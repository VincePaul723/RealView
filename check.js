require('dotenv').config();
// Quick check: which databases exist and how many rows realview has.
const mysql = require('mysql2/promise');

(async () => {
  const db = await mysql.createConnection({
    host: process.env.MYSQL_HOST || 'localhost',
    port: Number(process.env.MYSQL_PORT || 3306),
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
  });
  const [dbs] = await db.query('SHOW DATABASES');
  console.log('Databases:', dbs.map(r => r.Database).join(', '));

  const [tables] = await db.query(
    `SELECT table_name AS t, table_rows AS n FROM information_schema.tables
     WHERE table_schema = 'realview' ORDER BY 1`);
  if (tables.length === 0) {
    console.log('No "realview" database or no tables in it. schema.sql did not run.');
  } else {
    console.table(tables);
    const [u] = await db.query('SELECT user_id, username FROM realview.users');
    console.log('users:', u);
  }
  await db.end();
})().catch(e => { console.error(e.message); process.exit(1); });
