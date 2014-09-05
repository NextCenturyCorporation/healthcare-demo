/*global require */
// require is a global node function/keyword
var config = require('./config');


var winston = require('winston');
//Load and set up the logger
var logger = new (winston.Logger)({
	//Make it log to both the console and a file 
	transports : [new (winston.transports.Console)({level:config.log_level}),
					new (winston.transports.File)({filename: 'logs/general.log'})]
});
logger.DO_LOG = true;


var mongoose = require('mongoose');
/**
 * Connect to the DB now, if we should at all.
 * Mongoose only needs to connect once, it will be shared
 * between all files
**/
if(!config.noDB){
	var connectString = 'mongodb://' + config.db_host + ':' + config.db_port + '/' + config.db_collection;
	mongoose.connect(connectString, function(err) {
		if (err !== undefined) {
			logger.error('Unable to connect to ' + connectString);
			throw err;
		} else {
			logger.warn('Connected to ' + connectString);			
		}
	});
}

var express = require('express');
var fs = require('fs');
var app = express();
var httpsApp = express();
var server = require('http').createServer(app);

// Create options for creation to Express httpsServer
var options = {
  key: fs.readFileSync('owf/apache-tomcat-7.0.21/certs/healthcare-demo-ca.key'),
  cert: fs.readFileSync('owf/apache-tomcat-7.0.21/certs/healthcare-demo-ca.crt'),
  passphrase:'changeit'
}	
// Create the httpsServer using the options and httpsApp Express server
var httpsServer = require('https').createServer(options, httpsApp);

// Configure the Express http server
configureExpress (app);       // used to run nodeJs in http mode
// Configure the Express https server
configureExpress (httpsApp);  // used to run nodeJs in https mode

var socketio = require('socket.io');
//Use Socket.IO for http server
var io = socketio.listen(server);
io.set('log level', 1);

//configure socketio for http server
io.on('connection', function(socket) {
	socket.on('join_room', function (data) {
		if(data.room === 'EVEREST.data.workflow') {
			logger.debug("Joining socket to EVEREST.data.workflow room");
			socket.join('EVEREST.data.workflow');
		}
	});
});

//Use Socket.IO for https server
var httpsIo = socketio.listen(httpsServer);
httpsIo.set('log level', 1);

//configure socketio for https server
httpsIo.on('connection', function(socket) {
	socket.on('join_room', function (data) {
		if(data.room === 'EVEREST.data.workflow') {
			logger.debug("Joining socket to EVEREST.data.workflow room");
			socket.join('EVEREST.data.workflow');
		}
	});
});

// establish listener for the http server
server.listen(config.port, function(){
//  logger.debug("Express server listening on port " + server.address().port + " in " + app.settings.env + " mode");
  logger.info("Express server listening on port " + server.address().port + " in " + app.settings.env + " mode");
});

// establish listener for the http server
httpsServer.listen(config.https_port, function(){
  //logger.debug("Express httpsServer listening on port " + server.address().port + " in " + httpsApp.settings.env + " mode");
  logger.info("Express httpsServer listening on port " + httpsServer.address().port + " in " + httpsApp.settings.env + " mode");
});

//Event routes
logger.debug('Loading events');
var RouterService = require('./services/router_service.js');
// establish routerServices for the http and https Express servers
var routerService = new RouterService(app, io, logger);
var httpRouterService = new RouterService(httpsApp, httpsIo, logger);

/**
 * helper menthod used to configure an Express server
 * @param app The Express server to configure
 */
function configureExpress (app) {

    app.configure(function(){
	app.use(express.bodyParser());
	app.use(express.methodOverride());
	app.use(app.router);
        // set the starting point base url and directory where your files are.
	app.use(express.static(__dirname + '/static'));
	// allow jsonp to be used with jquery GET callback on REST calls
	app.enable("jsonp callback");

	/**
	 *  allow Cross-Origin Resource Sharing (CORS)
	 *  for cross domain access
	 */
	app.all('*', function(req, res, next){
		if (!req.get('Origin')) {
			return next();
		}
		// use "*" here to accept any origin
		res.set('Access-Control-Allow-Origin', '*');
		res.set('Access-Control-Allow-Methods', 'GET, POST, DEL, DELETE, PUT, SEARCH, OPTIONS');
		res.set('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type');
		// res.set('Access-Control-Allow-Max-Age', 3600);
		if ('OPTIONS' === req.method) {
			return res.send(200);
		}
		return next();
	});

	/**
	 * Custom error handler
	 * This is modeled off the connect errorHandler
	 * https://github.com/senchalabs/connect/blob/master/lib/middleware/errorHandler.js
	 * http://stackoverflow.com/questions/7151487/error-handling-principles-for-nodejs-express-apps
	**/
	/* jshint -W098 */  // errorHandler signature needs to be the four params, even if they go unused
	app.use(function errorHandler(err, req, res, next){
		if (err.status) { 
			res.statusCode = err.status;
		}
		if (res.statusCode < 400) {
			res.statusCode = 500;
		}
		//Send back json
		res.setHeader('Content-Type', 'application/json');
		//Do not send the whole stack, could have security issues
		res.end(JSON.stringify({error: err.message}));
		logger.error('Error ', {stack: err.stack});
	});
    });

}
