require("dotenv").config(); //loads the MySQL password from the .env file

const express = require("express"); //imports the express module
const crypt = require("crypto"); //used to hash passwords
const session = require("express-session"); //keeps users logged in between pages
const cookieParser = require("cookie-parser"); //reads cookies sent by the browser
const app = express(); //creates the express application object
app.use(express.urlencoded({ extended: true })); //lets us read form data from req.body
app.use(cookieParser());

app.use(session({
	secret: process.env.SESSION_SECRET, // Used to sign the session ID cookie
	resave: false,                      // Prevents resaving unchanged sessions
	saveUninitialized: false,           // Prevents storing empty, uninitialized sessions
	cookie: {
		maxAge: 60000 * 60,             // Cookie expiry in milliseconds (1 hour)
		httpOnly: true,                 // Protects against XSS attacks
		secure: false                   // Set to true if using HTTPS
	}
}));
app.use(express.static("public")); //register public as the directory for static files

const mysql = require("mysql2"); //uses new mysql package
const requiredDatabaseSettings = ["MYSQL_USER", "MYSQL_PASSWORD", "MYSQL_DATABASE", "SESSION_SECRET"];
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

//makes user input safe to put inside HTML
function escapeHtml(text)
{
	return String(text).replace(/[&<>"']/g, (c) => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
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

	let sql = "select user_id, username, email, password_hash from users where username = ?";
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
		{
			//remember who is logged in for the rest of the session
			req.session.user = {user_id: result[0].user_id, username: result[0].username, email: result[0].email};
			res.send(`<p>You have logged in successfully ${escapeHtml(username)}.<br> Visit your <a href="/profile">Profile</a></p>`);
		}
		else
			res.send('<p>The login credentials were incorrect. <a href="login.html">Back to login</a></p>');
	});
});

//shows the logged in user's info
app.get("/profile",function(req,res)
{
	if (!req.session.user)
		res.send('<p>You are not logged in. Please <a href="login.html">Login here</a>.</p>');
	else
		res.send(`<p>Hi ${escapeHtml(req.session.user.username)}. Your e-mail is ${escapeHtml(req.session.user.email)}.<br><a href="Main.html">Go to your page</a> | <a href="/logout">Logout</a></p>`);
});

//sends the logged in user as JSON so pages can show their name
app.get("/user",function(req,res)
{
	if (!req.session.user)
		res.status(401).json({error: "Not logged in"});
	else
		res.json(req.session.user);
});

//logs the user out
app.get("/logout",function(req,res)
{
	req.session.destroy((err)=>
	{
		if (err) res.send("Error logging out");
		else res.send('<p>Logged out successfully! <a href="login.html">Login Here</a></p>');
	});
});
