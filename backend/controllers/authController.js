const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

function createToken(user) {
  return jwt.sign(
    { role: user.role },
    process.env.JWT_SECRET,
    {
      subject: user.id,
      expiresIn: process.env.JWT_EXPIRES_IN || '1d'
    }
  );
}

function isValidPassword(password) {
  return typeof password === 'string'
    && password.length >= 8
    && Buffer.byteLength(password, 'utf8') <= 72;
}

async function createUser(req, res, next, role, isBootstrapAdmin = false) {
  try {
    const { name, email, password } = req.body || {};
    if (Object.prototype.hasOwnProperty.call(req.body || {}, 'role')) {
      return res.status(400).json({
        success: false,
        message: 'Role is assigned by an administrator.'
      });
    }

    const normalizedName = typeof name === 'string' ? name.trim() : '';
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (normalizedName.length < 2 || normalizedName.length > 100) {
      return res.status(400).json({
        success: false,
        message: 'Name must contain between 2 and 100 characters.'
      });
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message: 'Enter a valid email address.'
      });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters and no more than 72 UTF-8 bytes.'
      });
    }

    const user = new User({
      name: normalizedName,
      email: normalizedEmail,
      role,
      isBootstrapAdmin
    });
    await user.setPassword(password);
    await user.save();

    return res.status(201).json({
      success: true,
      message: 'Account created.',
      data: {
        user,
        token: createToken(user)
      }
    });
  } catch (error) {
    if (isBootstrapAdmin && error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Admin bootstrap was already used or the account conflicts with an existing record.'
      });
    }

    return next(error);
  }
}

function register(req, res, next) {
  return createUser(req, res, next, 'cashier');
}

async function bootstrapAdmin(req, res, next) {
  try {
    const configuredToken = process.env.DEV_ADMIN_BOOTSTRAP_TOKEN;
    const suppliedToken = req.get('x-admin-bootstrap-token') || '';

    if (process.env.NODE_ENV !== 'development' || !configuredToken) {
      return res.status(404).json({
        success: false,
        message: 'Development admin bootstrap is disabled.'
      });
    }

    const expectedBuffer = Buffer.from(configuredToken);
    const suppliedBuffer = Buffer.from(suppliedToken);
    if (expectedBuffer.length !== suppliedBuffer.length
      || !crypto.timingSafeEqual(expectedBuffer, suppliedBuffer)) {
      return res.status(401).json({
        success: false,
        message: 'A valid admin bootstrap token is required.'
      });
    }

    await User.init();
    if (await User.exists({})) {
      return res.status(409).json({
        success: false,
        message: 'An account already exists; bootstrap can only create the first admin.'
      });
    }

    return await createUser(req, res, next, 'admin', true);
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body || {};
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (!normalizedEmail || typeof password !== 'string' || password.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.'
      });
    }

    const user = await User.findOne({ email: normalizedEmail }).select('+passwordHash');
    if (!user || !user.isActive || !(await user.comparePassword(password))) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Login successful.',
      data: {
        user,
        token: createToken(user)
      }
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { bootstrapAdmin, register, login };
