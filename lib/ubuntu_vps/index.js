var exec = require('child_process').exec;
var _ = require('underscore')._;
var fs = require('fs');
var util = require('../util');
var async = require('async');

module.exports = {
  provision: function(target, done) {
    console.log("UBUNTU with", target);

    async.waterfall([
      // Update the environment (root, all service types)
      function environment(done) {
        return util.remoteScript({
          file: __dirname + '/environment.sh',
          remote: 'root@' + target.host,
          data: {
            authorizedKeys: target.keys.join('\n')
          }
        }, done);
      },
      // Create the user for the node service (root, node service type)
      function node(done) {
        if (target.type !== 'node') {
          return done();
        }
        return util.remoteScript({
          file: __dirname + '/node.sh',
          remote: 'root@' + target.host,
          data: {
            serviceName: target.name,
            authorizedKeys: target.keys.join('\n'),
            nodeVersion: target.version
          }
        }, done);
      }
    ], done);


  }
};