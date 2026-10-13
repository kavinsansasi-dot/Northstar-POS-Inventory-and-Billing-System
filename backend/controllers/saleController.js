const mongoose = require('mongoose');
const Customer = require('../models/Customer');
const Product = require('../models/Product');
const Sale = require('../models/Sale');

class SaleRequestError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function parseNonNegativeAmount(value, fieldName) {
  if (value === undefined) {
    return 0;
  }
  if ((typeof value !== 'number' && typeof value !== 'string')
    || (typeof value === 'string' && value.trim() === '')) {
    throw new SaleRequestError(400, `${fieldName} must be a non-negative number.`);
  }

  const amount = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(amount) || amount < 0) {
    throw new SaleRequestError(400, `${fieldName} must be a non-negative number.`);
  }
  return amount;
}

function roundCurrency(amount) {
  return Math.round((amount + Number.EPSILON) * 100) / 100;
}

async function fetchSaleProducts(quantities, session) {
  let query = Product.find({ _id: { $in: [...quantities.keys()] } }).select('name');
  if (session) {
    query = query.session(session);
  }

  const products = await query;
  const productsById = new Map(products.map((product) => [String(product._id), product]));

  for (const productId of quantities.keys()) {
    if (!productsById.has(productId)) {
      throw new SaleRequestError(404, `Product ${productId} was not found.`);
    }
  }

  return productsById;
}

async function executeSale({
  body,
  quantities,
  discount,
  tax,
  cashier,
  session,
  onStockReduced,
  onSaleCreated
}) {
  const productsById = await fetchSaleProducts(quantities, session);
  const saleItems = [];

  for (const [productId, qty] of quantities) {
    const updatedProduct = await Product.findOneAndUpdate(
      { _id: productId, stock: { $gte: qty } },
      { $inc: { stock: -qty } },
      {
        new: true,
        runValidators: true,
        ...(session ? { session } : {})
      }
    );

    if (!updatedProduct) {
      throw new SaleRequestError(
        400,
        `Insufficient stock for ${productsById.get(productId).name}`
      );
    }

    if (onStockReduced) {
      onStockReduced(productId, qty);
    }
    saleItems.push({
      product: updatedProduct._id,
      name: updatedProduct.name,
      price: updatedProduct.price,
      qty
    });
  }

  const subtotal = roundCurrency(
    saleItems.reduce((sum, item) => sum + item.price * item.qty, 0)
  );
  if (discount > subtotal) {
    throw new SaleRequestError(400, 'Discount cannot exceed the sale subtotal.');
  }

  const total = roundCurrency(subtotal - discount + tax);
  const saleData = {
    items: saleItems,
    subtotal,
    discount: roundCurrency(discount),
    tax: roundCurrency(tax),
    total,
    paymentType: body.paymentType,
    cashier
  };

  if (body.customer !== undefined && body.customer !== null) {
    saleData.customer = body.customer;
  }

  const sale = new Sale(saleData);
  try {
    await sale.save(session ? { session } : undefined);
  } catch (error) {
    const saveError = new SaleRequestError(500, 'Failed to save sale.');
    saveError.cause = error;
    throw saveError;
  }
  if (onSaleCreated) {
    onSaleCreated(sale._id);
  }

  if (body.customer !== undefined && body.customer !== null) {
    const customer = await Customer.findByIdAndUpdate(
      body.customer,
      { $inc: { totalPurchases: total } },
      {
        new: true,
        runValidators: true,
        ...(session ? { session } : {})
      }
    );
    if (!customer) {
      throw new SaleRequestError(404, 'Customer not found.');
    }
    sale.customer = customer._id;
  }
  return sale;
}

async function rollbackStandaloneSale(reducedProducts, saleId) {
  const rollbackErrors = [];

  if (saleId) {
    try {
      const result = await Sale.deleteOne({ _id: saleId });
      if (result.deletedCount !== 1) {
        throw new Error('Sale was not found while rolling back the sale.');
      }
    } catch (error) {
      rollbackErrors.push(error);
    }
  }

  for (const { productId, qty } of reducedProducts.reverse()) {
    try {
      const product = await Product.findOneAndUpdate(
        { _id: productId },
        { $inc: { stock: qty } },
        { runValidators: true }
      );
      if (!product) {
        throw new Error(`Product ${productId} was not found while restoring stock.`);
      }
    } catch (error) {
      rollbackErrors.push(error);
    }
  }

  if (rollbackErrors.length > 0) {
    throw new AggregateError(
      rollbackErrors,
      'Failed to fully roll back a standalone sale.'
    );
  }
}

