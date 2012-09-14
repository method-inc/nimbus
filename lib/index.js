var _ = require('underscore')._;

function Nimbus(options) {
  this.path = options.path || process.cwd();
  this.config = this.getConfig();
  this.handlers = {
    'ubuntu-vps': require('./ubuntu_vps')
  };
}

// TODO change config keys to "serviceName@host serviceType"

Nimbus.prototype.getConfig = function() {
  var config = require(this.path + '/../nimbus.json');
  var key, service, userHost, user, host;

  // augment 'services'
  config.names = {};
  for (key in config.services) {
    if (key !== 'defaults') {
      userHost = key.split('@');
      user = userHost[0];
      host = userHost[1];
      // create simple host entry if none exists for this service
      config.hosts[host] = config.hosts[host] || {};
      // add host and name information to each service (for convenience)
      _.extend(config.services[key], {
        name: user,
        host: config.hosts[host]
      });
      // add a 'names' property to the config file with named targets
      config.names[user] = config.services[key];
      // fill in default values
      _.defaults(config.services[key], config.services.defaults);
    }
  }

  // augment 'hosts'
  for (key in config.hosts) {
    if (key !== 'defaults') {
      config.hosts[key].publicIP = key;
      config.hosts[key].gatewayIP = key.slice(0, key.lastIndexOf('.')) + '.1';
      // fill in default values
      _.defaults(config.hosts[key], config.hosts.defaults);
    }
  }

  //console.log(JSON.stringify(config, null, 4));
  return config;
};

Nimbus.prototype.getService = function(target) {
  var service = this.config.names[target];
  if (!service) {
    throw new Error("No such service in nimbus.json: " + service);
  }
  return service;
};

Nimbus.prototype.getHandler = function(service) {
  var handler = this.handlers[service.host.platform];
  if (!handler) {
    throw new Error("No handler for platform: " + service.host.platform);
  }
  return handler;
};

Nimbus.prototype.list = function() {
  return _.keys(this.config.services);
};

Nimbus.prototype.provision = function(options, done) {
  var target = options.target;
  var service = this.getService(target);
  var handler = this.getHandler(service);
  handler.provision(service, options, function(err) {
    console.log("disconnected from " + service.name + '@' + service.host.publicIP);
    return done(err);
  });
};

Nimbus.prototype.deploy = function(target, ref, done) {
  var service = this.getService(target);
  var handler = this.getHandler(service);
  handler.deploy(service, ref, done);
};

Nimbus.prototype.update_config = function(target, done) {
  var service = this.getService(target);
  var handler = this.getHandler(service);
  handler.config(service, done);
};

Nimbus.prototype.remote = function(target, done) {

};

module.exports = Nimbus;