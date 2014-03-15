/**
 * General functions
 */
var general = {};

//General 404 error
general.send404 = function(res){
	res.status(404);
	res.jsonp({error: 'Not found'});
	res.end();
};

//General 500 error
general.send500 = function(res, msg){
	res.status(500);
	res.jsonp({error:'Server error ' + msg});
	res.end();
};

general.getOptions = function(res){
	res.json({"Get Patients": "/patients", 
			"Get One Patient": "/patient"});
	res.end();
};

module.exports = general;