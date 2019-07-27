var exec = require('cordova/exec');

exports.playVideo = function (params, success, error) {
    exec(success, error, 'videoplayer', 'playVideo', [params]);
};

exports.closeVideo = function (params, success, error) {
    exec(success, error, 'videoplayer', 'closeVideo', [params]);
};