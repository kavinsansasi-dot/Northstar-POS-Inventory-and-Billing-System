const express = require('express');
const {
  createCustomer,
  deleteCustomer,
  getAllCustomers,
  getCustomerById,
  updateCustomer
} = require('../controllers/customerController');
const requireAuth = require('../middleware/auth');
const allowRoles = require('../middleware/role');

const router = express.Router();

router.use(requireAuth);
router.get('/', getAllCustomers);
router.get('/:id', getCustomerById);
router.post('/', createCustomer);
router.put('/:id', updateCustomer);
router.delete('/:id', allowRoles('admin'), deleteCustomer);

module.exports = router;
