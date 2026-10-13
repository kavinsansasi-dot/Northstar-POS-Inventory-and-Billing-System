require('dotenv').config();

const cors = require('cors');
const express = require('express');
const helmet = require('helmet');
const connectDatabase = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const customerRoutes = require('./routes/customerRoutes');
const productRoutes = require('./routes/productRoutes');
const reportRoutes = require('./routes/reportRoutes');
const saleRoutes = require('./routes/saleRoutes');

const app = express();
const configuredOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean)
  : '*';

app.use(helmet());
app.use(cors({ origin: configuredOrigins }));
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (_req, res) => {
  res.status(200).json({ success: true, message: 'POS API is healthy.' });
});
app.use('/api/auth', authRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/products', productRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/reports', reportRoutes);

app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found.' });
});

app.use((error, _req, res, _next) => {
  if (error.code === 11000) {
    return res.status(409).json({
      success: false,
      message: 'A record with that email, phone, SKU, or barcode already exists.'
    });
  }

  if (error.name === 'ValidationError' || error.name === 'CastError'
    || error.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      message: error.message || 'The request contains invalid data.'
    });
  }

  console.error(error);
  return res.status(500).json({
    success: false,
    message: 'An unexpected server error occurred.'
  });
});

async function startServer() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be configured with at least 32 characters.');
  }

  await connectDatabase();

  const port = Number(process.env.PORT) || 5000;
  app.listen(port, () => {
    console.log(`POS API listening on port ${port}.`);
  });
}

startServer().catch((error) => {
  console.error('Unable to start the POS API:', error.message);
  process.exit(1);
});
