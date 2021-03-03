const AWS = require('aws-sdk');
const response = require('./cfn-response');
let gluecrawlername = process.env.CRAWLNAME;
exports.handler = function (event, context, callback) {
    if (event.RequestType === 'Delete') {
        response.send(event, context, response.SUCCESS);
    } else {
        const glue = new AWS.Glue();
        glue.startCrawler({ Name: gluecrawlername }, function (err, data) {
            if (err) {
                if (responseData['__type'] == 'CrawlerRunningException') {
                    callback(null, responseData.Message);
                } else {
                    const responseString = JSON.stringify(responseData);
                    if (event.ResponseURL) {
                        response.send(event, context, response.FAILED, { msg: responseString });
                    } else {
                        callback(responseString);
                    }
                }
            }
            else {
                if (event.ResponseURL) {
                    response.send(event, context, response.SUCCESS);
                } else {
                    callback(null, response.SUCCESS);
                }
            }
        });
    }
};