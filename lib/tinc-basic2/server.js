var os = require('os');
var http = require('http');

const HOSTNAME = os.hostname();
const PORT = 8080; 

var server = http.createServer(function(request, response) {
  console.log("Received request: ", request);
  response.end("Response from " + HOSTNAME + " to requested path " + request.url + "\n");
});

server.listen(PORT, function() {
  console.log("Server listening to http://0.0.0.0:%s", PORT);
});
