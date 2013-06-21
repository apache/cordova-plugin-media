---
license: Licensed to the Apache Software Foundation (ASF) under one
         or more contributor license agreements.  See the NOTICE file
         distributed with this work for additional information
         regarding copyright ownership.  The ASF licenses this file
         to you under the Apache License, Version 2.0 (the
         "License"); you may not use this file except in compliance
         with the License.  You may obtain a copy of the License at

           http://www.apache.org/licenses/LICENSE-2.0

         Unless required by applicable law or agreed to in writing,
         software distributed under the License is distributed on an
         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
         KIND, either express or implied.  See the License for the
         specific language governing permissions and limitations
         under the License.
---

media.startRecord
=================

Starts recording an audio file.

    media.startRecord();

Description
-----------

The `media.startRecord` method executes synchronously, starts a
recording for an audio file.

Supported Platforms
-------------------

- Android
- BlackBerry WebWorks (OS 5.0 and higher)
- iOS
- Windows Phone 7 and 8
- Windows 8

Quick Example
-------------

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

Full Example
------------

    <!DOCTYPE html>
    <html>
      <head>
        <title>Device Properties Example</title>

        <script type="text/javascript" charset="utf-8" src="cordova-x.x.x.js"></script>
        <script type="text/javascript" charset="utf-8">

        // Wait for device API libraries to load
        //
        document.addEventListener("deviceready", onDeviceReady, false);

        // Record audio
        //
        function recordAudio() {
            var src = "myrecording.amr";
            var mediaRec = new Media(src, onSuccess, onError);

            // Record audio
            mediaRec.startRecord();

            // Stop recording after 10 sec
            var recTime = 0;
            var recInterval = setInterval(function() {
                recTime = recTime + 1;
                setAudioPosition(recTime + " sec");
                if (recTime >= 10) {
                    clearInterval(recInterval);
                    mediaRec.stopRecord();
                }
            }, 1000);
        }

        // device APIs are available
        //
        function onDeviceReady() {
            recordAudio();
        }

        // onSuccess Callback
        //
        function onSuccess() {
            console.log("recordAudio():Audio Success");
        }

        // onError Callback
        //
        function onError(error) {
            alert('code: '    + error.code    + '\n' +
                  'message: ' + error.message + '\n');
        }

        // Set audio position
        //
        function setAudioPosition(position) {
            document.getElementById('audio_position').innerHTML = position;
        }

        </script>
      </head>
      <body>
        <p id="media">Recording audio...</p>
        <p id="audio_position"></p>
      </body>
    </html>

Android Quirks
----------

- Android devices record audio in Adaptive Multi-Rate format. The specified file should end with a _.amr_ extension.

BlackBerry WebWorks Quirks
----------

- BlackBerry devices record audio in Adaptive Multi-Rate format. The specified file must end with a _.amr_ extension.

iOS Quirks
----------

- iOS only records to files of type _.wav_ and returns an error if the file name extension is not correct.
- If a full path is not provided, the recording is placed in the application's _documents/tmp_ directory. This can be accessed via the `File` API using `LocalFileSystem.TEMPORARY`. Any subdirectory specified at record time must already exist.
- Files can be recorded and played back using the documents URI:

        var myMedia = new Media("documents://beer.mp3")

Tizen Quirks
----------

- Not supported on Tizen devices.
