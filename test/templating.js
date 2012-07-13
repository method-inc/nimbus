var _ = require('underscore')._;
var fs = require('fs');

_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g,
  evaluate: /<%([\s\S]+?)%>/g
};

var string = fs.readFileSync('../lib/ubuntu_vps/node.sh', 'utf-8');
var template = _.template(string);
var result = template({
  serviceName: 'serviceName',
  authorizedKeys: ['key1', 'key2'],
  nodeVersion: '0.0.1',
  nimbusJSON: '{ "privateConfig": { "working": true } }'
});

console.log("node.sh:");
console.log(result);

string = fs.readFileSync('../lib/ubuntu_vps/environment.sh', 'utf-8');
template = _.template(string);
result = template({
  authorizedKeys: ['key1', 'key2'],
  publicIP: '1.2.3.4',
  gatewayIP: '2.3.4.5',
  privateIP: '3.4.5.6'
});

console.log("environment.sh:");
console.log(result);