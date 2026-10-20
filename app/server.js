const express = require('express');
const mysql = require('mysql2/promise');
const path = require('path');

const app = express();
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(express.urlencoded({ extended: true }));

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  charset: 'utf8mb4'
});

app.get('/health', async (req, res) => {
  try { await pool.query('SELECT 1'); res.send('OK'); }
  catch (e) { res.status(500).send('DB error'); }
});

app.get('/', async (req, res) => {
  const { q = '', city = '', type = '', min = '', max = '' } = req.query;
  let sql = 'SELECT * FROM listings WHERE 1=1';
  const params = [];
  if (q)    { sql += ' AND (title LIKE ? OR address LIKE ?)'; params.push(`%${q}%`, `%${q}%`); }
  if (city) { sql += ' AND city LIKE ?'; params.push(`%${city}%`); }
  if (type) { sql += ' AND type = ?'; params.push(type); }
  if (min)  { sql += ' AND price >= ?'; params.push(min); }
  if (max)  { sql += ' AND price <= ?'; params.push(max); }
  sql += ' ORDER BY created_at DESC LIMIT 50';
  const [rows] = await pool.query(sql, params);
  res.render('index', { listings: rows, query: req.query });
});

app.get('/listings/:id', async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM listings WHERE id = ?', [req.params.id]);
  if (!rows.length) return res.status(404).send('Không tìm thấy tin');
  res.render('detail', { l: rows[0], sent: req.query.sent });
});

app.post('/listings/:id/contact', async (req, res) => {
  const { name, phone, message } = req.body;
  if (!name || !phone) return res.status(400).send('Thiếu họ tên hoặc số điện thoại');
  await pool.query(
    'INSERT INTO contacts (listing_id, name, phone, message) VALUES (?,?,?,?)',
    [req.params.id, name, phone, message || '']
  );
  res.redirect(`/listings/${req.params.id}?sent=1`);
});

app.get('/post', (req, res) => res.render('post'));
app.post('/post', async (req, res) => {
  const b = req.body;
  const [r] = await pool.query(
    `INSERT INTO listings (title,type,city,address,price,area,description,owner_name,owner_phone)
     VALUES (?,?,?,?,?,?,?,?,?)`,
    [b.title, b.type, b.city, b.address, b.price, b.area, b.description, b.owner_name, b.owner_phone]
  );
  res.redirect(`/listings/${r.insertId}`);
});

app.listen(3000, '0.0.0.0', () => console.log('App listening on 3000'));
