const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required.'],
      trim: true,
      minlength: [2, 'Name must contain at least 2 characters.'],
      maxlength: [100, 'Name cannot exceed 100 characters.']
    },
    email: {
      type: String,
      required: [true, 'Email is required.'],
      unique: true,
      lowercase: true,
      trim: true,
      maxlength: 254,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Enter a valid email address.']
    },
    passwordHash: {
      type: String,
      required: true,
      select: false
    },
    role: {
      type: String,
      enum: ['admin', 'cashier'],
      default: 'cashier',
      required: true
    },
    isActive: {
      type: Boolean,
      default: true
    },
    isBootstrapAdmin: {
      type: Boolean,
      default: false,
      select: false
    }
  },
  {
    timestamps: true,
    toJSON: {
      transform(_document, returnedObject) {
        delete returnedObject.passwordHash;
        delete returnedObject.isBootstrapAdmin;
        delete returnedObject.__v;
        return returnedObject;
      }
    }
  }
);

userSchema.index(
  { isBootstrapAdmin: 1 },
  {
    unique: true,
    partialFilterExpression: { isBootstrapAdmin: true }
  }
);

userSchema.methods.setPassword = async function setPassword(password) {
  this.passwordHash = await bcrypt.hash(password, 12);
};

userSchema.methods.comparePassword = function comparePassword(password) {
  return bcrypt.compare(password, this.passwordHash);
};

module.exports = mongoose.model('User', userSchema);
