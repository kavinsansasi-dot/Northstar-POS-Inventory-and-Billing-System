const mongoose = require('mongoose');
const Product = require('../models/Product');

const writableFields = new Set([
  'name',
  'sku',
  'category',
  'price',
  'cost',
  'stock',
  'minStock',
  'barcode'
]);
const stringFields = new Set(['name', 'sku', 'category', 'barcode']);
const numberFields = new Set(['price', 'cost', 'stock', 'minStock']);

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function parseProductInput(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'Request body must be a JSON object.' };
  }

  const unknownFields = Object.keys(body).filter((field) => !writableFields.has(field));
  if (unknownFields.length > 0) {
    return { error: `Unsupported product field(s): ${unknownFields.join(', ')}.` };
  }

  const values = {};
  for (const [field, value] of Object.entries(body)) {
    if (stringFields.has(field)) {
      if (typeof value !== 'string') {
        return { error: `${field} must be a string.` };
      }
      values[field] = value.trim();
      continue;
    }

    if (numberFields.has(field)) {
      if ((typeof value !== 'number' && typeof value !== 'string')
        || (typeof value === 'string' && value.trim() === '')) {
        return { error: `${field} must be a valid number.` };
      }

      const number = typeof value === 'number' ? value : Number(value);
      if (!Number.isFinite(number) || number < 0) {
        return { error: `${field} must be a non-negative number.` };
      }
      values[field] = number;
    }
  }

  if (values.barcode === '') {
    values.barcode = undefined;
  }

  return { values };
}

function isValidId(id) {
  return mongoose.isValidObjectId(id);
}

async function createProduct(req, res, next) {
  try {
    const parsed = parseProductInput(req.body);
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }

    const product = await Product.create(parsed.values);
    return res.status(201).json({
      success: true,
      message: 'Product created.',
      data: product
    });
  } catch (error) {
    return next(error);
  }
}

async function getAllProducts(req, res, next) {
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
    if (typeof req.query.category === 'string' && req.query.category.trim()) {
      filter.category = new RegExp(`^${escapeRegex(req.query.category.trim())}$`, 'i');
    }
    const searchTerm = typeof req.query.search === 'string'
      ? req.query.search
      : req.query.q;
    if (typeof searchTerm === 'string' && searchTerm.trim()) {
      const search = new RegExp(escapeRegex(searchTerm.trim()), 'i');
      filter.$or = [{ name: search }, { sku: search }, { category: search }, { barcode: search }];
    }

    const [products, total] = await Promise.all([
      Product.find(filter)
        .sort({ name: 1, _id: 1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Product.countDocuments(filter)
    ]);

    return res.status(200).json({
      success: true,
      message: 'Products retrieved.',
      data: products,
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

async function getProductById(req, res, next) {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid product ID.' });
    }

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Product retrieved.',
      data: product
    });
  } catch (error) {
    return next(error);
  }
}

async function updateProduct(req, res, next) {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid product ID.' });
    }

    const parsed = parseProductInput(req.body);
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }
    if (Object.keys(parsed.values).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Provide at least one product field to update.'
      });
    }

    const update = { $set: parsed.values };
    if (parsed.values.barcode === undefined
      && Object.prototype.hasOwnProperty.call(req.body, 'barcode')) {
      delete update.$set.barcode;
      update.$unset = { barcode: 1 };
    }

    const product = await Product.findByIdAndUpdate(
      req.params.id,
      update,
      { new: true, runValidators: true }
    );
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Product updated.',
      data: product
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteProduct(req, res, next) {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid product ID.' });
    }

    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Product deleted.',
      data: { id: product.id }
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createProduct,
  deleteProduct,
  getAllProducts,
  getProductById,
  updateProduct
};
