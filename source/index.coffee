pty = require '../build/Release/pty.node'
{ReadStream} = require 'tty'

class PTY

  @INSTANCE_COUNT: 0

  @CLEAN_ENV_KEYS: [
    # Make sure we didn't start our
    # server from inside tmux.
    'TMUX', 'TMUX_PANE'
    # Make sure we didn't start
    # our server from inside screen.
    # http://web.mit.edu/gnu/doc/html/screen_20.html
    'STY', 'WINDOW'
    # Delete some variables that
    # might confuse our terminal.
    'WINDOWID', 'TERMCAP'
    'COLUMNS', 'LINES'
  ]

  constructor: (file=process.env.SHELL, args=[], @opts={})->

    opts.cols or= 80
    opts.rows or= 24

    opts.env or= process.env

    if opts.env is process.env
      @clearEnvironment opts.env

    opts.name or= opts.env.TERM or 'xterm'
    opts.env.TERM = opts.name
    opts.env = @getPairs opts.env

    if opts.open
      @openPty = pty.open opts.cols, opts.rows
      @readable = yes
      @writable = yes
    else
      @listen @fork file, args, opts.env

  fork: (file, args, env, cwd=process.cwd())->
    {uid, gid, cols, rows} = @opts

    params = [file, args, env, cwd, cols, rows]
    params = params.concat [uid, gid] if uid and gid

    pty.fork params...

  listen: (ptyFork)->
    {@pid, @fd, @pty} = ptyFork

    @socket = new ReadStream @fd
    @setEncoding 'utf8'
    @resume()

    PTY.INSTANCE_COUNT++
    @readable = yes
    @writable = yes

    @on 'error', (err)=>
      @close()
      # EIO, happens when someone closes our child
      # process: the only process in the terminal.
      # node < 0.6.14: errno 5
      # node >= 0.6.14: read EIO
      return if err?.code?.match /errno 5|EIO/
      throw err if @listeners('error').length < 2

    @on 'close', =>
      PTY.INSTANCE_COUNT--
      @close()
      @socket.emit "exit"

  # Helpers
  write      : (data)-> @socket.write data
  end        : (data)-> @socket.end data
  pipe       : (dest, opts)-> @socket.pipe dest, opts
  pause      : -> @socket.pause()
  resume     : -> @socket.resume()

  resize: (@cols=80, @rows=24)-> pty.resize @fd, @cols, @rows

  destroy: ->
    @close()
    @once 'close', => @kill 'SIGHUP'
    @socket.destroy()

  kill: (sig)-> try process.kill @pid, sig or 'SIGHUP'

  redraw: ->
    # We could just send SIGWINCH, but most programs will
    # ignore it if the size hasn't actually changed.
    @resize @cols+1, @rows+1
    setTimeout (=> @resize @cols, @rows), 30

  # Instance Utils

  setEncoding: (encoding)->
    delete @socket._decoder if @socket._decoder
    @socket.setEncoding encoding

  on: (type, callback)->
    @socket.on type, callback
    this

  once: (type, callback)->
    @socket.once type, callback
    this

  off: (type, callback)->
    if callback
      @socket.removeListener type, callback
    else
      @socket.removeAllListeners type
    this

  close: ->
    @socket.writable = @writable = no
    @socket.readable = @readable = no
    @write = -> console.log 'closed'
    @end = -> console.log 'closed'

  emit: -> @socket.emit arguments...
  listeners: (type)-> @socket.listeners type

  # Instance Aliases
  removeAllListeners: (type)-> @off type
  removeListener: PTY::off
  addListener: PTY::on

  # Utils
  getPairs: (object)-> ("#{key}=#{value}" for own key, value of object)
  clearEnvironment: (env)-> delete env[key] for key in PTY.CLEAN_ENV_KEYS

  # Getters
  PTY::__defineGetter__ 'stdout',  -> this
  PTY::__defineGetter__ 'stdin',   -> this
  PTY::__defineGetter__ 'stderr',  -> throw new Error 'No stderr.'
  PTY::__defineGetter__ 'process', -> pty.process(@fd, @pty) or @file

  # Static Aliases
  @fork = @spawn = @createTerminal

  @createSocket: (sock)->
    socket = new ReadStream sock
    socket.setEncoding 'utf8'
    socket.resume()
    socket

  @open: (opts)->
    name = process.argv[0] or 'node'
    opts.open = yes
    session = new PTY name, [], opts
    term = session.openPty

    master = PTY.createSocket term.master
    slave = PTY.createSocket term.slave

    session.socket = master
    session.fd = term.master
    session.pty = term.pty
    session.pid = null

    PTY::INSTANCE_COUNT++

    session.on 'error', (err)=>
      @close()
      throw err if session.listeners('error').length < 2

    session.on 'close', ->
      PTY::INSTANCE_COUNT--
      @close()

    session

  @createTerminal: -> new PTY arguments...

module.exports = {
  native: pty
  Terminal: PTY
  PTY
}
