pty.coffee
==========

Psuedo Terminal port in CoffeeScript.

Note: Doesn't support Windows bindings.

## Install

```bash
npm install pty.coffee
```

## Example

```coffee
{PTY} = require('pty.coffee');

term = new PTY 'bash', [],
  name: 'xterm-color'
  cols: 80
  rows: 30
  cwd: process.env.HOME
  env: process.env

term.on 'data', (data)->
  console.log data

setTimeout (->
  term.write "ls | grep i\n"
), 1000
```
