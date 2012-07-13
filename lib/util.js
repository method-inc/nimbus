var _ = require('underscore')._;
var fs = require('fs');
var exec = require('child_process').exec;
var spawn = require('child_process').spawn;

// mustache templates
_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g,
  evaluate: /<%([\s\S]+?)%>/g
};

module.exports = {
  remoteScript: function(options, done) {
    var string = options.file ? fs.readFileSync(options.file, 'utf-8') : options.string;
    var template = _.template(string);
    var result = template(options.data || {});
    var copy = ('copy' in options) ? options.copy : true;
    var path = options.path || '/tmp/remoteScript';
    fs.writeFileSync('/tmp/remoteScript', result, 'utf-8');
    fs.chmodSync('/tmp/remoteScript', '755');

    // Create SSH process
    // TODO: use this instead of all the piping for node 0.8.x:
    //var ssh = spawn('ssh', [options.remote, 'bash -s'], { stdio: 'inherit' });
    var ssh = spawn('ssh', [options.remote, 'bash -s']);

    // Create readable file stream from local script
    var tmpFile = fs.createReadStream('/tmp/remoteScript');

    // Pipe output from SSH to output from this process
    ssh.stdout.pipe(process.stdout, {end: false});
    ssh.stderr.pipe(process.stderr, {end: false});

    // Resume input on this process and pipe it to SSH
    process.stdin.resume();
    process.stdin.pipe(ssh.stdin, {end: false});
    process.stdin.on('end', function() {
      ssh.stdin.write('exit', 'utf-8');
    });

    // Pipe the local script as SSH input
    tmpFile.pipe(ssh.stdin);

    // Complete whenever SSH exits
    ssh.on('exit', function(err, result) {
      // TODO: unlink temp script file
      console.log("SSH exit");
      process.stdin.pause();
      return done(err);
    });
  },
  localCmd: function(options, done) {
    var proc = spawn(options.cmd, options.args, options.options);

    proc.stdout.pipe(process.stdout, {end: false});
    proc.stderr.pipe(process.stderr, {end: false});

    process.stdin.resume();
    process.stdin.pipe(proc.stdin, {end: false});
    process.stdin.on('end', function() {
      proc.stdin.write('exit', 'utf-8');
    });

    proc.on('exit', function(err, result) {
      process.stdin.pause();
      return done(err);
    });
  }
};
