const crypto = require('crypto');
const mongoose = require('mongoose');

const saleItemSchema = new mongoose.Schema(
  {
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true
    },
    name: {
      type: String,
      required: true,
      trim: true
    },
    price: {
      type: Number,
      required: true,
      min: 0
    },
    qty: {
      type: Number,
      required: true,
      min: Number.EPSILON
    }
  },
  { _id: false }
);

const saleSchema = new mongoose.Schema(
  {
    invoiceNo: {
      type: String,
      required: true,
      unique: true,
      immutable: true,
      default: () => `INV-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`
    },
    items: {
      type: [saleItemSchema],
      required: true,
      validate: {
        validator: (items) => Array.isArray(items) && items.length > 0,
        message: 'A sale must contain at least one item.'
      }
    },
    subtotal: {
      type: Number,
      required: true,
      min: 0
    },
    discount: {
      type: Number,
      min: 0,
      default: 0
    },
    tax: {
      type: Number,
      min: 0,
      default: 0
    },
    total: {
      type: Number,
      required: true,
      min: 0
    },
    paymentType: {
      type: String,
      enum: ['cash', 'card', 'upi'],
      required: true
    },
    cashier: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    customer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer'
    },
    date: {
      type: Date,
      default: Date.now,
      required: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Sale', saleSchema);
