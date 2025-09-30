
/**
 * Static server for Klonglens2
 */
const express = require('express');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Serve static files from public/
app.use(express.static(path.join(__dirname, 'public')));

// Example route (extendable)
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from Klonglens2 API!' });
});

app.listen(PORT, () => {
  console.log(`Klonglens2 server running at http://localhost:${PORT}`);
});
