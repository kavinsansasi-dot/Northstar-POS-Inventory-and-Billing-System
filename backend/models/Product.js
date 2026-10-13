const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Product name is required.'],
      trim: true,
      maxlength: [120, 'Product name cannot exceed 120 characters.']
    },
    sku: {
      type: String,
      required: [true, 'SKU is required.'],
      unique: true,
      uppercase: true,
      trim: true,
      maxlength: [64, 'SKU cannot exceed 64 characters.']
    },
    category: {
      type: String,
      required: [true, 'Category is required.'],
      trim: true,
      maxlength: [80, 'Category cannot exceed 80 characters.']
    },
    price: {
      type: Number,
      required: [true, 'Selling price is required.'],
      min: [0, 'Selling price cannot be negative.']
    },
    cost: {
      type: Number,
      min: [0, 'Cost cannot be negative.'],
      default: 0
    },
    stock: {
      type: Number,
      min: [0, 'Stock cannot be negative.'],
      default: 0
    },
    minStock: {
      type: Number,
      min: [0, 'Minimum stock cannot be negative.'],
      default: 0
    },
    barcode: {
      type: String,
      trim: true,
      maxlength: [64, 'Barcode cannot exceed 64 characters.']
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', productSchema);
