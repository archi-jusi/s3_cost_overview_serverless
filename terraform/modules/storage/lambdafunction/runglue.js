const AWS = require('aws-sdk');
let gluecrawlername = process.env.CRAWLNAME;
exports.handler = function (event, context, callback) {
const glue = new AWS.Glue();
glue.startCrawler({ Name: gluecrawlername }, function (err, data) {
    if (err) {
        console.log("Error: " + err);
    } 
    else {
        console.log(data); 
    }

});
};
