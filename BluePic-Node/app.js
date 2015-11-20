/**
 * @license
 * Licensed Materials - Property of IBM
 * 5725-I43 (C) Copyright IBM Corp. 2014, 2015. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

var when = require('when');
var express = require('express');
var bodyParser = require('body-parser');
var env = require('./config/localEnv');
var app = express();
app.use(bodyParser.json());
var db;
var cloudant;
var dbCredentials = {
	dbName : 'bluepic_db'
};

// CONNECT TO CLOUDANT DB 
if(process.env.VCAP_SERVICES) {
	var vcapServices = JSON.parse(process.env.VCAP_SERVICES);
	if(vcapServices.cloudantNoSQLDB) {
		dbCredentials.host = vcapServices.cloudantNoSQLDB[0].credentials.host;
		dbCredentials.port = vcapServices.cloudantNoSQLDB[0].credentials.port;
		dbCredentials.user = vcapServices.cloudantNoSQLDB[0].credentials.username;
		dbCredentials.password = vcapServices.cloudantNoSQLDB[0].credentials.password;
		dbCredentials.url = vcapServices.cloudantNoSQLDB[0].credentials.url;
		}		
		
} else{
	console.warn('VCAP_SERVICES environment variable not set - localEnv.js');
	dbCredentials.host = env.HOST;
	dbCredentials.port = env.PORT;
	dbCredentials.user = env.USER;
	dbCredentials.password = env.PASSWORD;
	dbCredentials.url = env.URL;
}

// Load the Cloudant library. 
var Cloudant = require('cloudant');
 
// Initialize Cloudant with settings from env variables 
var username = dbCredentials.user;
var password = dbCredentials.password;
// Login
var cloudant = Cloudant({account:username, password:password});

// Specify which db to work with
db = cloudant.use(dbCredentials.dbName);

// DEFINE ROUTES 
// Redirect to mobile backend application doc page when accessing the root context
app.get('/', function(req, res){
	res.sendfile('public/index.html');
});

// Endpoint to get cloudant API key/password from a fb user id. 
app.post('/cloudantapi', function(req, res) {
	console.log(req);
	var fb_id = req.body.fb_id;
	var profile_name = req.body.profile_name;
	if (!fb_id) {
		res.json({'msg':'Need to provide fb id!'});
	}
	else if (!profile_name) {
		res.json({'msg':'Need to provide profile name!'});
	}
	// Send facebook id and profile name to Cloudant. 
	else {
		sendFBID(fb_id, profile_name)
		.then(function(val) {
			console.log(val);
			res.json(val);
		});
	}
})


// START APP
var port = (process.env.VCAP_APP_PORT || 3000);
app.listen(port);
console.log("Mobile backend app is listening at " + port);


// FUNCTIONS

// Creates profile if id doesn't exist. 
function sendFBID(id, name) {
	var deferred = when.defer();
	// Query the profile view
	db.view('profilesView', 'profiles-view', {keys:[id]},function(err, body) {
	if (!err) {
		if (body.rows.length) {
			console.log('User with id exists.') 
			var response = {'msg':'User already exists.'};
			deferred.resolve(response);
		}
		else {
			// User with id does NOT exist.
			console.log('User with id DOES NOT exists, updating cloudant...')
			updateCloudant(id, name); 
			var response = {'msg':'User DOES NOT exist, created in cloudant.'};
			deferred.resolve(response);
		}
	}
	});
	return deferred.promise;
}

function updateCloudant(id, name) {	
	db.insert({'name':name,'Type':'profile' }, id, function(err, body, header) {
      if (err) {
        return console.log('Error inserting', err.message);
      }
      console.log('You have inserted the profile.');
      
    });
}

