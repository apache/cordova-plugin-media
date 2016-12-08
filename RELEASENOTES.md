<!--
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
-->
# Release Notes

### 2.4.1 (Dec 07, 2016)
* [CB-12034](https://issues.apache.org/jira/browse/CB-12034) (ios) Add mandatory iOS 10 privacy description
* [CB-11917](https://issues.apache.org/jira/browse/CB-11917) - Remove pull request template checklist item: "iCLA has been submitted…"
* [CB-11529](https://issues.apache.org/jira/browse/CB-11529) ios: Make available setting volume for player on ios device
* [CB-11832](https://issues.apache.org/jira/browse/CB-11832) Incremented plugin version.
* [CB-11832](https://issues.apache.org/jira/browse/CB-11832) Updated version and RELEASENOTES.md for release 2.4.0
* [CB-11795](https://issues.apache.org/jira/browse/CB-11795) Add 'protective' entry to cordovaDependencies
* [CB-11793](https://issues.apache.org/jira/browse/CB-11793) fixed android build issue with last commit
* [CB-11085](https://issues.apache.org/jira/browse/CB-11085) Fix error output using println to LOG.e
* [CB-11757](https://issues.apache.org/jira/browse/CB-11757) (ios) Error out if trying to stop playback while in a wrong state
* [CB-11380](https://issues.apache.org/jira/browse/CB-11380) (ios) Overloaded audioFileForResource method instead of modifying its signature
* Closing invalid pull request: close #104
* [CB-11380](https://issues.apache.org/jira/browse/CB-11380) (ios) Updated modified method signature in the .h file
* [CB-11380](https://issues.apache.org/jira/browse/CB-11380) (ios) Fixed an unexpected error callback when initializing Media with file that doesn't exist
* [CB-10849](https://issues.apache.org/jira/browse/CB-10849) (ios) Fixed a crash when playing soundfiles consecutively
* [CB-11754](https://issues.apache.org/jira/browse/CB-11754) (Android) Fixed the build error
* [CB-11086](https://issues.apache.org/jira/browse/CB-11086) (Android) Fixed a crash when setVolume() is called on unitialized audio This closes #93
* Plugin uses Android Log class and not Cordova LOG class
* [CB-11655](https://issues.apache.org/jira/browse/CB-11655) (Android) Enabled asynchronous error handling
* Update spec.24 expectations to be more descriptive
* [CB-11430](https://issues.apache.org/jira/browse/CB-11430) Report duration NaN value to JS properly
* [CB-11429](https://issues.apache.org/jira/browse/CB-11429) Update test stream URL
* [CB-11430](https://issues.apache.org/jira/browse/CB-11430) Skip audio playback tests on Saucelabs
* [CB-11458](https://issues.apache.org/jira/browse/CB-11458) - media.spec.25 'should be able to play an audio stream' fails on iOS platform
* Add badges for paramedic builds on Jenkins
* [CB-11313](https://issues.apache.org/jira/browse/CB-11313) Can't start media streaming on Android 6.0 (test case)
* [CB-11313](https://issues.apache.org/jira/browse/CB-11313) Can't start media streaming on Android 6.0
* Add pull request template.
* Readme: Add fenced code blocks with langauage hints
* Dummy commit to trigger CI run
* Dummy commit to trigger CI run
* [CB-11165](https://issues.apache.org/jira/browse/CB-11165) removed peer dependency
* [CB-10776](https://issues.apache.org/jira/browse/CB-10776) Add the ability to pause and resume an audio recording (Android)
* [CB-10776](https://issues.apache.org/jira/browse/CB-10776) Add the ability to pause and resume an audio recording (iOS)
* [CB-9487](https://issues.apache.org/jira/browse/CB-9487) Don't update position when getting amplitude
* [CB-10996](https://issues.apache.org/jira/browse/CB-10996) Adding front matter to README.md
* Dummy commit to trigger CI run
* [CB-11091](https://issues.apache.org/jira/browse/CB-11091) Incremented plugin version.
*  Updated version and RELEASENOTES.md for release 2.3.0
* Request audio focus when playing; Pause audio when audio focus is lost; resume playing when audio focus is granted again.
* Replace PermissionHelper.java with cordova-plugin-compat
* [CB-10783](https://issues.apache.org/jira/browse/CB-10783) Modify expected position to be in a proper range.This closes #89
* [CB-9487](https://issues.apache.org/jira/browse/CB-9487) Support getting amplitude for recording
* iOS audio should handle naked local file sources
* Dummy commit to trigger build on ci.cordova.io
* Dummy commit, to initiate a CI run on ci.cordova.io
* Dummy commit, to initiate a CI run on ci.cordova.io
* [CB-10720](https://issues.apache.org/jira/browse/CB-10720) Fixing README for display on Cordova website
* [CB-10636](https://issues.apache.org/jira/browse/CB-10636) Add JSHint for plugins
* [CB-10535](https://issues.apache.org/jira/browse/CB-10535) Fix CI crash caused by media plugin:    1- [iOS] Only perform 'seek' operation if both avPlayer and avPlayerItem are ready,         send error to client code if they aren't ready.    2- Deplay Media File Playing by a few seconds so that 'seek' operation happens only         after enough buffering has been done.
* [CB-10557](https://issues.apache.org/jira/browse/CB-10557) Incremented plugin version.
* [CB-10557](https://issues.apache.org/jira/browse/CB-10557) Updated version and RELEASENOTES.md for release 2.2.0
* [CB-10476](https://issues.apache.org/jira/browse/CB-10476) - fix problem where callbacks were not invoked on android due to messageChannel being overridden by callbackContext in every execut() call. This closes #78
* chore: edit package.json license to match SPDX id
* [CB-10455](https://issues.apache.org/jira/browse/CB-10455) android: Adding permission helper to remove cordova-android 5.0.0 constraint
* Fixed incorrectly written test
* rate control working
* Revert "rate fix"
* rate fix
* add rate support to avPlayer implementation on ios
* completion handler for stop();
* increment version
* Implement stop() for avplayer for compliance
* fix getDuration() returns 0
* updates to CDVSound.h for AVPlayer
* Streaming & Background threading on play
* [CB-10368](https://issues.apache.org/jira/browse/CB-10368) Incremented plugin version.
* [CB-10368](https://issues.apache.org/jira/browse/CB-10368) Updated version and RELEASENOTES.md for release 2.1.0
* Merged. Close #63. Close #73.
* Merged. Close #68. Close #74.
* Fixed example referencing non-existent variable
* [CB-9452](https://issues.apache.org/jira/browse/CB-9452) Treat RTSP streams as remote URLs
* Merged: Close #68, Close #74. #62 addresses the following : Closes #18, Closes #12.
* add JIRA issue tracker link
* fix [CB-9884](https://issues.apache.org/jira/browse/CB-9884) & [CB-9885](https://issues.apache.org/jira/browse/CB-9885)
* [CB-10100](https://issues.apache.org/jira/browse/CB-10100) updated file dependency to not grab new majors
* [CB-10035](https://issues.apache.org/jira/browse/CB-10035) Incremented plugin version.
* Fix block usage of self
* [CB-10035](https://issues.apache.org/jira/browse/CB-10035) linked issues in RELEASENOTES.md
* [CB-10035](https://issues.apache.org/jira/browse/CB-10035) Updated version and RELEASENOTES.md for release 2.0.0
* removed r prefix from tags
* [CB-10035](https://issues.apache.org/jira/browse/CB-10035) Updated RELEASENOTES to be newest to oldest
* Refactored after feedback
* Adding the media permissions code
* Adding engine tag
* Actually fixing the contribute link.
* Fixing contribute link.
* [CB-9619](https://issues.apache.org/jira/browse/CB-9619) Fixed tests waiting for precise position
* Cleanup pull requests. Close #23, Close #40, Close #55
* [CB-9606](https://issues.apache.org/jira/browse/CB-9606) Fixes arguments parsing in `seekAudio`
* [CB-9605](https://issues.apache.org/jira/browse/CB-9605) Fixes issue with playback resume after pause on WP8
* fix record and play NullPointerException
* [CB-9237](https://issues.apache.org/jira/browse/CB-9237) Add cdvfile:// support to media plugin on windows platform
* [CB-9238](https://issues.apache.org/jira/browse/CB-9238) Media plugin cannot record audio on windows
* fix failing test with empty media src string
* resolved conflicts, added manual test button to change audio playback rate.
* rate is enabled, otherwise media has to be stopped and started to change rate. Fixed error getting command args
* Fix for @synthesize rate mistype
* Added media.setRate auto test fix
* Added iOS platform media.setRate auto test
* Add iOS platform check in Media.prototype.setRate fix
* Add iOS platform check in Media.prototype.setRate
* Add Media.prototype.setRate method (only for iOS)
* remove spontaneous integration tests
* [CB-9192](https://issues.apache.org/jira/browse/CB-9192) Incremented plugin version.
* [CB-9202](https://issues.apache.org/jira/browse/CB-9202) updated repo url to github mirror in package.json
* [CB-9192](https://issues.apache.org/jira/browse/CB-9192) Updated version and RELEASENOTES.md for release 1.0.1
* [CB-9128](https://issues.apache.org/jira/browse/CB-9128) cordova-plugin-media documentation translation: cordova-plugin-media
* fix npm md issue
* [CB-9079](https://issues.apache.org/jira/browse/CB-9079) Increased timeout for playback tests
* [CB-8888](https://issues.apache.org/jira/browse/CB-8888) Makes media status reporting on windows more precise
* [CB-8793](https://issues.apache.org/jira/browse/CB-8793) Increased playback timeout in tests
* [CB-8858](https://issues.apache.org/jira/browse/CB-8858) Incremented plugin version.
* [CB-8858](https://issues.apache.org/jira/browse/CB-8858) Updated version in package.json for release 1.0.0
* Revert "CB-8858 Incremented plugin version."
* [CB-8858](https://issues.apache.org/jira/browse/CB-8858) Incremented plugin version.
* [CB-8858](https://issues.apache.org/jira/browse/CB-8858) Updated version and RELEASENOTES.md for release 1.0.0
* [CB-8793](https://issues.apache.org/jira/browse/CB-8793) Fixed tests to pass on wp8 and windows
* [CB-8746](https://issues.apache.org/jira/browse/CB-8746) bumped version of file dependency
* [CB-8746](https://issues.apache.org/jira/browse/CB-8746) gave plugin major version bump
* [CB-8779](https://issues.apache.org/jira/browse/CB-8779) Fixed media status reporting on wp8
* [CB-8747](https://issues.apache.org/jira/browse/CB-8747) added missing comma
* [CB-8747](https://issues.apache.org/jira/browse/CB-8747) updated dependency, added peer dependency
* [CB-8683](https://issues.apache.org/jira/browse/CB-8683) changed plugin-id to pacakge-name
* [CB-8653](https://issues.apache.org/jira/browse/CB-8653) properly updated translated docs to use new id
* [CB-8653](https://issues.apache.org/jira/browse/CB-8653) updated translated docs to use new id
* [CB-8541](https://issues.apache.org/jira/browse/CB-8541) Adds information about available recording formats on Windows
* Use TRAVIS_BUILD_DIR, install paramedic by npm
* [CB-8686](https://issues.apache.org/jira/browse/CB-8686) - remove musicLibrary capability
* [CB-7962](https://issues.apache.org/jira/browse/CB-7962) Adds browser platform support
* [CB-8653](https://issues.apache.org/jira/browse/CB-8653) Updated Readme
* [CB-8659](https://issues.apache.org/jira/browse/CB-8659) ios: 4.0.x Compatibility: Remove use of deprecated headers
* [CB-8572](https://issues.apache.org/jira/browse/CB-8572) Integrate TravisCI
* [CB-8438](https://issues.apache.org/jira/browse/CB-8438) cordova-plugin-media documentation translation: cordova-plugin-media
* [CB-8538](https://issues.apache.org/jira/browse/CB-8538) Added package.json file
* [CB-8428](https://issues.apache.org/jira/browse/CB-8428) Fix tests on Windows if no audio playback hardware is available
* [CB-8428](https://issues.apache.org/jira/browse/CB-8428) Fix multiple `done()` calls in media plugin test on devices where audio is not configured
* [CB-8426](https://issues.apache.org/jira/browse/CB-8426) Add Windows platform section to Media plugin
* [CB-8425](https://issues.apache.org/jira/browse/CB-8425) Media plugin .ctr: make src param required as per spec
* [CB-8429](https://issues.apache.org/jira/browse/CB-8429) Incremented plugin version.
* [CB-8429](https://issues.apache.org/jira/browse/CB-8429) Updated version and RELEASENOTES.md for release 0.2.16
* [CB-8351](https://issues.apache.org/jira/browse/CB-8351) ios: Stop using (newly) deprecated CDVJSON.h
* [CB-8351](https://issues.apache.org/jira/browse/CB-8351) Use argumentForIndex rather than NSArray extension
* [CB-8252](https://issues.apache.org/jira/browse/CB-8252) Fire audio events from native via message channel (close #41) - Add startup logic to initialize a message channel for native -> Javascript - Applies only to android and amazon-fireos (as this reuses the android native code) - Change audio status events to send via plugin message channel, instead using eval() (i.e. webView.sendJavascript())
* [CB-8152](https://issues.apache.org/jira/browse/CB-8152) - Remove deprecated methods in Media plugin (deprecated since 2.5)
* [CB-8110](https://issues.apache.org/jira/browse/CB-8110) Incremented plugin version.
* [CB-8110](https://issues.apache.org/jira/browse/CB-8110) Updated version and RELEASENOTES.md for release 0.2.15
* [CB-6153](https://issues.apache.org/jira/browse/CB-6153) android: Add docs for volume control behaviour, and fix controls not being reset on page navigation
* [CB-6153](https://issues.apache.org/jira/browse/CB-6153) android: Make volume buttons control music stream while any audio players are created
* [CB-7977](https://issues.apache.org/jira/browse/CB-7977) Mention deviceready in plugin docs
* [CB-7945](https://issues.apache.org/jira/browse/CB-7945) Made media.spec.15 and media.spec.16 auto tests green
* [CB-7700](https://issues.apache.org/jira/browse/CB-7700) cordova-plugin-media documentation translation: cordova-plugin-media
* [CB-7471](https://issues.apache.org/jira/browse/CB-7471) cordova-plugin-media documentation translation: cordova-plugin-media
*  Incremented plugin version.
*  Updated version and RELEASENOTES.md for release 0.2.14
* Amazon Specific changes: Added READ_PHONE_STATE permission same as done in Android
* make possible plays wav file
* [CB-7638](https://issues.apache.org/jira/browse/CB-7638) Get audio duration properly on windows
* [CB-7454](https://issues.apache.org/jira/browse/CB-7454) Adds support for m4a audio format for Windows
* [CB-7547](https://issues.apache.org/jira/browse/CB-7547) Fixes audio recording on windows platform
* [CB-7531](https://issues.apache.org/jira/browse/CB-7531) Fixes play() failure after release() call
* [CB-7571](https://issues.apache.org/jira/browse/CB-7571) Bump version of nested plugin to match parent plugin
* [CB-7571](https://issues.apache.org/jira/browse/CB-7571) Incremented plugin version.
* [CB-7571](https://issues.apache.org/jira/browse/CB-7571) Updated version and RELEASENOTES.md for release 0.2.13
* [CB-6963](https://issues.apache.org/jira/browse/CB-6963) renamed folder to tests + added nested plugin.xml
* [CB-7244](https://issues.apache.org/jira/browse/CB-7244) Incremented plugin version.
* [CB-7244](https://issues.apache.org/jira/browse/CB-7244) Updated version and RELEASENOTES.md for release 0.2.12
* CB-7249cordova-plugin-media documentation translation: cordova-plugin-media
* added documentation for manual tests
* [CB-6963](https://issues.apache.org/jira/browse/CB-6963) Port Media manual & automated tests
* [CB-6963.](https://issues.apache.org/jira/browse/CB-6963.) Port media tests to plugin-test-framework
* CB-6127lisa7cordova-plugin-consolecordova-plugin-media documentation translation: cordova-plugin-media
* ios: Make it easier to play media and record audio simultaneously
* code #s for MediaError
* [CB-6877](https://issues.apache.org/jira/browse/CB-6877) Incremented plugin version.
* [CB-6877](https://issues.apache.org/jira/browse/CB-6877) Updated version and RELEASENOTES.md for release 0.2.11
* [CB-6127](https://issues.apache.org/jira/browse/CB-6127) Spanish and French Translations added. Github close #13
* [CB-6807](https://issues.apache.org/jira/browse/CB-6807) Add license
* documentation translation: cordova-plugin-media
* Lisa testing pulling in plugins for plugin: cordova-plugin-media
* Lisa testing pulling in plugins for plugin: cordova-plugin-media
* [CB-6706](https://issues.apache.org/jira/browse/CB-6706) Relax dependency on file plugin
* [CB-6478](https://issues.apache.org/jira/browse/CB-6478) Fix exception when try to record audio file on windows 8
* [CB-6477](https://issues.apache.org/jira/browse/CB-6477) Add musicLibrary and microphone capabilities to windows 8 platform
* [CB-6491](https://issues.apache.org/jira/browse/CB-6491) add CONTRIBUTING.md
* [CB-6452](https://issues.apache.org/jira/browse/CB-6452) Incremented plugin version on dev branch.
* [CB-6452](https://issues.apache.org/jira/browse/CB-6452) Updated version and RELEASENOTES.md for release 0.2.10
* [CB-6465](https://issues.apache.org/jira/browse/CB-6465) Add license headers to Tizen code
* [CB-6460](https://issues.apache.org/jira/browse/CB-6460) Update license headers
* [CB-6422](https://issues.apache.org/jira/browse/CB-6422) [windows8] use cordova/exec/proxy
* [CB-6212](https://issues.apache.org/jira/browse/CB-6212) iOS: fix warnings compiled under arm64 64-bit
* [CB-6225](https://issues.apache.org/jira/browse/CB-6225) - Media plugin does not specify a dependency on File plugin 1.0.1
* Add NOTICE file
* [CB-6114](https://issues.apache.org/jira/browse/CB-6114) Incremented plugin version on dev branch.
* Add NOTICE file
* [CB-6114](https://issues.apache.org/jira/browse/CB-6114) Updated version and RELEASENOTES.md for release 0.2.9
* [CB-6051](https://issues.apache.org/jira/browse/CB-6051) Android: Allow media plugin to handle invalid file locations
* [CB-6051](https://issues.apache.org/jira/browse/CB-6051) Update media plugin to work with new cdvfile:// urls
* [CB-5980](https://issues.apache.org/jira/browse/CB-5980) Incremented plugin version on dev branch.
* [CB-5980](https://issues.apache.org/jira/browse/CB-5980) Updated version and RELEASENOTES.md for release 0.2.8
* [CB-5748](https://issues.apache.org/jira/browse/CB-5748) Make sure that Media.onStatus is called when recording is started.
* Lisa testing pulling in plugins for plugin: cordova-plugin-media
* Lisa testing pulling in plugins for plugin: cordova-plugin-media
* [CB-5980](https://issues.apache.org/jira/browse/CB-5980) Updated version and RELEASENOTES.md for release 0.2.8
* Add preliminary support for Tizen.
* [CB-4755](https://issues.apache.org/jira/browse/CB-4755) Fix crash in Media.setVolume on iOS
* Delete stale test/ directory
* [CB-5719](https://issues.apache.org/jira/browse/CB-5719) Incremented plugin version on dev branch.
* [CB-5719](https://issues.apache.org/jira/browse/CB-5719) Updated version and RELEASENOTES.md for release 0.2.7
* [CB-5658](https://issues.apache.org/jira/browse/CB-5658) Update license comment formatting of doc/index.md
* [CB-5658](https://issues.apache.org/jira/browse/CB-5658) Add doc.index.md for Media plugin
* [CB-5658](https://issues.apache.org/jira/browse/CB-5658) Delete stale snapshot of plugin docs
* Adding READ_PHONE_STATE to the plugin permissions
* [CB-5565](https://issues.apache.org/jira/browse/CB-5565) Incremented plugin version on dev branch.
* [CB-5565](https://issues.apache.org/jira/browse/CB-5565) Updated version and RELEASENOTES.md for release 0.2.6
* [ubuntu] specify policy_group
* add ubuntu platform
* Added amazon-fireos platform. Change to use amazon-fireos as a platform if the user agent string contains 'cordova-amazon-fireos'
* [CB-5188](https://issues.apache.org/jira/browse/CB-5188)
* [CB-5188](https://issues.apache.org/jira/browse/CB-5188) Updated version and RELEASENOTES.md for release 0.2.5
* [CB-5128](https://issues.apache.org/jira/browse/CB-5128) add repo + issue tag to plugin.xml for media plugin
* [CB-5010](https://issues.apache.org/jira/browse/CB-5010) Incremented plugin version on dev branch.
* [CB-5010](https://issues.apache.org/jira/browse/CB-5010) Updated version and RELEASENOTES.md for release 0.2.4
* [CB-4928](https://issues.apache.org/jira/browse/CB-4928) plugin-media doesn't load on windows8
* [CB-4915](https://issues.apache.org/jira/browse/CB-4915) Incremented plugin version on dev branch.
* [CB-4915](https://issues.apache.org/jira/browse/CB-4915) Updated version and RELEASENOTES.md for release 0.2.3
* [CB-4889](https://issues.apache.org/jira/browse/CB-4889) bumping&resetting version
* [windows8] commandProxy was moved
* [CB-4889](https://issues.apache.org/jira/browse/CB-4889) renaming references
* [CB-4889](https://issues.apache.org/jira/browse/CB-4889) renaming org.apache.cordova.core.media to org.apache.cordova.media
* [CB-4847](https://issues.apache.org/jira/browse/CB-4847) iOS 7 microphone access requires user permission - if denied, CDVCapture, CDVSound does not handle it properly
* Rename CHANGELOG.md -> RELEASENOTES.md
* [CB-4799](https://issues.apache.org/jira/browse/CB-4799) Fix incorrect JS references within native code on Android & iOS
* Fix compiler/lint warnings
* Rename plugin id from AudioHandler -> media
* [CB-4763](https://issues.apache.org/jira/browse/CB-4763) Remove reference to cordova-android's FileHelper.
* [CB-4752](https://issues.apache.org/jira/browse/CB-4752) Incremented plugin version on dev branch.
* Revert "[CB-4847] iOS 7 microphone access requires user permission - if denied, CDVCapture, CDVSound does not handle it properly"
* [CB-4847](https://issues.apache.org/jira/browse/CB-4847) iOS 7 microphone access requires user permission - if denied, CDVCapture, CDVSound does not handle it properly
* [CB-4752](https://issues.apache.org/jira/browse/CB-4752) Updated version and changelog
* [CB-4432](https://issues.apache.org/jira/browse/CB-4432) copyright notice change
* [CB-4432](https://issues.apache.org/jira/browse/CB-4432) copyright notice change
* [CB-4595](https://issues.apache.org/jira/browse/CB-4595) updated version
* [CB-4417](https://issues.apache.org/jira/browse/CB-4417) Move cordova-plugin-media to its own Java package.
* updated readme, name tag and namespace
* [plugin.xml] standardizing license + meta
* [license] adding apache license file
* [wp][CB-3783] All api calls maintain the callbackID to prevent issues with overlapping calls.
* [Windows8][CB-4448] Added windows 8 support
* updating plugin.xml with registry data

### 2.4.0 (Sep 08, 2016)
* [CB-11795](https://issues.apache.org/jira/browse/CB-11795) Add 'protective' entry to cordovaDependencies
* [CB-11793](https://issues.apache.org/jira/browse/CB-11793) fixed **android** build issue with last commit
* [CB-11085](https://issues.apache.org/jira/browse/CB-11085) Fix error output using `println` to `LOG.e`
* [CB-11757](https://issues.apache.org/jira/browse/CB-11757) (**ios**) Error out if trying to stop playback while in a wrong state
* [CB-11380](https://issues.apache.org/jira/browse/CB-11380) (**ios**) Overloaded `audioFileForResource` method instead of modifying its signature
* [CB-11380](https://issues.apache.org/jira/browse/CB-11380) (**ios**) Updated modified method signature in the .h file
* [CB-11380](https://issues.apache.org/jira/browse/CB-11380) (**ios**) Fixed an unexpected error callback when initializing Media with file that doesn't exist
* [CB-10849](https://issues.apache.org/jira/browse/CB-10849) (ios) Fixed a crash when playing soundfiles consecutively
* [CB-11754](https://issues.apache.org/jira/browse/CB-11754) (**Android**) Fixed the build error
* [CB-11086](https://issues.apache.org/jira/browse/CB-11086) (**Android**) Fixed a crash when `setVolume()` is called on unitialized audio This closes #93
* Plugin uses `Android Log class` and not `Cordova LOG class`
* [CB-11655](https://issues.apache.org/jira/browse/CB-11655) (**Android**) Enabled asynchronous error handling
* [CB-11430](https://issues.apache.org/jira/browse/CB-11430) Report duration NaN value to JS properly
* [CB-11429](https://issues.apache.org/jira/browse/CB-11429) Update test stream URL
* [CB-11430](https://issues.apache.org/jira/browse/CB-11430) Skip audio playback tests on Saucelabs
* [CB-11458](https://issues.apache.org/jira/browse/CB-11458) - `media.spec.25` 'should be able to play an audio stream' fails on **iOS** platform
* Add badges for paramedic builds on Jenkins
* [CB-11313](https://issues.apache.org/jira/browse/CB-11313) Can't start media streaming on **Android 6.0**
* Add pull request template.
* Readme: Add fenced code blocks with langauage hints
* [CB-11165](https://issues.apache.org/jira/browse/CB-11165) removed peer dependency
* [CB-10776](https://issues.apache.org/jira/browse/CB-10776) Add the ability to pause and resume an audio recording (**Android**)
* [CB-10776](https://issues.apache.org/jira/browse/CB-10776) Add the ability to pause and resume an audio recording (**iOS**)
* [CB-9487](https://issues.apache.org/jira/browse/CB-9487) Don't update position when getting amplitude
* [CB-10996](https://issues.apache.org/jira/browse/CB-10996) Adding front matter to README.md

### 2.3.0 (Apr 15, 2016)
* Request audio focus when playing; Pause audio when audio focus is lost; resume playing when audio focus is granted again.
* Replace `PermissionHelper.java` with `cordova-plugin-compat`
* [CB-10783](https://issues.apache.org/jira/browse/CB-10783) Modify expected position to be in a proper range.
* [CB-9487](https://issues.apache.org/jira/browse/CB-9487) Support getting amplitude for recording
* **iOS** audio should handle naked local file sources
* [CB-10720](https://issues.apache.org/jira/browse/CB-10720) Fixing README for display on Cordova website
* [CB-10636](https://issues.apache.org/jira/browse/CB-10636) Add `JSHint` for plugins
* [CB-10535](https://issues.apache.org/jira/browse/CB-10535) Fix CI crash caused by media plugin

### 2.2.0 (Feb 09, 2016)
* [CB-10476](https://issues.apache.org/jira/browse/CB-10476) Fix problem where callbacks were not invoked on android due to messageChannel being overridden by callbackContext in every execute() call
* Edit package.json license to match SPDX id
* [CB-10455](https://issues.apache.org/jira/browse/CB-10455) android: Adding permission helper to remove cordova-android 5.0.0 constraint
* [CB-57](https://issues.apache.org/jira/browse/CB-57) Updated to use avplayer when url starts with http:// or https:// for full streaming support
* [CB-8222](https://issues.apache.org/jira/browse/CB-8222) Background thread on play to prevent locking during initial load of media

### 2.1.0 (Jan 15, 2016)
* Fixed example referencing non-existent variable
* [CB-9452](https://issues.apache.org/jira/browse/CB-9452) Treat `RTSP streams` as `remote URLs`
* add JIRA issue tracker link
* fix [CB-9884](https://issues.apache.org/jira/browse/CB-9884) & [CB-9885](https://issues.apache.org/jira/browse/CB-9885)
* [CB-10100](https://issues.apache.org/jira/browse/CB-10100) updated file dependency to not grab new majors
* Fix block usage of self

### 2.0.0 (Nov 18, 2015)
* [CB-10035](https://issues.apache.org/jira/browse/CB-10035) Updated `RELEASENOTES` to be newest to oldest
* Media now supports new permissions for **Android 6.0** aka **Marshmallow**
* Fixing contribute link.
* [CB-9619](https://issues.apache.org/jira/browse/CB-9619) Fixed tests waiting for precise position
* [CB-9606](https://issues.apache.org/jira/browse/CB-9606) Fixes arguments parsing in `seekAudio`
* [CB-9605](https://issues.apache.org/jira/browse/CB-9605) Fixes issue with playback resume after pause on **WP8**
* fix record and play `NullPointerException`
* [CB-9237](https://issues.apache.org/jira/browse/CB-9237) Add `cdvfile://` support to media plugin on **Windows** platform
* [CB-9238](https://issues.apache.org/jira/browse/CB-9238) Media plugin cannot record audio on **Windows**
* Added **iOS** platform `media.setRate` auto test
* Add **iOS** platform check in `Media.prototype.setRate`
* Add `Media.prototype.setRate` method (only for **iOS**)

### 1.0.1 (Jun 17, 2015)
* [CB-9128](https://issues.apache.org/jira/browse/CB-9128) cordova-plugin-media documentation translation: cordova-plugin-media
* fix npm md issue
* [CB-9079](https://issues.apache.org/jira/browse/CB-9079) Increased timeout for playback tests
* [CB-8888](https://issues.apache.org/jira/browse/CB-8888) Makes media status reporting on windows more precise
* [CB-8793](https://issues.apache.org/jira/browse/CB-8793) Increased playback timeout in tests

### 1.0.0 (Apr 15, 2015)
* [CB-8793](https://issues.apache.org/jira/browse/CB-8793) Fixed tests to pass on wp8 and windows
* [CB-8746](https://issues.apache.org/jira/browse/CB-8746) bumped version of file dependency
* [CB-8746](https://issues.apache.org/jira/browse/CB-8746) gave plugin major version bump
* [CB-8779](https://issues.apache.org/jira/browse/CB-8779) Fixed media status reporting on wp8
* [CB-8747](https://issues.apache.org/jira/browse/CB-8747) added missing comma
* [CB-8747](https://issues.apache.org/jira/browse/CB-8747) updated dependency, added peer dependency
* [CB-8683](https://issues.apache.org/jira/browse/CB-8683) changed plugin-id to pacakge-name
* [CB-8653](https://issues.apache.org/jira/browse/CB-8653) properly updated translated docs to use new id
* [CB-8653](https://issues.apache.org/jira/browse/CB-8653) updated translated docs to use new id
* [CB-8541](https://issues.apache.org/jira/browse/CB-8541) Adds information about available recording formats on Windows
* Use TRAVIS_BUILD_DIR, install paramedic by npm
* [CB-8686](https://issues.apache.org/jira/browse/CB-8686) - remove musicLibrary capability
* [CB-7962](https://issues.apache.org/jira/browse/CB-7962) Adds browser platform support
* [CB-8653](https://issues.apache.org/jira/browse/CB-8653) Updated Readme
* [CB-8659](https://issues.apache.org/jira/browse/CB-8659): ios: 4.0.x Compatibility: Remove use of deprecated headers
* [CB-8572](https://issues.apache.org/jira/browse/CB-8572) Integrate TravisCI
* [CB-8438](https://issues.apache.org/jira/browse/CB-8438) cordova-plugin-media documentation translation: cordova-plugin-media
* [CB-8538](https://issues.apache.org/jira/browse/CB-8538) Added package.json file
* [CB-8428](https://issues.apache.org/jira/browse/CB-8428) Fix tests on Windows if no audio playback hardware is available
* [CB-8428](https://issues.apache.org/jira/browse/CB-8428) Fix multiple `done()` calls in media plugin test on devices where audio is not configured
* [CB-8426](https://issues.apache.org/jira/browse/CB-8426) Add Windows platform section to Media plugin
* [CB-8425](https://issues.apache.org/jira/browse/CB-8425) Media plugin .ctr: make src param required as per spec

### 0.2.16 (Feb 04, 2015)
* [CB-8351](https://issues.apache.org/jira/browse/CB-8351) ios: Stop using (newly) deprecated CDVJSON.h
* [CB-8351](https://issues.apache.org/jira/browse/CB-8351) ios: Use argumentForIndex rather than NSArray extension
* [CB-8252](https://issues.apache.org/jira/browse/CB-8252) android: Fire audio events from native via message channel
* [CB-8152](https://issues.apache.org/jira/browse/CB-8152) ios: Remove deprecated methods in Media plugin (deprecated since 2.5)

### 0.2.15 (Dec 02, 2014)
* [CB-6153](https://issues.apache.org/jira/browse/CB-6153) **Android**: Add docs for volume control behaviour, and fix controls not being reset on page navigation
* [CB-6153](https://issues.apache.org/jira/browse/CB-6153) **Android**: Make volume buttons control music stream while any audio players are created
* [CB-7977](https://issues.apache.org/jira/browse/CB-7977) Mention `deviceready` in plugin docs
* [CB-7945](https://issues.apache.org/jira/browse/CB-7945) Made media.spec.15 and media.spec.16 auto tests green
* [CB-7700](https://issues.apache.org/jira/browse/CB-7700) cordova-plugin-media documentation translation: cordova-plugin-media

### 0.2.14 (Oct 03, 2014)
* Amazon Specific changes: Added READ_PHONE_STATE permission same as done in Android
* make possible plays wav file
* [CB-7638](https://issues.apache.org/jira/browse/CB-7638) Get audio duration properly on windows
* [CB-7454](https://issues.apache.org/jira/browse/CB-7454) Adds support for m4a audio format for Windows
* [CB-7547](https://issues.apache.org/jira/browse/CB-7547) Fixes audio recording on windows platform
* [CB-7531](https://issues.apache.org/jira/browse/CB-7531) Fixes play() failure after release() call

### 0.2.13 (Sep 17, 2014)
* [CB-6963](https://issues.apache.org/jira/browse/CB-6963) renamed folder to tests + added nested plugin.xml
* added documentation for manual tests
* [CB-6963](https://issues.apache.org/jira/browse/CB-6963) Port Media manual & automated tests
* [CB-6963](https://issues.apache.org/jira/browse/CB-6963) Port media tests to plugin-test-framework
 
### 0.2.12 (Aug 06, 2014)
* [CB-6127](https://issues.apache.org/jira/browse/CB-6127) Updated translations for docs
* ios: Make it easier to play media and record audio simultaneously
* code #s for MediaError

### 0.2.11 (Jun 05, 2014)
* [CB-6127](https://issues.apache.org/jira/browse/CB-6127) Spanish and French Translations added. Github close #13
* [CB-6807](https://issues.apache.org/jira/browse/CB-6807) Add license
* [CB-6706](https://issues.apache.org/jira/browse/CB-6706): Relax dependency on file plugin
* [CB-6478](https://issues.apache.org/jira/browse/CB-6478): Fix exception when try to record audio file on windows 8
* [CB-6477](https://issues.apache.org/jira/browse/CB-6477): Add musicLibrary and microphone capabilities to windows 8 platform
* [CB-6491](https://issues.apache.org/jira/browse/CB-6491) add CONTRIBUTING.md

### 0.2.10 (Apr 17, 2014)
* [CB-6422](https://issues.apache.org/jira/browse/CB-6422): [windows8] use cordova/exec/proxy
* [CB-6212](https://issues.apache.org/jira/browse/CB-6212): [iOS] fix warnings compiled under arm64 64-bit
* [CB-6225](https://issues.apache.org/jira/browse/CB-6225): Specify plugin dependency on File plugin 1.0.1
* [CB-6460](https://issues.apache.org/jira/browse/CB-6460): Update license headers
* [CB-6465](https://issues.apache.org/jira/browse/CB-6465): Add license headers to Tizen code
* Add NOTICE file

### 0.2.9 (Feb 26, 2014)
* [CB-6051](https://issues.apache.org/jira/browse/CB-6051) Update media plugin to work with new cdvfile:// urls
* [CB-5748](https://issues.apache.org/jira/browse/CB-5748) Make sure that Media.onStatus is called when recording is started.

### 0.2.8 (Feb 05, 2014)
* Add preliminary support for Tizen.
* [CB-4755](https://issues.apache.org/jira/browse/CB-4755) Fix crash in Media.setVolume on iOS

### 0.2.7 (Jan 02, 2014)
* [CB-5658](https://issues.apache.org/jira/browse/CB-5658) Add doc/index.md for Media plugin
* Adding READ_PHONE_STATE to the plugin permissions

### 0.2.6 (Dec 4, 2013)
* [ubuntu] specify policy_group
* add ubuntu platform
* Added amazon-fireos platform. Change to use amazon-fireos as a platform if the user agent string contains 'cordova-amazon-fireos'

### 0.2.5 (Oct 28, 2013)
* [CB-5128](https://issues.apache.org/jira/browse/CB-5128): add repo + issue tag to plugin.xml for media plugin
* [CB-5010](https://issues.apache.org/jira/browse/CB-5010) Incremented plugin version on dev branch.

### 0.2.4 (Oct 9, 2013)
* [CB-4928](https://issues.apache.org/jira/browse/CB-4928) plugin-media doesn't load on windows8
* [CB-4915](https://issues.apache.org/jira/browse/CB-4915) Incremented plugin version on dev branch.

### 0.2.3 (Sept 25, 2013)
* [CB-4889](https://issues.apache.org/jira/browse/CB-4889) bumping&resetting version
* [windows8] commandProxy was moved
* [CB-4889](https://issues.apache.org/jira/browse/CB-4889) renaming references
* [CB-4889](https://issues.apache.org/jira/browse/CB-4889) renaming org.apache.cordova.core.media to org.apache.cordova.media
* [CB-4847](https://issues.apache.org/jira/browse/CB-4847) iOS 7 microphone access requires user permission - if denied, CDVCapture, CDVSound does not handle it properly
* Rename CHANGELOG.md -> RELEASENOTES.md
* [CB-4799](https://issues.apache.org/jira/browse/CB-4799) Fix incorrect JS references within native code on Android & iOS
* Fix compiler/lint warnings
* Rename plugin id from AudioHandler -> media
* [CB-4763](https://issues.apache.org/jira/browse/CB-4763) Remove reference to cordova-android's FileHelper.
* [CB-4752](https://issues.apache.org/jira/browse/CB-4752) Incremented plugin version on dev branch.

### 0.2.1 (Sept 5, 2013)
* [CB-4432](https://issues.apache.org/jira/browse/CB-4432) copyright notice change
