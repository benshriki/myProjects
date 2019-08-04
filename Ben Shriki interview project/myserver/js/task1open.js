                                   
var fs = require('fs');
var text = fs.readFileSync("./dllfiles.txt");
var filetxt=text.toString();
var textByLine = fs.readFileSync('dllfiles.txt').toString().split("\n");
console.log(text);