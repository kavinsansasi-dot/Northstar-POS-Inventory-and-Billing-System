const express = require('express');
const { bootstrapAdmin, login, register } = require('../controllers/authController');
const requireAuth = require('../middleware/auth');
const allowRoles = require('../middleware/role');

const router = express.Router();

router.post('/bootstrap-admin', bootstrapAdmin);
router.post('/register', requireAuth, allowRoles('admin'), register);
router.post('/login', login);

module.exports = router;
