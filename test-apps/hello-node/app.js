require("cf-autoconfig");
var express = require("express");
var app = express();

app.get('/', function(req, res) {
    res.send('\n\nHello from Cloud Foundry\n\n');
});

app.listen(3000);
