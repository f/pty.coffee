require("coffee-script/register");
var PTYLoader = require("./source/index.coffee");
module.exports = PTYLoader(process.platform === 'win32');
