// Path: gachamerch-backend/server.js
const express = require('express');
const mysql = require('mysql2/promise'); // Menggunakan versi promise untuk async/await
const cors = require('cors');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// 1. Konfigurasi CORS Utama (Menambahkan OPTIONS ke dalam metode yang diizinkan)
app.use(cors({ 
    origin: '*', 
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'], 
    allowedHeaders: ['Content-Type', 'Authorization'] 
}));

// 2. KHUSUS VERCEL: Interceptor Preflight OPTIONS agar tidak memicu 'Redirect not allowed'
app.options('*', (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.sendStatus(200);
});

// Konfigurasi Connection Pool ke TiDB Cloud
const db = mysql.createPool({
    host: 'gateway01.ap-southeast-1.prod.aws.tidbcloud.com',
    user: '4TX4DANzYZuX3cG.root',
    password: 'cFQ0oqb59EVEYdrn',
    database: 'test',
    port: 4000,
    ssl: {
        rejectUnauthorized: true
    },
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Cek koneksi TiDB Cloud menggunakan metode asinkron (Promise) yang benar
(async () => {
    try {
        const connection = await db.getConnection();
        console.log('⚡ Sukses! Backend terhubung ke TiDB Cloud Serverless.');
        connection.release();
    } catch (err) {
        console.error('❌ Gagal tersambung ke TiDB Cloud:', err.message);
    }
})();

// Cache map to bind dynamic runtime tokens back to usernames
const tokenStorage = {}; 

// Middleware helper to validate Bearer token headers and extract the username
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    if (!authHeader) return res.status(401).json({ message: "Access Denied: Missing Token" });
    
    const token = authHeader.split(' ')[1];
    if (!token || !tokenStorage[token]) return res.status(401).json({ message: "Invalid or expired token sessions" });
    
    req.username = tokenStorage[token]; // Attach token-decoded identity to request pipeline
    next(); 
}

// LOGIN
app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const [rows] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
        if (rows.length === 0) return res.status(400).json({ message: "User not found" });
        
        const user = rows[0];
        if (password !== user.password) return res.status(400).json({ message: "Invalid password" });

        const token = crypto.randomBytes(10).toString('hex'); 
        tokenStorage[token] = user.username; // Bind token back to username profile context

        res.json({ token, username: user.username, role: user.role });
    } catch (err) {
        res.status(500).json({ message: "Database failure: " + err.message });
    }
});

// OAuth Bypass
app.post('/api/oauth-login', async (req, res) => {
    const { username } = req.body;
    const token = crypto.randomBytes(10).toString('hex');
    tokenStorage[token] = username;
    res.json({ token, username, role: 'user' });
});

// ==========================================
// NEW DATABASE CART SYSTEM ENDPOINTS
// ==========================================

// GET CART FOR ACTIVE USER
app.get('/api/cart', authenticateToken, async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT cart.id as cart_entry_id, cart.quantity, resources.* FROM cart 
             JOIN resources ON cart.resource_id = resources.id 
             WHERE cart.username = ?`, 
            [req.username]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// ADD ITEM TO CART (Or increment quantity if it exists)
app.post('/api/cart', authenticateToken, async (req, res) => {
    const { resource_id, quantity } = req.body;
    try {
        const [existing] = await db.query('SELECT * FROM cart WHERE username = ? AND resource_id = ?', [req.username, resource_id]);
        
        if (existing.length > 0) {
            await db.query('UPDATE cart SET quantity = quantity + ? WHERE id = ?', [quantity, existing[0].id]);
        } else {
            await db.query('INSERT INTO cart (username, resource_id, quantity) VALUES (?, ?, ?)', [req.username, resource_id, quantity]);
        }
        res.json({ message: "Staged to database cart successfully!" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// REMOVE ENTRY FROM CART (FIXED Parameter validation for serverless)
app.delete('/api/cart/:id', authenticateToken, async (req, res) => {
    const cartId = req.params.id || req.query.id;
    const username = req.username;

    if (!cartId) return res.status(400).json({ message: "Missing item ID" });

    try {
        await db.query('DELETE FROM cart WHERE id = ? AND username = ?', [cartId, username]);
        res.json({ message: "Dropped item from database cart entry." });
    } catch (err) {
        res.status(500).json({ message: "Database failure: " + err.message });
    }
});

// CART CHECKOUT CLEAR ROUTE
app.post('/api/cart/checkout', authenticateToken, async (req, res) => {
    try {
        const [cartItems] = await db.query(
            `SELECT cart.quantity, resources.* FROM cart 
             JOIN resources ON cart.resource_id = resources.id 
             WHERE cart.username = ?`, [req.username]
        );

        for (let item of cartItems) {
            await db.query('UPDATE resources SET stock = stock - ? WHERE id = ?', [item.quantity, item.id]);
        }

        await db.query('DELETE FROM cart WHERE username = ?', [req.username]);
        res.json({ message: "Checkout processed and items cleared from database!" });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// ==========================================
// STANDARD CATALOG CRUDS
// ==========================================
app.get('/api/resources', async (req, res) => {
    try { const [rows] = await db.query('SELECT * FROM resources'); res.json(rows); } catch (err) { res.status(500).json({ message: err.message }); }
});

// GET RESOURCE BY ID (FIXED Parameter validation for serverless)
app.get('/api/resources/:id', authenticateToken, async (req, res) => {
    const resourceId = req.params.id || req.query.id;

    if (!resourceId) return res.status(400).json({ message: "Missing resource ID" });

    try {
        const [rows] = await db.query('SELECT * FROM resources WHERE id = ?', [resourceId]);
        if (rows.length === 0) return res.status(404).json({ message: "Not found" });
        res.json(rows[0]);
    } catch (err) { 
        res.status(500).json({ message: "Database failure: " + err.message }); 
    }
});

app.post('/api/resources', authenticateToken, async (req, res) => {
    const { name, type, description, stock, image_url, price } = req.body;
    try { await db.query('INSERT INTO resources (name, type, description, stock, image_url, price) VALUES (?, ?, ?, ?, ?, ?)', [name, type, description, stock, image_url, price]); res.json({ message: "Success" }); } catch (err) { res.status(500).json({ message: err.message }); }
});

app.put('/api/resources/:id', authenticateToken, async (req, res) => {
    const resourceId = req.params.id || req.query.id;
    const { name, type, description, stock, image_url, price } = req.body;
    try { await db.query('UPDATE resources SET name=?, type=?, description=?, stock=?, image_url=?, price=? WHERE id=?', [name, type, description, stock, image_url, price, resourceId]); res.json({ message: "Success" }); } catch (err) { res.status(500).json({ message: err.message }); }
});

app.delete('/api/resources/:id', authenticateToken, async (req, res) => {
    const resourceId = req.params.id || req.query.id;
    try { await db.query('DELETE FROM resources WHERE id = ?', [resourceId]); res.json({ message: "Success" }); } catch (err) { res.status(500).json({ message: err.message }); }
});

// Penyesuaian port dinamis agar aman berjalan di lokal maupun serverless Vercel
if (process.env.NODE_ENV !== 'production') {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => console.log(`BACKEND SECURED ON PORT ${PORT}`));
}

// Export modul app untuk dibaca Vercel Engine
module.exports = app;