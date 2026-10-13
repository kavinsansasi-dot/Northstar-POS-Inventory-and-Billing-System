const express = require('express');
const {
  getDailyReport,
  getLowStockReport,
  getWeeklyReport
} = require('../controllers/reportController');
const requireAuth = require('../middleware/auth');
const allowRoles = require('../middleware/role');

const router = express.Router();

router.use(requireAuth, allowRoles('admin'));
router.get('/daily', getDailyReport);
router.get('/low-stock', getLowStockReport);
router.get('/weekly', getWeeklyReport);

module.exports = router;
