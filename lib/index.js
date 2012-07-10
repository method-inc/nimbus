var _ = require('underscore')._;

var SPECIAL = ['privateConfig', 'defaults'];

function Nimbus(options) {
  this.path = options.path || process.cwd();
  this.config = this.getConfig();
  this.handlers = {
    'ubuntu-vps': require('./ubuntu_vps')
  };
}

// TODO change config keys to "serviceName@host serviceType"

Nimbus.prototype.getConfig = function() {
  var raw = require(this.path + '/../nimbus.json');
  var json = {};
  var names = {};
  for (var key in raw) {
    if (SPECIAL.indexOf(key) === -1) {
      json[key] = raw[key];
      var sections = key.split('@');
      raw[key] = _.extend({}, raw.defaults, raw[key], {
        name: sections[0],
        host: sections[1]
      });
      names[sections[0]] = raw[key];
    }
  }
  return {
    json: json,
    names: names,
    local: raw.local
  };
};

Nimbus.prototype.list = function() {
  return _.keys(this.config.json);
};

Nimbus.prototype.provision = function(target, done) {
  var names = this.config.names;
  var targetData = names[target];
  if (!targetData) {
    throw new Error("No such target in nimbus.json: " + target);
  }
  var handler = this.handlers[targetData.platform];
  if (!handler) {
    throw new Error("No handler for platform: " + targetData.platform);
  }
  handler.provision(targetData, done);
};


module.exports = Nimbus;