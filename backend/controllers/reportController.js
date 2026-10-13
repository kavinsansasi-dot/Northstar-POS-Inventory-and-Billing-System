const Product = require('../models/Product');
const Sale = require('../models/Sale');

function getUtcDayRange(dateValue) {
  let day;
  if (dateValue === undefined) {
    day = new Date();
  } else {
    if (typeof dateValue !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dateValue)) {
      return null;
    }

    day = new Date(`${dateValue}T00:00:00.000Z`);
    if (Number.isNaN(day.getTime()) || day.toISOString().slice(0, 10) !== dateValue) {
      return null;
    }
  }

  const start = new Date(Date.UTC(day.getUTCFullYear(), day.getUTCMonth(), day.getUTCDate()));
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);
  return { start, end };
}

async function getDailyReport(req, res, next) {
  try {
    const range = getUtcDayRange(req.query.date);
    if (!range) {
      return res.status(400).json({
        success: false,
        message: 'date must be a valid calendar date in YYYY-MM-DD format.'
      });
    }

    const [report] = await Sale.aggregate([
      {
        $match: {
          date: {
            $gte: range.start,
            $lt: range.end
          }
        }
      },
      {
        $facet: {
          totals: [
            {
              $group: {
                _id: null,
                totalSales: { $sum: '$total' },
                numberOfBills: { $sum: 1 }
              }
            }
          ],
          topProducts: [
            { $unwind: '$items' },
            {
              $group: {
                _id: '$items.product',
                name: { $first: '$items.name' },
                quantitySold: { $sum: '$items.qty' },
                salesAmount: {
                  $sum: { $multiply: ['$items.price', '$items.qty'] }
                }
              }
            },
            { $sort: { quantitySold: -1, salesAmount: -1, _id: 1 } },
            { $limit: 5 },
            {
              $project: {
                _id: 0,
                product: '$_id',
                name: 1,
                quantitySold: 1,
                salesAmount: 1
              }
            }
          ]
        }
      },
      {
        $project: {
          _id: 0,
          totalSales: {
            $ifNull: [{ $arrayElemAt: ['$totals.totalSales', 0] }, 0]
          },
          numberOfBills: {
            $ifNull: [{ $arrayElemAt: ['$totals.numberOfBills', 0] }, 0]
          },
          topProducts: 1
        }
      }
    ]);

    return res.status(200).json({
      success: true,
      message: 'Daily report retrieved.',
      data: {
        date: range.start.toISOString().slice(0, 10),
        totalSales: report?.totalSales || 0,
        numberOfBills: report?.numberOfBills || 0,
        topProducts: report?.topProducts || []
      }
    });
  } catch (error) {
    return next(error);
  }
}

async function getLowStockReport(_req, res, next) {
  try {
    const products = await Product.aggregate([
      {
        $match: {
          $expr: { $lte: ['$stock', '$minStock'] }
        }
      },
      { $sort: { stock: 1, name: 1, _id: 1 } },
      {
        $project: {
          _id: 1,
          name: 1,
          sku: 1,
          category: 1,
          stock: 1,
          minStock: 1
        }
      }
    ]);

    return res.status(200).json({
      success: true,
      message: 'Low-stock report retrieved.',
      data: products
    });
  } catch (error) {
    return next(error);
  }
}

async function getWeeklyReport(_req, res, next) {
  try {
    const today = new Date();
    const end = new Date(Date.UTC(
      today.getUTCFullYear(),
      today.getUTCMonth(),
      today.getUTCDate() + 1
    ));
    const start = new Date(end);
    start.setUTCDate(start.getUTCDate() - 7);

    const dailyTotals = await Sale.aggregate([
      {
        $match: {
          date: { $gte: start, $lt: end }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$date', timezone: 'UTC' }
          },
          totalSales: { $sum: '$total' },
          numberOfBills: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } },
      {
        $project: {
          _id: 0,
          date: '$_id',
          totalSales: 1,
          numberOfBills: 1
        }
      }
    ]);

    const totalsByDate = new Map(dailyTotals.map((day) => [day.date, day]));
    const days = [];
    for (let offset = 0; offset < 7; offset += 1) {
      const day = new Date(start);
      day.setUTCDate(start.getUTCDate() + offset);
      const date = day.toISOString().slice(0, 10);
      days.push(totalsByDate.get(date) || {
        date,
        totalSales: 0,
        numberOfBills: 0
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Weekly report retrieved.',
      data: days
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { getDailyReport, getLowStockReport, getWeeklyReport };
