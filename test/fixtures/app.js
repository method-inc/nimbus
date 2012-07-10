var express = require('express');

var app = express();

app.use(function(req, res, next) {
  res.send("Hello, World!");
});

app.listen(80);