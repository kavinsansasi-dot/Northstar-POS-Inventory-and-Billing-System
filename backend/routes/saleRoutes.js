const express = require('express');
const { createSale, getSales } = require('../controllers/saleController');
const requireAuth = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);
router.post('/', createSale);
router.get('/', getSales);

module.exports = router;