async function createSale(req, res, next) {
  let session;
  try {
    const body = req.body || {};
    if (!Array.isArray(body.items) || body.items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one sale item is required.'
      });
    }
    if (!['cash', 'card', 'upi'].includes(body.paymentType)) {
      return res.status(400).json({
        success: false,
        message: 'paymentType must be cash, card, or upi.'
      });
    }
    if (body.customer !== undefined && body.customer !== null
      && !mongoose.isValidObjectId(body.customer)) {
      return res.status(400).json({
        success: false,
        message: 'customer must be a valid customer ID.'
      });
    }

    const discount = parseNonNegativeAmount(body.discount, 'discount');
    const tax = parseNonNegativeAmount(body.tax, 'tax');
    const quantities = new Map();

    for (const item of body.items) {
      if (!item || typeof item !== 'object' || Array.isArray(item)
        || !mongoose.isValidObjectId(item.product)) {
        return res.status(400).json({
          success: false,
          message: 'Each item must include a valid product ID and quantity.'
        });
      }
      if (typeof item.qty !== 'number' || !Number.isFinite(item.qty) || item.qty <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Each item quantity must be a positive number.'
        });
      }

      const productId = item.product.toString().toLowerCase();
      const combinedQty = (quantities.get(productId) || 0) + item.qty;
      if (!Number.isFinite(combinedQty)) {
        return res.status(400).json({
          success: false,
          message: 'Combined quantity for a product must be a finite number.'
        });
      }
      quantities.set(productId, combinedQty);
    }

    const hello = await mongoose.connection.db.admin().command({ hello: 1 });
    const replicaSetDetected = typeof hello.setName === 'string' && hello.setName.length > 0;
    let savedSale;

    if (replicaSetDetected) {
      session = await mongoose.startSession();
      await session.withTransaction(async () => {
        savedSale = await executeSale({
          body,
          quantities,
          discount,
          tax,
          cashier: req.user._id,
          session
        });
      }, {
        readConcern: { level: 'snapshot' },
        writeConcern: { w: 'majority' },
        readPreference: 'primary'
      });
    } else {
      const reducedProducts = [];
      let saleId;
      try {
        savedSale = await executeSale({
          body,
          quantities,
          discount,
          tax,
          cashier: req.user._id,
          onStockReduced: (productId, qty) => reducedProducts.push({ productId, qty }),
          onSaleCreated: (id) => { saleId = id; }
        });
      } catch (saleError) {
        await rollbackStandaloneSale(reducedProducts, saleId);
        throw saleError;
      }
    }

    return res.status(201).json({
      success: true,
      message: 'Sale created.',
      data: savedSale
    });
  } catch (error) {
    if (error instanceof SaleRequestError) {
      return res.status(error.status).json({ success: false, message: error.message });
    }
    return next(error);
  } finally {
    if (session) {
      await session.endSession();
    }
  }
}

async function getSales(req, res, next) {
  try {
    const page = req.query.page === undefined ? 1 : Number(req.query.page);
    const limit = req.query.limit === undefined ? 20 : Number(req.query.limit);
    if (!Number.isInteger(page) || page < 1
      || !Number.isInteger(limit) || limit < 1 || limit > 100) {
      return res.status(400).json({
        success: false,
        message: 'Page must be a positive integer and limit must be between 1 and 100.'
      });
    }

    const filter = {};
    const dateFilter = {};
    for (const [queryName, operator] of [['startDate', '$gte'], ['endDate', '$lte']]) {
      const value = req.query[queryName];
      if (value === undefined) {
        continue;
      }
      if (typeof value !== 'string' || Number.isNaN(Date.parse(value))) {
        return res.status(400).json({
          success: false,
          message: `${queryName} must be a valid date.`
        });
      }

      const parsedDate = new Date(value);
      if (queryName === 'endDate' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
        parsedDate.setUTCHours(23, 59, 59, 999);
      }
      dateFilter[operator] = parsedDate;
    }

    if (dateFilter.$gte && dateFilter.$lte && dateFilter.$gte > dateFilter.$lte) {
      return res.status(400).json({
        success: false,
        message: 'startDate must be earlier than or equal to endDate.'
      });
    }
    if (Object.keys(dateFilter).length > 0) {
      filter.date = dateFilter;
    }

    const [sales, total] = await Promise.all([
      Sale.find(filter)
        .populate('cashier', 'name email')
        .sort({ date: -1, _id: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Sale.countDocuments(filter)
    ]);

    return res.status(200).json({
      success: true,
      message: 'Sales retrieved.',
      data: sales,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { createSale, getSales };
