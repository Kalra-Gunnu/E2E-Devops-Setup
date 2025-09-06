require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();

app.use(express.json());

app.use(cors());
const paymentRoutes = require('./routes/payment.route')
const healthRoutes = require('./routes/health.route')

app.use('/api/payment', paymentRoutes);
app.use('/api/payment', healthRoutes);


const PORT = process.env.PORT;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
