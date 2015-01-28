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

/*global Windows:true */

var cordova = require('cordova'),
    Media = require('org.apache.cordova.media.Media');

var MediaError = require('org.apache.cordova.media.MediaError');

var recordedFile;

var URI_Schema = [
    {re:new RegExp('^ms-appdata://(localhost|)/local'),
        path:Windows.Storage.ApplicationData.current.localFolder.path},
    {re:new RegExp('^cdvfile://localhost/persistent'),
        path:Windows.Storage.ApplicationData.current.localFolder.path},
    {re:new RegExp('^ms-appdata://(localhost|)/temp'),
        path:Windows.Storage.ApplicationData.current.temporaryFolder.path},
    {re:new RegExp('^cdvfile://(localhost|)/temporary'),
        path:Windows.Storage.ApplicationData.current.temporaryFolder.path},
    {re:new RegExp('^file://(localhost|)/'), path:''}
];

module.exports = {
    mediaCaptureMrg:null,

    // Initiates the audio file
    create:function(win, lose, args) {
        var id = args[0];
        var src = args[1];
        var thisM = Media.get(id);
        Media.onStatus(id, Media.MEDIA_STATE, Media.MEDIA_STARTING);

        Media.prototype.node = null;

        var fn = src.split('.').pop(); // gets the file extension
        if (thisM.node === null) {
            if (fn === 'mp3' || fn === 'wma' || fn === 'wav' ||
                fn === 'cda' || fn === 'adx' || fn === 'wm' ||
                fn === 'm3u' || fn === 'wmx' || fn === 'm4a') {
                thisM.node = new Audio(src);
                thisM.node.load();

                var getDuration = function () {
                    var dur = thisM.node.duration;
                    if (isNaN(dur)) {
                        dur = -1;
                    }
                    Media.onStatus(id, Media.MEDIA_DURATION, dur);
                };

                thisM.node.onloadedmetadata = getDuration;
                getDuration();
            }
            else {
                if (lose)
                    lose({code:MediaError.MEDIA_ERR_ABORTED});
            }
        }
    },

    // Start playing the audio
    startPlayingAudio:function(win, lose, args) {
        var id = args[0];
        //var src = args[1];
        //var options = args[2];

        var thisM = Media.get(id);
        // if Media was released, then node will be null and we need to create it again
        if (!thisM.node) {
            module.exports.create(win, lose, args);
        }

        Media.onStatus(id, Media.MEDIA_STATE, Media.MEDIA_RUNNING);

        thisM.node.play();
    },

    // Stops the playing audio
    stopPlayingAudio:function(win, lose, args) {
        var id = args[0];
        try {
            (Media.get(id)).node.pause();
            (Media.get(id)).node.currentTime = 0;
            Media.onStatus(id, Media.MEDIA_STATE, Media.MEDIA_STOPPED);
            win();
        } catch (err) {
            lose("Failed to stop: "+err);
        }
    },

    // Seeks to the position in the audio
    seekToAudio:function(win, lose, args) {
        var id = args[0];
        var milliseconds = args[1];
        try {
            (Media.get(id)).node.currentTime = milliseconds / 1000;
            win();
        } catch (err) {
            lose("Failed to seek: "+err);
        }
    },

    // Pauses the playing audio
    pausePlayingAudio:function(win, lose, args) {
        var id = args[0];
        var thisM = Media.get(id);
        try {
            thisM.node.pause();
            Media.onStatus(id, Media.MEDIA_STATE, Media.MEDIA_PAUSED);
        } catch (err) {
            lose("Failed to pause: "+err);
        }
    },

    // Gets current position in the audio
    getCurrentPositionAudio:function(win, lose, args) {
        var id = args[0];
        try {
            var p = (Media.get(id)).node.currentTime;
            Media.onStatus(id, Media.MEDIA_POSITION, p);
            win(p);
        } catch (err) {
            lose(err);
        }
    },

    // Start recording audio
    startRecordingAudio:function(win, lose, args) {
        var id = args[0];
        var src = args[1];

        var normalizedSrc = src.replace(/\//g, '\\');
        var destPath = normalizedSrc.substr(0, normalizedSrc.lastIndexOf('\\'));
        var destFileName = normalizedSrc.replace(destPath + '\\', '');

        // Initialize device
        Media.prototype.mediaCaptureMgr = null;
        var thisM = (Media.get(id));
        var captureInitSettings = new Windows.Media.Capture.MediaCaptureInitializationSettings();
        captureInitSettings.streamingCaptureMode = Windows.Media.Capture.StreamingCaptureMode.audio;
        thisM.mediaCaptureMgr = new Windows.Media.Capture.MediaCapture();
        thisM.mediaCaptureMgr.addEventListener("failed", lose);

        thisM.mediaCaptureMgr.initializeAsync(captureInitSettings).done(function (result) {
            thisM.mediaCaptureMgr.addEventListener("recordlimitationexceeded", lose);
            thisM.mediaCaptureMgr.addEventListener("failed", lose);
            
            // Start recording
            Windows.Storage.ApplicationData.current.temporaryFolder.createFileAsync(destFileName, Windows.Storage.CreationCollisionOption.replaceExisting).done(function (newFile) {
                recordedFile = newFile;
                var encodingProfile = null;
                switch (newFile.fileType) {
                    case '.m4a':
                        encodingProfile = Windows.Media.MediaProperties.MediaEncodingProfile.createM4a(Windows.Media.MediaProperties.AudioEncodingQuality.auto);
                        break;
                    case '.mp3':
                        encodingProfile = Windows.Media.MediaProperties.MediaEncodingProfile.createMp3(Windows.Media.MediaProperties.AudioEncodingQuality.auto);
                        break;
                    case '.wma':
                        encodingProfile = Windows.Media.MediaProperties.MediaEncodingProfile.createWma(Windows.Media.MediaProperties.AudioEncodingQuality.auto);
                        break;
                    default:
                        lose("Invalid file type for record");
                        break;
                }
                thisM.mediaCaptureMgr.startRecordToStorageFileAsync(encodingProfile, newFile)
                .done(
                    function() {
                        Media.onStatus(id, Media.MEDIA_STATE, Media.MEDIA_RUNNING);
                        win();
                    }, 
                    lose
                );
            }, lose);
        }, lose);
    },

    // Stop recording audio
    stopRecordingAudio:function(win, lose, args) {
        var id = args[0];
        var thisM = Media.get(id);
        function done(cb,arg) {
            Media.onStatus(id, Media.MEDIA_STATE, Media.MEDIA_STOPPED);
            cb(arg);
        }
        thisM.mediaCaptureMgr.stopRecordAsync().done(function () {
            var fname = thisM.src.replace(/^.*[\\\/]([^\\\/]+)$/,'$1');
            var path = thisM.src.substr(0,thisM.src.lastIndexOf(fname));
            URI_Schema.every(function(s) {
                if (!s.re.test(path))
                    return true;
                path=decodeURIComponent(path.replace(s.re,s.path));
            });
            path = path.replace(/\//g, '\\');
            if (path && recordedFile.path != path+fname) {
                Windows.Storage.StorageFolder.getFolderFromPathAsync(path).done(function(destFolder) {
                    recordedFile.copyAsync(destFolder, fname, Windows.Storage.CreationCollisionOption.replaceExisting)
                    .done(function(){done(win);}, function(err){done(lose,err);});
                }, function(err){done(lose,err);});
            } else {
                // if path is not defined, we leave recorded file in temporary folder (similar to iOS)
                done(win);
            }
        }, lose);
    },

    // Release the media object
    release:function(win, lose, args) {
        var id = args[0];
        var thisM = Media.get(id);
        try {
            delete thisM.node;
            if (thisM.mediaCaptureMgr) {
                thisM.mediaCaptureMgr.close();
                delete thisM.mediaCaptureMgr;
            }
        } catch (err) {
            lose("Failed to release: "+err);
        }
    },
    setVolume:function(win, lose, args) {
        var id = args[0];
        var volume = args[1];
        var thisM = Media.get(id);
        thisM.volume = volume;
    }
};

require("cordova/exec/proxy").add("Media",module.exports);
