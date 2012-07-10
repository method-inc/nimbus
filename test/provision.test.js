var should = require('should');
var exec = require('child_process').exec;

var OPTIONS = {
  cwd: __dirname + '/fixtures'
};

var HOST = '66.175.213.8';

describe('nimbus provision', function() {
  describe('with node target', function() {
    it('should run without error', function(done) {
      exec('../../bin/nimbus provision -t prod_web1', OPTIONS, function(err, stdout, stderr) {
        should.not.exist(err);
        stderr.should.be.empty;
        return done();
      });
    });
    it('should add ssh keys to the remote system', function(done) {
      exec('ssh root@' + HOST + " 'ls /'", function(err, stdout, stderr) {
        should.not.exist(err);
        stderr.should.be.empty;
        stdout.should.not.be.empty;
        return done();
      });
    });
  });
  describe('with mongo target', function() {

  });
  describe('with redis target', function() {

  });
  describe('with nginx target', function() {

  });
});