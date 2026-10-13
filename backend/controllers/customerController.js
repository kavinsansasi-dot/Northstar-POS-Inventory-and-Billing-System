const mongoose = require('mongoose');
const Customer = require('../models/Customer');
const Sale = require('../models/Sale');

const writableFields = new Set(['name', 'phone', 'email', 'address', 'notes']);
const stringFields = new Set(['name', 'phone', 'email', 'address', 'notes']);

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function parseCustomerInput(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'Request body must be a JSON object.' };
  }

  const unknownFields = Object.keys(body).filter((field) => !writableFields.has(field));
  if (unknownFields.length > 0) {
    return { error: `Unsupported customer field(s): ${unknownFields.join(', ')}.` };
  }

  const values = {};
  for (const [field, value] of Object.entries(body)) {
    if (!stringFields.has(field)) continue;
    if (typeof value !== 'string') {
      return { error: `${field} must be a string.` };
    }

    values[field] = value.trim();
  }

  if (values.email === '') {
    values.email = undefined;
  } else if (values.email !== undefined
    && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email)) {
    return { error: 'email must be a valid email address.' };
  }

  return { values };
}

function isValidId(id) {
  return mongoose.isValidObjectId(id);
}

async function createCustomer(req, res, next) {
  try {
    const parsed = parseCustomerInput(req.body);
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }

    const customer = await Customer.create(parsed.values);
    return res.status(201).json({
      success: true,
      message: 'Customer created.',
      data: customer
    });
  } catch (error) {
    return next(error);
  }
}

async function getAllCustomers(req, res, next) {
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
    const searchTerm = typeof req.query.search === 'string'
      ? req.query.search
      : req.query.q;
    if (typeof searchTerm === 'string' && searchTerm.trim()) {
      const search = new RegExp(escapeRegex(searchTerm.trim()), 'i');
      filter.$or = [{ name: search }, { phone: search }];
    }

    const [customers, total] = await Promise.all([
      Customer.find(filter)
        .sort({ name: 1, _id: 1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Customer.countDocuments(filter)
    ]);

    return res.status(200).json({
      success: true,
      message: 'Customers retrieved.',
      data: customers,
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

async function getCustomerById(req, res, next) {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid customer ID.' });
    }

    const customer = await Customer.findById(req.params.id).lean();
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found.' });
    }

    const recentSales = await Sale.find({ customer: customer._id })
      .select('invoiceNo items subtotal discount tax total paymentType date')
      .sort({ date: -1, _id: -1 })
      .limit(10)
      .lean();

    return res.status(200).json({
      success: true,
      message: 'Customer retrieved.',
      data: { customer, recentSales }
    });
  } catch (error) {
    return next(error);
  }
}

async function updateCustomer(req, res, next) {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid customer ID.' });
    }

    const parsed = parseCustomerInput(req.body);
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }
    if (Object.keys(parsed.values).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Provide at least one customer field to update.'
      });
    }

    const update = { $set: parsed.values };
    if (parsed.values.email === undefined
      && Object.prototype.hasOwnProperty.call(req.body, 'email')) {
      delete update.$set.email;
      update.$unset = { email: 1 };
    }

    const customer = await Customer.findByIdAndUpdate(
      req.params.id,
      update,
      { new: true, runValidators: true }
    );
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Customer updated.',
      data: customer
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteCustomer(req, res, next) {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid customer ID.' });
    }

    const customer = await Customer.findByIdAndDelete(req.params.id);
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Customer deleted.',
      data: { id: customer.id }
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createCustomer,
  deleteCustomer,
  getAllCustomers,
  getCustomerById,
  updateCustomer
};
