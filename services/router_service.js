/*global require */
// require is a global node function/keyword

var models = require('../models/models');

module.exports = function(app, io, logger){
	var Patient = require('./rest/patient.js');
	new Patient(app, models, io, logger);

	var Reminder = require('./rest/reminder.js');
	new Reminder(app, models, io, logger);

	var ActionHandler = require('./action_handler.js');
	new ActionHandler(models, io, logger);
};