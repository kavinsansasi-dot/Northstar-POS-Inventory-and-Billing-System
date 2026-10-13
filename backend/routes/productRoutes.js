const express = require('express');
const {
  createProduct,
  deleteProduct,
  getAllProducts,
  getProductById,
  updateProduct
} = require('../controllers/productController');
const requireAuth = require('../middleware/auth');
const allowRoles = require('../middleware/role');

const router = express.Router();

router.use(requireAuth);
router.get('/', getAllProducts);
router.get('/:id', getProductById);
router.post('/', allowRoles('admin'), createProduct);
router.put('/:id', allowRoles('admin'), updateProduct);
router.delete('/:id', allowRoles('admin'), deleteProduct);

module.exports = router;
