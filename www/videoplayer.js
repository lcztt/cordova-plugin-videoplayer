
var exec = require('cordova/exec');

function videoplayer() {

}

videoplayer.prototype.playVideo = function (params, success, error) {
    exec(success, error, 'videoplayer', 'playVideo', [params]);
};

videoplayer.prototype.closeVideo = function (params, success, error) {
    exec(success, error, 'videoplayer', 'closeVideo', [params]);
};

videoplayer.prototype.pauseVideo = function (params, success, error) {
    exec(success, error, 'videoplayer', 'pauseVideo', [params]);
};

videoplayer.prototype.replay = function (params, success, error) {
    exec(success, error, 'videoplayer', 'replay', [params]);
};

videoplayer.prototype.mute = function (params, success, error) {
    exec(success, error, 'videoplayer', 'mute', [params]);
};

videoplayer.prototype.onVideoPlayEvent = function (eventID, params) {
    cordova.fireDocumentEvent('videoplayer.onVideoPlayEvent', {
        eventID: eventID,
        params: params
    })
};

if (!window.videoplayer) {
    window.videoplayer = new videoplayer();
}

module.exports = new videoplayer();
