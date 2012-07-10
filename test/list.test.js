var should = require('should');
var exec = require('child_process').exec;

describe('nimbus list', function() {
  it('should list all deployment targets', function(done) {
    var options = {
      cwd: __dirname + '/fixtures'
    };
    exec('../../bin/nimbus list', options, function(err, stdout, stderr) {
      should.not.exist(err);
      stderr.should.be.empty;
      should.exist(stdout);
      stdout.should.not.be.empty;
      stdout.should.equal('node 66.175.213.8 prod_web1\nnode 5.6.7.8 prod_web2\nmongo 2.3.4.5 prod_db1\nredis 6.7.8.9 prod_mq1\nnginx 9.1.2.3 prod_media1\nnode 3.4.5.6 staging_web1\nmongo 3.4.5.6 staging_db1\nredis 3.4.5.6 staging_mq1\n');
      return done();
    });
  });
});