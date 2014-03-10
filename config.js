var config = {};

//Port to listen on
config.port = process.env.PORT || 8081;
//Database address
config.db_host = process.env.DB_HOST || '127.0.0.1';
//Database port
config.db_port = process.env.DB_PORT || 27017;
//Collection name
config.db_collection = process.env.DB_COLLECTION || 'healthcare-demo';

config.log_level = process.env.LOG_LEVEL || 'debug';

config.paramDefaults = {
	listCount: null,
	listOffset: 0,
	listSort: 1,
	listSortKey: "_id",
	listStart: new Date(0),
	listEnd: new Date('01/01/3000'),
	listDate: 'createdDate'
};

module.exports = config;