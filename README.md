# RealView

This project is an Express application backed by MySQL. The login and
registration routes require a running MySQL server and the `realview` schema.

## Setup

1. Install [Node.js](https://nodejs.org/) and make sure your MySQL server is running.
2. Install the project dependencies:

   ```sh
   npm install
   ```

3. Configure the database settings in `.env`:

   ```dotenv
   MYSQL_HOST=localhost
   MYSQL_PORT=3306
   MYSQL_USER=your_mysql_user
   MYSQL_PASSWORD=your_mysql_password
   MYSQL_DATABASE=realview
   ```

   Create the database and tables using `schema.sql` if they have not been
   created yet.

4. Start the application:

   ```sh
   npm start
   ```

   The app serves the pages in `public` at `http://localhost:3000`. Set `PORT`
   to use a different port.

To check the database connection and inspect the `realview` tables without
starting the web server, run:

```sh
npm run check:db
```
