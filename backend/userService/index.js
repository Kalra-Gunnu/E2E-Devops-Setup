require('dotenv').config();
const express = require('express');
const cors = require('cors');
const userLeadRoutes = require('./routes/userLead.route');

const app = express();

app.use(express.json());

app.use(cors());

const healthRoutes = require('./routes/health.route')

app.use('/api/userleads', userLeadRoutes);
app.use('/api/user', healthRoutes)

const PORT = process.env.PORT;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
