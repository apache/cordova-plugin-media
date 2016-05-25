/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var mediaObjects = {};
var isMeteringEnabled = false;

/**
 * This class provides access to the device media, interfaces to both sound and video
 *
 * @constructor
 * @param src                   The file name or url to play
 * @param successCallback       The callback to be called when the file is done playing or recording.
 *                                  successCallback()
 * @param errorCallback         The callback to be called if there is an error.
 *                                  errorCallback(int errorCode) - OPTIONAL
 * @param statusCallback        The callback to be called when media status has changed, including duration,
 *                                  position and audio level values.
 *                                  statusCallback(int statusCode, value) - OPTIONAL
 * @param meteringEnabled       The whether or not to turn on audio level metering for recording or playback. - OPTIONAL
 */
var AudioMRP = function(src, successCallback, errorCallback, statusCallback, meteringEnabled) {
    argscheck.checkArgs('sFFF', 'AudioMRP', arguments);
    this.id = utils.createUUID();
    mediaObjects[this.id] = this;
    this.src = src;
    this.successCallback = successCallback;
    this.errorCallback = errorCallback;
    this.statusCallback = statusCallback;
    isMeteringEnabled = meteringEnabled;
    this._duration = -1;
    this._position = -1;
    this._micAccess = false;
    
    console.log('JS: AudioMRP plugin: Creating AudioMRP object: isMeteringEnabled: ' + isMeteringEnabled);
    exec(this.successCallback, this.errorCallback, "AudioMRP", "create", [this.id, this.src, isMeteringEnabled]);
};

// AudioMRP messages -- These are used internally by the plugin
AudioMRP.MEDIA_STATE = 1;
AudioMRP.MEDIA_DURATION = 2;
AudioMRP.MEDIA_POSITION = 4;
AudioMRP.MEDIA_AUDIO_LEVEL = 6;
AudioMRP.MEDIA_MICROPHONE_ACCESS = 7;
AudioMRP.MEDIA_ERROR = 99;

// AudioMRP states -- these are reported to whatever is using the AudioMRP plugin
AudioMRP.MEDIA_NONE = 0;
AudioMRP.MEDIA_RECORD_START = 8;
AudioMRP.MEDIA_RECORD_STOP = 10;
AudioMRP.MEDIA_PLAY_START = 12;
AudioMRP.MEDIA_PLAY_PAUSE = 14;
AudioMRP.MEDIA_PLAY_STOP = 16;
AudioMRP.MEDIA_PLAY_COMPLETE = 18;
AudioMRP.MEDIA_DURATION_REPORT = 20;
AudioMRP.MEDIA_POSITION_REPORT = 22;
AudioMRP.MEDIA_AUDIO_LEVEL_REPORT = 24;
AudioMRP.MEDIA_MICROPHONE_ACCESS_REPORT = 26;

// "static" function to return existing objs.
AudioMRP.get = function(id) {
    return mediaObjects[id];
};

/**
 * Start or resume playing audio file.
 */
AudioMRP.prototype.play = function(options) {
    exec(null, null, "AudioMRP", "startPlayingAudio", [this.id, this.src, options]);
};

/**
 * Stop playing audio file.
 */
AudioMRP.prototype.stop = function() {
    var me = this;
    exec(function() {
        me._position = 0;
    }, this.errorCallback, "AudioMRP", "stopPlayingAudio", [this.id]);
};

/**
 * Seek or jump to a new time in the track..
 */
AudioMRP.prototype.seekTo = function(milliseconds) {
    var me = this;
    exec(function(p) {
        me._position = p;
    }, this.errorCallback, "AudioMRP", "seekToAudio", [this.id, milliseconds]);
};

/**
 * Pause playing audio file.
 */
AudioMRP.prototype.pause = function() {
    exec(null, this.errorCallback, "AudioMRP", "pausePlayingAudio", [this.id]);
};

/**
 * Get duration of an audio file.
 * The duration is only set for audio that is playing, paused or stopped.
 *
 * @return  duration or -1 if not known.
 */
AudioMRP.prototype.getDuration = function() {
    exec(null, this.errorCallback, "AudioMRP", "getDurationAudio", [this.id]);
};

