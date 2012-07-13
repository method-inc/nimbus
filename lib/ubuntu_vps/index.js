var exec = require('child_process').exec;
var _ = require('underscore')._;
var fs = require('fs');
var util = require('../util');
var async = require('async');

module.exports = {
  provision: function(service, options, done) {
    async.waterfall([
      // Update the environment (root, all service types)
      function environment(done) {
        return util.remoteScript({
          file: __dirname + '/environment.sh',
          remote: 'root@' + service.host.publicIP,
          data: {
            authorizedKeys: service.host.keys.join('\n'),
            publicIP: service.host.publicIP,
            privateIP: service.host.privateIP,
            gatewayIP: service.host.gatewayIP
          }
        }, done);
      },
      // Create the user for the node service (root, node service type)
      function node(done) {
        if (service.type !== 'node') {
          return done();
        }
        return util.remoteScript({
          file: __dirname + '/node.sh',
          remote: 'root@' + service.host.publicIP,
          data: {
            serviceName: service.name,
            authorizedKeys: service.host.keys.join('\n'),
            nodeVersion: service.version,
            nimbusJSON: JSON.stringify({"privateConfig": service.privateConfig}, null, 2),
            updateOnly: options.update
          }
        }, done);
      },
      // Create the user for the mongodb service (root, mongo service type)
      function mongo(done) {
        if (service.type !== 'mongo') {
          return done();
        }
        return util.remoteScript({
          file: __dirname + '/mongo.sh',
          remote: 'root@' + service.host.publicIP,
          data: {
            serviceName: service.name,
            authorizedKeys: service.host.keys.join('\n'),
            mongoVersion: service.version,
            bindIP: service.bind || "127.0.0.1"
          }
        }, done);
      },
      // Create the user for the redis service (root, redis service type)
      function redis(done) {
        if (service.type !== 'redis') {
          return done();
        }
        return util.remoteScript({
          file: __dirname + '/redis.sh',
          remote: 'root@' + service.host.publicIP,
          data: {
            serviceName: service.name,
            redisVersion: service.version,
            port: service.port,
            authorizedKeys: service.host.keys.join('\n'),
            bindIP: service.bind || "127.0.0.1"
          }
        }, done);
      }
    ], done);
  },
  deploy: function(service, ref, done) {
    var cmd = 'git';
    var args = [
      'push',
      'ssh://' + service.name + '@' + service.host.publicIP + '/home/' + service.name + '/repo',
      ref
    ];
    console.log(cmd, args.join(' '));
    console.log("Please be patient, this may take several minutes...");
    return util.localCmd({
      cmd: cmd,
      args: args
    }, done);
  },
  update: function(service, done) {
    if (service.type === 'node') {
      return util.remoteScript({
        file: __dirname + '/node_update.sh',
        remote: 'root@' + service.host.publicIP,
        data: {
          authorizedKeys: service.host.keys.join('\n'),
          nimbusJSON: JSON.stringify({"privateConfig": service.privateConfig}, null, 2)
        }
      });
    }
  }
};