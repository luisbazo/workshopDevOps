var express = require('express');
var log4js = require('log4js');
var http = require('http');
var app = express();
var logger = log4js.getLogger('HelloKube');
var isHealthy = true;

var istioError = "false";
var istioDelay = 0;

logger.info("Starting...");


setInterval(function() {
	if (isHealthy) {
		logger.info("lalala....");
	} else {
		logger.info("cough...");
	}
}, 3000);


app.get("/istio/error", function(req, res, next) {
	logger.info("operation /istio/error invoked...");
	istioError = req.query.error;
	logger.info("istioError: " + istioError);
	res.send("istioError set to: "  + istioError);
});


app.get("/istio/delay", function(req, res, next) {
	logger.info("operation /istio/delay invoked...");
	istioDelay = req.query.delay;
	logger.info("delay: " + istioDelay);
	res.send("Delay set to: "  + istioDelay);
});

app.get("/istio/op", function(req, res, next) {
	logger.info("operation /istio/op invoked...");
	setTimeout(function() {
    		if (istioError === "false") {
			logger.info("returning GREEN");
			res.send("Istio GREEN");
		} else {
			logger.info("returning RED");
			res.status(500).send("Istio RED");
		}
	}, istioDelay);
	
});


app.get("/", function(req, res, next) {
	logger.info("operation / invoked...");
	res.send("I'm alive 8!!!");
});

app.get("/env", function(req, res, next) {
	res.json(process.env);
});

app.get("/pod", function(req, res, next) {
	var pod = process.env['HOSTNAME'];
	res.send("Pod serving request: " + pod);
});

app.get("/health", function(req, res, next) {
	if (isHealthy) {
		logger.info("operation /health invoked... returning GREEN");
		res.send("GREEN");
	} else {
		logger.info("operation /health invoked... returning RED");
		res.status(500).send("RED");
	}
});

app.get("/infect", function(req, res, next) {
	logger.info("operation /infect invoked...");
	isHealthy = false;
	res.send("I don't feel that good...");
});

app.get("/kill", function(req, res, next) {
	res.send("You are dead...");
	process.exit();
});

var port = process.env.PORT || 8080;

app.listen(port, function() {
	logger.info('HelloKube listening on port ' + port);
});

