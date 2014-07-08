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

exports.defineAutoTests = function () {
    var failed = function (done, msg, error) {
        var info = typeof msg == 'undefined' ? 'Unexpected error callback' : msg;
        expect(true).toFailWithMessage(info + '\n' + JSON.stringify(error));
        done();
    };

    var succeed = function (done, msg) {
        var info = typeof msg == 'undefined' ? 'Unexpected success callback' : msg;
        expect(true).toFailWithMessage(info);
        done();
    };

    describe('Media', function () {

        beforeEach(function () {
            // Custom Matcher
            jasmine.Expectation.addMatchers({
                toFailWithMessage : function () {
                    return {
                        compare : function (error, message) {
                            var pass = false;
                            return {
                                pass : pass,
                                message : message
                            };
                        }
                    };
                }
            });
        });

        it("media.spec.1 should exist", function () {
            expect(Media).toBeDefined();
            expect(typeof Media).toBe("function");
        });

        it("media.spec.2 should have the following properties", function () {
            var media1 = new Media("dummy");
            expect(media1.id).toBeDefined();
            expect(media1.src).toBeDefined();
            expect(media1._duration).toBeDefined();
            expect(media1._position).toBeDefined();
            media1.release();
        });

        it("media.spec.3 should define constants for Media status", function () {
            expect(Media).toBeDefined();
            expect(Media.MEDIA_NONE).toBe(0);
            expect(Media.MEDIA_STARTING).toBe(1);
            expect(Media.MEDIA_RUNNING).toBe(2);
            expect(Media.MEDIA_PAUSED).toBe(3);
            expect(Media.MEDIA_STOPPED).toBe(4);
        });

        it("media.spec.4 should define constants for Media errors", function () {
            expect(MediaError).toBeDefined();
            expect(MediaError.MEDIA_ERR_NONE_ACTIVE).toBe(0);
            expect(MediaError.MEDIA_ERR_ABORTED).toBe(1);
            expect(MediaError.MEDIA_ERR_NETWORK).toBe(2);
            expect(MediaError.MEDIA_ERR_DECODE).toBe(3);
            expect(MediaError.MEDIA_ERR_NONE_SUPPORTED).toBe(4);
        });

        it("media.spec.5 should contain a play function", function () {
            var media1 = new Media();
            expect(media1.play).toBeDefined();
            expect(typeof media1.play).toBe('function');
            media1.release();
        });

        it("media.spec.6 should contain a stop function", function () {
            var media1 = new Media();
            expect(media1.stop).toBeDefined();
            expect(typeof media1.stop).toBe('function');
            media1.release();
        });

        it("media.spec.7 should contain a seekTo function", function () {
            var media1 = new Media();
            expect(media1.seekTo).toBeDefined();
            expect(typeof media1.seekTo).toBe('function');
            media1.release();
        });

        it("media.spec.8 should contain a pause function", function () {
            var media1 = new Media();
            expect(media1.pause).toBeDefined();
            expect(typeof media1.pause).toBe('function');
            media1.release();
        });

        it("media.spec.9 should contain a getDuration function", function () {
            var media1 = new Media();
            expect(media1.getDuration).toBeDefined();
            expect(typeof media1.getDuration).toBe('function');
            media1.release();
        });

        it("media.spec.10 should contain a getCurrentPosition function", function () {
            var media1 = new Media();
            expect(media1.getCurrentPosition).toBeDefined();
            expect(typeof media1.getCurrentPosition).toBe('function');
            media1.release();
        });

        it("media.spec.11 should contain a startRecord function", function () {
            var media1 = new Media();
            expect(media1.startRecord).toBeDefined();
            expect(typeof media1.startRecord).toBe('function');
            media1.release();
        });

        it("media.spec.12 should contain a stopRecord function", function () {
            var media1 = new Media();
            expect(media1.stopRecord).toBeDefined();
            expect(typeof media1.stopRecord).toBe('function');
            media1.release();
        });

        it("media.spec.13 should contain a release function", function () {
            var media1 = new Media();
            expect(media1.release).toBeDefined();
            expect(typeof media1.release).toBe('function');
            media1.release();
        });

        it("media.spec.14 should contain a setVolume function", function () {
            var media1 = new Media();
            expect(media1.setVolume).toBeDefined();
            expect(typeof media1.setVolume).toBe('function');
            media1.release();
        });

        it("media.spec.15 should return MediaError for bad filename", function (done) {
            var fileName = 'invalid.file.name';
            //Error callback it has an unexpected behavior under Windows Phone,
            //it enters to the error callback several times, instead of just one walk-through
            //JIRA issue related with all details: CB-7092
            //the conditional statement should be removed once the issue is fixed.

            //bb10 dialog pops up, preventing tests from running
            if (cordova.platformId === 'blackberry10' || cordova.platformId === 'windowsphone') {
                expect(true).toFailWithMessage('Platform does not supported this feature');
                done();
            } else {
                var badMedia = null;
                badMedia = new Media(fileName, succeed.bind(null, done, ' badMedia = new Media , Unexpected succees callback, it should not create Media object with invalid file name'), function (result) {
                        expect(result).toBeDefined();
                        expect(result.code).toBe(MediaError.MEDIA_ERR_ABORTED);
                        badMedia.release();
                        done();
                    });
                badMedia.play();
            }
        });

        it("media.spec.16 position should be set properly", function (done) {
            var mediaFile = 'http://cordova.apache.org/downloads/BlueZedEx.mp3',
            mediaState = Media.MEDIA_STOPPED,
            successCallback,
            flag = true,
            statusChange = function (statusCode) {
                if (statusCode == Media.MEDIA_RUNNING && flag) {
                    //flag variable used to ensure an extra security statement to ensure that the callback is processed only once,
                    //in case for some reason the statusChange callback is reached more than one time with the same status code.
                    //Some information about this kind of behavior it can be found at JIRA: CB-7099
                    flag = false;
                    setTimeout(function () {
                        media1.getCurrentPosition(function (position) {
                            expect(position).toBeGreaterThan(0.0);
                            media1.stop();
                            media1.release();
                            done();
                        }, failed.bind(null, done, 'media1.getCurrentPosition - Error getting media current position'));
                    }, 1000);
                }
            };
            media1 = new Media(mediaFile, successCallback, failed.bind(null, done, 'media1 = new Media - Error creating Media object. Media file: ' + mediaFile), statusChange);
            media1.play();
        });

        it("media.spec.17 duration should be set properly", function (done) {
            if (cordova.platformId === 'blackberry10') {
                expect(true).toFailWithMessage('Platform does not supported this feature');
                done();
            }
            var mediaFile = 'http://cordova.apache.org/downloads/BlueZedEx.mp3',
            mediaState = Media.MEDIA_STOPPED,
            successCallback,
            flag = true,
            statusChange = function (statusCode) {
                if (statusCode == Media.MEDIA_RUNNING && flag) {
                    //flag variable used to ensure an extra security statement to ensure that the callback is processed only once,
                    //in case for some reason the statusChange callback is reached more than one time with the same status code.
                    //Some information about this kind of behavior it can be found at JIRA: CB-7099.
                    flag = false;
                    setTimeout(function () {
                        expect(media1.getDuration()).toBeGreaterThan(0.0);
                        media1.stop();
                        media1.release();
                        done();
                    }, 1000);
                }
            },
            media1 = new Media(mediaFile, successCallback, failed.bind(null, done, 'media1 = new Media - Error creating Media object. Media file: ' + mediaFile), statusChange);
            media1.play();
        });
    });
};
