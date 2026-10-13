const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Customer name is required.'],
      trim: true,
      maxlength: [120, 'Customer name cannot exceed 120 characters.']
    },
    phone: {
      type: String,
      required: [true, 'Customer phone is required.'],
      unique: true,
      trim: true,
      maxlength: [32, 'Customer phone cannot exceed 32 characters.']
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      maxlength: [254, 'Customer email cannot exceed 254 characters.']
    },
    address: {
      type: String,
      trim: true,
      maxlength: [500, 'Customer address cannot exceed 500 characters.']
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [2000, 'Customer notes cannot exceed 2000 characters.']
    },
    totalPurchases: {
      type: Number,
      min: [0, 'Total purchases cannot be negative.'],
      default: 0
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Customer', customerSchema);
