/**
 *
 * app.js
 * Node.js Server
 *
 * Written by Brennan Jones
 *
 * Last modified: 26 October 2013
 *
 */


var app = require('http').createServer(handler),
    io = require('socket.io').listen(app),
	static = require('node-static');

var fileServer = new static.Server('./');

app.listen(12345);

// If the URL of the server is opened in a browser.
function handler(request, response)
{
	request.addListener('end', function() {
		fileServer.serve(request, response);
	});
}

// Comment this line to see debug messages.
io.set('log level', 1);

var messages = {};
var messageEvents = {};
var numMessages = 0;

var numClients = 0;

var i;

io.sockets.on('connection', function(socket)
{	
	console.log(socket.handshake.address.address + " (Client ID: " + numClients + ") signed on [" + (new Date()).toUTCString() + "]");
	
	// Send all previously drawn paths to new client.
	for (i = 0; i < numMessages; i++) {
		socket.emit(messageEvents[i], messages[i]);
	}
	
	// Broadcast new client information to all clients except new client.
	socket.broadcast.emit('NewClient', { clientId: numClients });
	
	// Save message data.
	messageEvents[numMessages] = 'NewClient';
	messages[numMessages] = { clientId: numClients };
	numMessages++;
	
	// Allow the new client to draw.
	socket.emit('AllowToDraw', { clientId: numClients });
	
	numClients++;
	
	/* HANDLERS */
	
	socket.on('Echo', function(data)
	{
		console.log(data.echo);
	});
	
	socket.on('Pan', function(data)
	{
		// Broadcast to all except new clients.
		socket.broadcast.emit('Pan', data);
		
		// Save message data.
		messageEvents[numMessages] = 'Pan';
		messages[numMessages] = data;
		numMessages++;
	});
});