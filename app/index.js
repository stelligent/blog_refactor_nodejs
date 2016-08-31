'use strict';
var http = require('http');
var config = require('config');
var dbConfig = config.get('app.config');
var server = http.createServer(function (request, response) {
    response.writeHead(200);
    response.write('<p>' + JSON.stringify(dbConfig) + '</p>');
	response.end('<p>HTTP' + request.method + " @ " + Date.now() + '</p>');
});
server.listen(8080);
