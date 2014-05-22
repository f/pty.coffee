module.exports = (win32)->
  require if win32 then "./win/index" else "./unix/index"