/**
 * Get position of audio.
 */
AudioMRP.prototype.getCurrentPosition = function(success, fail) {
    var me = this;
    exec(function(p) {
        me._position = p;
        success(p);
    }, fail, "AudioMRP", "getCurrentPositionAudio", [this.id]);
};

/**
 * Start recording audio file.
 */
AudioMRP.prototype.startRecord = function() {
    exec(null, this.errorCallback, "AudioMRP", "startRecordingAudio", [this.id, this.src]);
};

/**
 * Stop recording audio file.
 */
AudioMRP.prototype.stopRecord = function() {
    exec(null, this.errorCallback, "AudioMRP", "stopRecordingAudio", [this.id]);
};

/**
 * Release the resources.
 */
AudioMRP.prototype.release = function() {
    exec(null, this.errorCallback, "AudioMRP", "release", [this.id]);
};

/**
 * Adjust the volume.
 */
AudioMRP.prototype.setVolume = function(volume) {
    exec(null, null, "AudioMRP", "setVolume", [this.id, volume]);
};

/**
 * Adjust the playback rate.
 */
AudioMRP.prototype.setRate = function(rate) {
    if (cordova.platformId === 'ios'){
        exec(null, null, "AudioMRP", "setRate", [this.id, rate]);
    } else {
        console.warn('media.setRate method is currently not supported for', cordova.platformId, 'platform.');
    }
};

/**
 * Force a microphone request event, rather than wait for the first audio recording to do so.
 */
AudioMRP.prototype.requestMicrophoneAccess = function() {
    exec(null, this.errorCallback, "AudioMRP", "requestMicAccess", [this.id]);
};


/**
 * Audio has status update.
 * PRIVATE
 *
 * @param id            The media object id (string)
 * @param msgType       The 'type' of update this is
 * @param value         Use of value is determined by the msgType
 */
AudioMRP.onStatus = function(id, msgType, value) {

    var media = mediaObjects[id];

    if (media) {
        switch(msgType) {
            case AudioMRP.MEDIA_STATE :
                if (media.statusCallback) {
                    media.statusCallback(value);
                }
                break;
            case AudioMRP.MEDIA_AUDIO_LEVEL :
                if (isMeteringEnabled) {
                    media.statusCallback(AudioMRP.MEDIA_AUDIO_LEVEL_REPORT, value);
                }
                break;
            case AudioMRP.MEDIA_DURATION :
                media._duration = Number(value);
                media.statusCallback(AudioMRP.MEDIA_DURATION_REPORT, media._duration);
                break;
            case AudioMRP.MEDIA_ERROR :
                if (media.errorCallback) {
                    media.errorCallback(value);
                }
                break;
            case AudioMRP.MEDIA_POSITION :
                media._position = Number(value);
                media.statusCallback(AudioMRP.MEDIA_POSITION_REPORT, media._position);
                break;
            case AudioMRP.MEDIA_MICROPHONE_ACCESS :
                media.statusCallback(AudioMRP.MEDIA_MICROPHONE_ACCESS_REPORT, value);
                break;
            default :
                if (console.error) {
                    console.error("Unhandled AudioMRP.onStatus :: " + msgType);
                }
                break;
        }
    } else if (console.error) {
        console.error("Received AudioMRP.onStatus callback for unknown media :: " + id);
    }

};

module.exports = AudioMRP;

function onMessageFromNative(msg) {
    if (msg.action == 'status') {
        AudioMRP.onStatus(msg.status.id, msg.status.msgType, msg.status.value);
    } else {
        throw new Error('Unknown media action' + msg.action);
    }
}

//if (cordova.platformId === 'android' || cordova.platformId === 'amazon-fireos' || cordova.platformId === 'windowsphone') {
//
//    var channel = require('cordova/channel');
//
//    channel.createSticky('onMediaPluginReady');
//    channel.waitForInitialization('onMediaPluginReady');
//
//    channel.onCordovaReady.subscribe(function() {
//        exec(onMessageFromNative, undefined, 'Media', 'messageChannel', []);
//        channel.initializationComplete('onMediaPluginReady');
//    });
//}
