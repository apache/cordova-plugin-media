---
title: Media
description: Record and play audio on the device.
---
<!--
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->

# cordova-plugin-media

[![Android Testsuite](https://github.com/apache/cordova-plugin-media/actions/workflows/android.yml/badge.svg)](https://github.com/apache/cordova-plugin-media/actions/workflows/android.yml) [![Chrome Testsuite](https://github.com/apache/cordova-plugin-media/actions/workflows/chrome.yml/badge.svg)](https://github.com/apache/cordova-plugin-media/actions/workflows/chrome.yml) [![iOS Testsuite](https://github.com/apache/cordova-plugin-media/actions/workflows/ios.yml/badge.svg)](https://github.com/apache/cordova-plugin-media/actions/workflows/ios.yml) [![Lint Test](https://github.com/apache/cordova-plugin-media/actions/workflows/lint.yml/badge.svg)](https://github.com/apache/cordova-plugin-media/actions/workflows/lint.yml)


This plugin provides the ability to record and play back audio files on a device.

__NOTE__: The current implementation does not adhere to a W3C
specification for media capture, and is provided for convenience only.
A future implementation will adhere to the latest W3C specification
and may deprecate the current APIs.

This plugin defines a global `Media` Constructor.

Although in the global scope, it is not available until after the `deviceready` event.

```js
document.addEventListener("deviceready", onDeviceReady, false);
function onDeviceReady() {
    console.log(Media);
}
```

## Installation

```bash
cordova plugin add cordova-plugin-media
```

## Supported Platforms

- Android
- iOS
- Browser

### Android Quirks

#### SDK Target Less Than 29

From the official [Storage updates in Android 11](https://developer.android.com/about/versions/11/privacy/storage) documentation, the [`WRITE_EXTERNAL_STORAGE`](https://developer.android.com/reference/android/Manifest.permission#WRITE_EXTERNAL_STORAGE) permission is no longer operational and does not provide access.

> If this permission is not allowlisted for an app that targets an API level before [`Build.VERSION_CODES.Q`](https://developer.android.com/reference/android/os/Build.VERSION_CODES#Q) (SDK 29) this permission cannot be granted to apps.

If you need to add this permission, please add the following to your `config.xml`.

```xml
<config-file target="AndroidManifest.xml" parent="/*" xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
</config-file>
```

## Media

```js
var media = new Media(src, mediaSuccess, [mediaError], [mediaStatus]);
```

### Parameters

- __src__: A URI containing the audio content. _(DOMString)_

- __mediaSuccess__: (Optional) The callback that executes after a `Media` object has completed the current play, record, or stop action. _(Function)_

- __mediaError__: (Optional) The callback that executes if an error occurs. It takes an integer error code. _(Function)_

- __mediaStatus__: (Optional) The callback that executes to indicate status changes. It takes a integer status code. _(Function)_

- __mediaDurationUpdate__: (Optional) the callback that executes when the file's duration updates and is available. _(Function)_

__NOTE__: `cdvfile` path is supported as `src` parameter:
```javascript
var my_media = new Media('cdvfile://localhost/temporary/recording.mp3', ...);
```

### Constants

The following constants are reported as the only parameter to the
`mediaStatus` callback:

- `Media.MEDIA_NONE`     = 0;
- `Media.MEDIA_STARTING` = 1;
- `Media.MEDIA_RUNNING`  = 2;
- `Media.MEDIA_PAUSED`   = 3;
- `Media.MEDIA_STOPPED`  = 4;

### Methods

- `media.getCurrentAmplitude`: Returns the current amplitude within an audio file.

- `media.getCurrentPosition`: Returns the current position within an audio file.

- `media.getDuration`: Returns the duration of an audio file.

- `media.play`: Start or resume playing an audio file.

- `media.pause`: Pause playback of an audio file.

- `media.pauseRecord`: Pause recording of an audio file.

- `media.release`: Releases the underlying operating system's audio resources.

- `media.resumeRecord`: Resume recording of an audio file.

- `media.seekTo`: Moves the position within the audio file.

- `media.setVolume`: Set the volume for audio playback.

- `media.startRecord`: Start recording an audio file.

- `media.stopRecord`: Stop recording an audio file.

- `media.stop`: Stop playing an audio file.

- `media.setRate`: Set the playback rate for the audio file.

### Additional ReadOnly Parameters

- __position__: The position within the audio playback, in seconds.
    - Not automatically updated during play; call `getCurrentPosition` to update.

- __duration__: The duration of the media, in seconds.


## media.getCurrentAmplitude

Returns the current amplitude within an audio file.

    media.getCurrentAmplitude(mediaSuccess, [mediaError]);

### Supported Platforms

- Android
- iOS

### Parameters

- __mediaSuccess__: The callback that is passed the current amplitude (0.0 - 1.0).

- __mediaError__: (Optional) The callback to execute if an error occurs.

### Quick Example

```js
// Audio player
//
var my_media = new Media(src, onSuccess, onError);

// Record audio
my_media.startRecord();

mediaTimer = setInterval(function () {
    // get media amplitude
    my_media.getCurrentAmplitude(
        // success callback
        function (amp) {
            console.log(amp + "%");
        },
        // error callback
        function (e) {
            console.log("Error getting amp=" + e);
        }
    );
}, 1000);
```

## media.getCurrentPosition

Returns the current position within an audio file.  Also updates the `Media` object's `position` parameter.

    media.getCurrentPosition(mediaSuccess, [mediaError]);

### Parameters

- __mediaSuccess__: The callback that is passed the current position in seconds.

- __mediaError__: (Optional) The callback to execute if an error occurs.

### Quick Example

```js
// Audio player
//
var my_media = new Media(src, onSuccess, onError);

// Update media position every second
var mediaTimer = setInterval(function () {
    // get media position
    my_media.getCurrentPosition(
        // success callback
        function (position) {
            if (position > -1) {
                console.log((position) + " sec");
            }
        },
        // error callback
        function (e) {
            console.log("Error getting pos=" + e);
        }
    );
}, 1000);
```

## media.getDuration

Returns the duration of an audio file in seconds. If the duration is unknown, it returns a value of -1.


    media.getDuration();

### Quick Example

```js
// Audio player
//
var my_media = new Media(src, onSuccess, onError);

// Get duration
var counter = 0;
var timerDur = setInterval(function() {
    counter = counter + 100;
    if (counter > 2000) {
        clearInterval(timerDur);
    }
    var dur = my_media.getDuration();
    if (dur > 0) {
        clearInterval(timerDur);
        document.getElementById('audio_duration').innerHTML = (dur) + " sec";
    }
}, 100);
```

#### Android Quirk

Newer versions of Android have aggressive routines that limit background processing. If you are trying to get the duration while your app is in the background longer than roughly 5 minutes, you will get more consistent results by using the [`mediaDurationUpdate` callback of the constructor](#parameters). 

## media.pause

Pauses playing an audio file.

    media.pause();


### Quick Example

```js
// Play audio
//
function playAudio(url) {
    // Play the audio file at url
    var my_media = new Media(url,
        // success callback
        function () { console.log("playAudio():Audio Success"); },
        // error callback
        function (err) { console.log("playAudio():Audio Error: " + err); }
    );

    // Play audio
    my_media.play();

    // Pause after 10 seconds
    setTimeout(function () {
        my_media.pause();
    }, 10000);
}
```

## media.pauseRecord

Pauses recording an audio file.

    media.pauseRecord();


### Supported Platforms

- iOS


### Quick Example

```js
// Record audio
//
function recordAudio() {
    var src = "myrecording.mp3";
    var mediaRec = new Media(src,
        // success callback
        function() {
            console.log("recordAudio():Audio Success");
        },

        // error callback
        function(err) {
            console.log("recordAudio():Audio Error: "+ err.code);
        });

    // Record audio
    mediaRec.startRecord();

    // Pause Recording after 5 seconds
    setTimeout(function() {
        mediaRec.pauseRecord();
    }, 5000);
}
```

## media.play

Starts or resumes playing an audio file.

```js
media.play();
```

### Quick Example

```js
// Play audio
//
function playAudio(url) {
    // Play the audio file at url
    var my_media = new Media(url,
        // success callback
        function () {
            console.log("playAudio():Audio Success");
        },
        // error callback
        function (err) {
            console.log("playAudio():Audio Error: " + err);
        }
    );
    // Play audio
    my_media.play();
}
```

### iOS Quirks

- __numberOfLoops__: Pass this option to the `play` method to specify
  the number of times you want the media file to play, e.g.:

        var myMedia = new Media("http://audio.ibeat.org/content/p1rj1s/p1rj1s_-_rockGuitar.mp3")
        myMedia.play({ numberOfLoops: 2 })

- __playAudioWhenScreenIsLocked__: Pass in this option to the `play`
  method to specify whether you want to allow playback when the screen
  is locked.  If set to `true` (the default value), the state of the
  hardware mute button is ignored, e.g.:

        var myMedia = new Media("http://audio.ibeat.org/content/p1rj1s/p1rj1s_-_rockGuitar.mp3");
        myMedia.play({ playAudioWhenScreenIsLocked : true });
        myMedia.setVolume('1.0');

> Note: To allow playback with the screen locked or background audio you have to add `audio` to `UIBackgroundModes` in the `info.plist` file. See [Apple documentation](https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW23). Also note that the audio has to be started before going to background.

- __order of file search__: When only a file name or simple path is
  provided, iOS searches in the `www` directory for the file, then in
  the application's `documents/tmp` directory:

        var myMedia = new Media("audio/beer.mp3")
        myMedia.play()  // first looks for file in www/audio/beer.mp3 then in <application>/documents/tmp/audio/beer.mp3

## media.release

Releases the underlying operating system's audio resources.
This is particularly important for Android, since there are a finite amount of
OpenCore instances for media playback. Applications should call the `release`
function for any `Media` resource that is no longer needed.

    media.release();


### Quick Example

```js
// Audio player
//
var my_media = new Media(src, onSuccess, onError);

my_media.play();
my_media.stop();
my_media.release();
```

## media.resumeRecord

Resume recording an audio file.

    media.resumeRecord();


### Supported Platforms

- iOS


### Quick Example

```js
// Record audio
//
function recordAudio() {
    var src = "myrecording.mp3";
    var mediaRec = new Media(src,
        // success callback
        function() {
            console.log("recordAudio():Audio Success");
        },

        // error callback
        function(err) {
            console.log("recordAudio():Audio Error: "+ err.code);
        });

    // Record audio
    mediaRec.startRecord();

    // Pause Recording after 5 seconds
    setTimeout(function() {
        mediaRec.pauseRecord();
    }, 5000);

    // Resume Recording after 10 seconds
    setTimeout(function() {
        mediaRec.resumeRecord();
    }, 10000);
}
```

## media.seekTo

Sets the current position within an audio file.

    media.seekTo(milliseconds);

### Parameters

- __milliseconds__: The position to set the playback position within the audio, in milliseconds.


### Quick Example

```js
// Audio player
//
var my_media = new Media(src, onSuccess, onError);
    my_media.play();
// SeekTo to 10 seconds after 5 seconds
setTimeout(function() {
    my_media.seekTo(10000);
}, 5000);
```

## media.setVolume

Set the volume for an audio file.

    media.setVolume(volume);

### Parameters

- __volume__: The volume to set for playback.  The value must be within the range of 0.0 to 1.0.

### Supported Platforms

- Android
- iOS

### Quick Example

```js
// Play audio
//
function playAudio(url) {
    // Play the audio file at url
    var my_media = new Media(url,
        // success callback
        function() {
            console.log("playAudio():Audio Success");
        },
        // error callback
        function(err) {
            console.log("playAudio():Audio Error: "+err);
    });

    // Play audio
    my_media.play();

    // Mute volume after 2 seconds
    setTimeout(function() {
        my_media.setVolume('0.0');
    }, 2000);

    // Set volume to 1.0 after 5 seconds
    setTimeout(function() {
        my_media.setVolume('1.0');
    }, 5000);
}
```

## media.startRecord

Starts recording an audio file.

    media.startRecord();

### Supported Platforms

- Android
- iOS

### Quick Example

```js
// Record audio
//
function recordAudio() {
    var src = "myrecording.mp3";
    var mediaRec = new Media(src,
        // success callback
        function() {
            console.log("recordAudio():Audio Success");
        },

        // error callback
        function(err) {
            console.log("recordAudio():Audio Error: "+ err.code);
        });

    // Record audio
    mediaRec.startRecord();
}
```

### Android Quirks

- Android devices record audio in AAC ADTS file format. The specified file should end with a _.aac_ extension.
- The hardware volume controls are wired up to the media volume while any Media objects are alive. Once the last created Media object has `release()` called on it, the volume controls revert to their default behaviour. The controls are also reset on page navigation, as this releases all Media objects.

### iOS Quirks

- iOS only records to files of type _.wav_ and _.m4a_ and returns an error if the file name extension is not correct.

- If a full path is not provided, the recording is placed in the application's `documents/tmp` directory. This can be accessed via the `File` API using `LocalFileSystem.TEMPORARY`. Any subdirectory specified at record time must already exist.

- Files can be recorded and played back using the documents URI:

        var myMedia = new Media("documents://beer.mp3")

- Since iOS 10 it's mandatory to provide an usage description in the `info.plist` if trying to access privacy-sensitive data. When the system prompts the user to allow access, this usage description string will displayed as part of the permission dialog box, but if you didn't provide the usage description, the app will crash before showing the dialog. Also, Apple will reject apps that access private data but don't provide an usage description.

This plugins requires the following usage description:

* `NSMicrophoneUsageDescription` describes the reason that the app accesses the user's microphone. 

To add this entry into the `info.plist`, you can use the `edit-config` tag in the `config.xml` like this:

```
<edit-config target="NSMicrophoneUsageDescription" file="*-Info.plist" mode="merge">
    <string>need microphone access to record sounds</string>
</edit-config>
```

## media.stop

Stops playing an audio file.

    media.stop();

### Quick Example

```js
// Play audio
//
function playAudio(url) {
    // Play the audio file at url
    var my_media = new Media(url,
        // success callback
        function() {
            console.log("playAudio():Audio Success");
        },
        // error callback
        function(err) {
            console.log("playAudio():Audio Error: "+err);
        }
    );

    // Play audio
    my_media.play();

    // Pause after 10 seconds
    setTimeout(function() {
        my_media.stop();
    }, 10000);
}
```

## media.stopRecord

Stops recording an audio file.

    media.stopRecord();

### Supported Platforms

- Android
- iOS

### Quick Example

```js
// Record audio
//
function recordAudio() {
    var src = "myrecording.mp3";
    var mediaRec = new Media(src,
        // success callback
        function() {
            console.log("recordAudio():Audio Success");
        },

        // error callback
        function(err) {
            console.log("recordAudio():Audio Error: "+ err.code);
        }
    );

    // Record audio
    mediaRec.startRecord();

    // Stop recording after 10 seconds
    setTimeout(function() {
        mediaRec.stopRecord();
    }, 10000);
}
```

## media.setRate

Stops recording an audio file.

    media.setRate(rate);

### Supported Platforms

- iOS
- Android (API 23+)

### Parameters

- __rate__: The rate to set for playback.

### Quick Example

```js
// Audio player
//
var my_media = new Media(src, onSuccess, onError);
    my_media.play();

// Set playback rate to 2.0x after 10 seconds
setTimeout(function() {
    my_media.setRate(2.0);
}, 5000);
```

## MediaError

A `MediaError` object is returned to the `mediaError` callback
function when an error occurs.

### Properties

- __code__: One of the predefined error codes listed below.

- __message__: An error message describing the details of the error.

### Constants

- `MediaError.MEDIA_ERR_ABORTED`        = 1
- `MediaError.MEDIA_ERR_NETWORK`        = 2
- `MediaError.MEDIA_ERR_DECODE`         = 3
- `MediaError.MEDIA_ERR_NONE_SUPPORTED` = 4
