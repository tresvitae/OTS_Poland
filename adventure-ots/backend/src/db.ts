// ============================================================
// Backend API — Database Connection Pool
// Uses mysql2/promise for async queries against TFS MariaDB
// ============================================================

import mysql from 'mysql2/promise';

const pool = mysql.createPool({
    host: process.env.DB_HOST || 'db',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'ots_baza',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
});

export default pool;
