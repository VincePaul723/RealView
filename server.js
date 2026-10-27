require("dotenv").config(); //loads the MySQL password from the .env file

const express = require("express"); //imports the express module
const crypt = require("crypto"); //used to hash passwords
const app = express(); //creates the express application object
app.use(express.urlencoded({ extended: true })); //lets us read form data from req.body
app.use(express.static("public")); //register public as the directory for static files

const mysql = require("mysql2"); //uses new mysql package
const requiredDatabaseSettings = ["MYSQL_USER", "MYSQL_PASSWORD", "MYSQL_DATABASE"];
const missingDatabaseSettings = requiredDatabaseSettings.filter(
	(setting) => !process.env[setting]
);

if (missingDatabaseSettings.length > 0) {
	console.error(`Missing required database settings: ${missingDatabaseSettings.join(", ")}`);
	process.exit(1);
}

const conn = mysql.createConnection({
	host: process.env.MYSQL_HOST || "localhost",
	user: process.env.MYSQL_USER,
	password: process.env.MYSQL_PASSWORD,
	database: process.env.MYSQL_DATABASE,
	port: Number(process.env.MYSQL_PORT || 3306)
});

//settings for the password hash
const hashRounds = 100;
const hashLength = 64;

conn.connect(function(err)
{
	if(err)
	{
		console.error("Could not connect to MySQL",err);
		process.exitCode = 1;
	}
	else
	{
		console.log("Database connection established");
		app.listen(process.env.PORT || 3000, function()
		{
			console.log(`Server listening on port ${process.env.PORT || 3000}`);
		});
	}
});

//hashes a password with the given salt
function hashPassword(plainPass, salt)
{
	return crypt.pbkdf2Sync(plainPass, salt, hashRounds, hashLength, 'sha512').toString('hex');
}

//register a new user
app.post("/register",function(req,res)
{
	let username = req.body.username;
	let email = req.body.email;
	let plainPass = req.body.password;

	//each user gets their own random salt, saved with the hash as salt:hash
	let salt = crypt.randomBytes(16).toString('hex');
	let passwordHash = salt + ":" + hashPassword(plainPass, salt);

	let sql = "insert into users (username,email,password_hash) values (?,?,?)";
	conn.query(sql,[username,email,passwordHash],function(err,result)
	{
		if (err)
		{
			console.log("There was an error registering a user",err);
			if (err.code === "ER_DUP_ENTRY")
				res.send('<p>That username or e-mail is already taken. <a href="register.html">Try again</a> or <a href="login.html">Login</a> here</p>');
			else
				res.send('<p>Something went wrong while registering. <a href="register.html">Try again</a></p>');
		}
		else
			res.send('<p>You have successfully registered. <a href="login.html">Login</a> here</p>');
	});
});

//log a user in
app.post("/login",function(req,res)
{
	let username = req.body.username;
	let plainPass = req.body.password;

	let sql = "select password_hash from users where username = ?";
	conn.query(sql,[username],function(err,result)
	{
		if (err)
		{
			console.log("There was an error logging in",err);
			res.send('<p>Something went wrong while logging in. <a href="login.html">Try again</a></p>');
			return;
		}

		let loggedIn = false;
		if (result.length > 0)
		{
			//split the stored value back into its salt and hash, then compare
			let parts = result[0].password_hash.split(":");
			loggedIn = parts.length === 2 && hashPassword(plainPass, parts[0]) === parts[1];
		}

		if (loggedIn)
			res.send('<p>You have logged in successfully</p>');
		else
			res.send('<p>The login credentials were incorrect. <a href="login.html">Back to login</a></p>');
	});
});
