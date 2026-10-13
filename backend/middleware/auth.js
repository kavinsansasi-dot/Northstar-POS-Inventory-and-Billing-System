const jwt = require('jsonwebtoken');
const User = require('../models/User');

async function requireAuth(req, res, next) {
  try {
    const authorization = req.get('authorization') || '';
    const [scheme, token, ...extraParts] = authorization.trim().split(/\s+/);

    if (scheme?.toLowerCase() !== 'bearer' || !token || extraParts.length > 0) {
      return res.status(401).json({
        success: false,
        message: 'A valid Bearer token is required.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ['HS256']
    });
    if (typeof decoded !== 'object' || !decoded.sub) {
      return res.status(401).json({
        success: false,
        message: 'The token is invalid or has expired.'
      });
    }

    const user = await User.findById(decoded.sub);
    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Your account is unavailable. Please sign in again.'
      });
    }

    req.user = user;
    return next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(401).json({
        success: false,
        message: 'The token is invalid or has expired.'
      });
    }

    return next(error);
  }
}

module.exports = requireAuth;
