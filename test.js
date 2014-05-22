var pty = require('./');

var term = new pty.PTY('bash', [], {
  name: 'xterm-color',
  cols: 80,
  rows: 30,
  cwd: process.env.HOME,
  env: process.env
});

term.on('data', function(data) {
  console.log(data);
});

setTimeout(function () {
  term.write("ls | grep i\n");
}, 1000);
