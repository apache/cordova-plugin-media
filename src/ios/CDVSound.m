/*
 Licensed to the Apache Software Foundation (ASF) under one
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
 */

#import "CDVSound.h"
#import "CDVFile.h"
#import <AVFoundation/AVFoundation.h>

#define DOCUMENTS_SCHEME_PREFIX @"documents://"
#define HTTP_SCHEME_PREFIX @"http://"
#define HTTPS_SCHEME_PREFIX @"https://"
#define CDVFILE_PREFIX @"cdvfile://"
#define RECORDING_WAV @"wav"

@implementation CDVSound

@synthesize soundCache, avSession, currMediaId, currDuration, meterTimer, isMeteringEnabled;


- (void)create:(CDVInvokedUrlCommand*)command {
    
    NSString* mediaId = [command argumentAtIndex:0];
    NSString* resourcePath = [command argumentAtIndex:1];
    BOOL meteringEnabled = [[command argumentAtIndex: 2] boolValue];
    
    self.currMediaId = mediaId;
    self.isMeteringEnabled = meteringEnabled;
    self.currDuration = -1;
    
    CDVAudioFile* audioFile = [self audioFileForResource:resourcePath withId:mediaId doValidation:NO forRecording:NO];
    
    NSLog(@"iOS: Creating AudioMRP Object with ID: %@, and isMetering: %s", mediaId, self.isMeteringEnabled ? "TRUE":"FALSE");
    
    if (audioFile == nil) {
        NSString* errorMessage = [NSString stringWithFormat:@"iOS: Failed to initialize AudioMRP file with path %@", resourcePath];
        NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMessage]];
        [self.commandDelegate evalJs:jsString];
    } else {
        NSURL* resourceUrl = [[NSURL alloc] initWithString:resourcePath];
        
        if (![resourceUrl isFileURL] && ![resourcePath hasPrefix:CDVFILE_PREFIX]) {
            
            NSLog(@"iOS: Creating AVPlayerItem and adding to player...");
            
            // First create an AVPlayerItem
            AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:resourceUrl];
            
            // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
            
            // Subscribe to the AVPlayerItem's PlaybackStalledNotification notification.
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemStalledPlaying:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
            
            // Pass the AVPlayerItem to a new player
            avPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        }
        
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)requestMicAccess:(CDVInvokedUrlCommand*)command {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        NSString* callbackId = command.callbackId;
        NSString* mediaId = [command argumentAtIndex:0];
        CDVPluginResult* result;
        NSString* jsString;
        
        if (granted) {
            NSLog(@"Permission granted");
            
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%s);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_MICROPHONE_ACCESS, (granted ? "true" : "false")];
            
        }
        else {
            NSLog(@"Permission denied");
            
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO];
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%s);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_MICROPHONE_ACCESS, (granted ? "true" : "false")];
            
        }
        
        [self.commandDelegate evalJs:jsString];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];

}

- (void)setVolume:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
#pragma unused(callbackId)
    
    NSString* mediaId = [command argumentAtIndex:0];
    NSNumber* volume = [command argumentAtIndex:1 withDefault:[NSNumber numberWithFloat:1.0]];

    if ([self soundCache] != nil) {
        CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
        if (audioFile != nil) {
            audioFile.volume = volume;
            if (audioFile.player) {
                audioFile.player.volume = [volume floatValue];
            }
            [[self soundCache] setObject:audioFile forKey:mediaId];
        }
    }

    // don't care for any callbacks
}

- (void)setRate:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
#pragma unused(callbackId)

    NSString* mediaId = [command argumentAtIndex:0];
    NSNumber* rate = [command argumentAtIndex:1 withDefault:[NSNumber numberWithFloat:1.0]];

    if ([self soundCache] != nil) {
        CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
        if (audioFile != nil) {
            audioFile.rate = rate;
            if (audioFile.player) {
                audioFile.player.enableRate = YES;
                audioFile.player.rate = [rate floatValue];
            }
            if (avPlayer.currentItem && avPlayer.currentItem.asset){
                float customRate = [rate floatValue];
                [avPlayer setRate:customRate];
            }
            
            [[self soundCache] setObject:audioFile forKey:mediaId];
        }
    }

    // don't care for any callbacks
}

- (void)startPlayingAudio:(CDVInvokedUrlCommand*)command {

    NSString* callbackId = command.callbackId;
#pragma unused(callbackId)

    NSString* mediaId = [command argumentAtIndex:0];
    NSString* resourcePath = [command argumentAtIndex:1];
    NSDictionary* options = [command argumentAtIndex:2 withDefault:nil];

    BOOL bError = NO;
    NSString* jsString = nil;

    CDVAudioFile* audioFile = [self audioFileForResource:resourcePath withId:mediaId doValidation:YES forRecording:NO];

    NSLog(@"iOS: startPlayingAudio: got audioFile (nil = %s)", (audioFile == nil ? "true":"false"));

    if ((audioFile != nil) && (audioFile.resourceURL != nil)) {
        
        if (audioFile.player == nil) {
            NSLog(@"iOS: startPlayingAudio: player is nil, calling prepareToPlay");
            bError = [self prepareToPlay:audioFile withId:mediaId];
        }
        
        if (!bError) {
            self.currMediaId = mediaId;
            
            // audioFile.player != nil  or player was successfully created
            // get the audioSession and set the category to allow Playing when device is locked or ring/silent switch engaged
            if ([self hasAudioSession]) {
                NSError* __autoreleasing err = nil;
                NSNumber* playAudioWhenScreenIsLocked = [options objectForKey:@"playAudioWhenScreenIsLocked"];
                BOOL bPlayAudioWhenScreenIsLocked = YES;
                if (playAudioWhenScreenIsLocked != nil) {
                    bPlayAudioWhenScreenIsLocked = [playAudioWhenScreenIsLocked boolValue];
                }

                NSString* sessionCategory = bPlayAudioWhenScreenIsLocked ? AVAudioSessionCategoryPlayback : AVAudioSessionCategorySoloAmbient;
                [self.avSession setCategory:sessionCategory error:&err];
                if (![self.avSession setActive:YES error:&err]) {
                    // other audio with higher priority that does not allow mixing could cause this to fail
                    NSLog(@"Unable to play audio: %@", [err localizedFailureReason]);
                    bError = YES;
                }
            }
            
            if (!bError) {
                NSLog(@"iOS: Playing audio sample '%@'", audioFile.resourcePath);
                
                if (avPlayer.currentItem && avPlayer.currentItem.asset) {

                    if (audioFile.rate != nil){
                        float customRate = [audioFile.rate floatValue];
                        NSLog(@"iOS: Setting AVPlayer custom rate");
                        [avPlayer setRate:customRate];
                    }
                    
                    [avPlayer play];
                    CMTime time = avPlayer.currentItem.asset.duration;
                    self.currDuration = (double)CMTimeGetSeconds(time);
                    NSLog(@"iOS: Playing stream with AVPlayer, custom rate and duration: %f", self.currDuration);
                    
                } else {

                    NSNumber* loopOption = [options objectForKey:@"numberOfLoops"];
                    NSInteger numberOfLoops = 0;
                    if (loopOption != nil) {
                        numberOfLoops = [loopOption intValue] - 1;
                    }
                    audioFile.player.numberOfLoops = numberOfLoops;
                    if (audioFile.player.isPlaying) {
                        [audioFile.player stop];
                        audioFile.player.currentTime = 0;
                    }
                    if (audioFile.volume != nil) {
                        audioFile.player.volume = [audioFile.volume floatValue];
                    }

                    audioFile.player.enableRate = YES;
                    if (audioFile.rate != nil) {
                        audioFile.player.rate = [audioFile.rate floatValue];
                    }

                    [audioFile.player play];
                    self.currDuration = audioFile.player.duration;
                    NSLog(@"iOS: Playing audio from audioFile.player with duration: %f", self.currDuration);
                }
                
                jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_START];

                [self.commandDelegate evalJs:jsString];
            }
            
            [self runAudioMetering: audioFile.player];
        }
        
        if (bError) {
            /*  I don't see a problem playing previously recorded audio so removing this section - BG
            NSError* error;
            // try loading it one more time, in case the file was recorded previously
            audioFile.player = [[ AVAudioPlayer alloc ] initWithContentsOfURL:audioFile.resourceURL error:&error];
            if (error != nil) {
                NSLog(@"Failed to initialize AVAudioPlayer: %@\n", error);
                audioFile.player = nil;
            } else {
                NSLog(@"Playing audio sample '%@'", audioFile.resourcePath);
                audioFile.player.numberOfLoops = numberOfLoops;
                [audioFile.player play];
            } */
            // error creating the session or player
            // jsString = [NSString stringWithFormat: @"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR,  MEDIA_ERR_NONE_SUPPORTED];
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_NONE_SUPPORTED message:nil]];
            [self.commandDelegate evalJs:jsString];
        }
    }
}

- (BOOL)prepareToPlay:(CDVAudioFile*)audioFile withId:(NSString*)mediaId {
    NSLog(@"iOS: prepareToPlay");
    BOOL bError = NO;
    NSError* __autoreleasing playerError = nil;

    // create the player
    NSURL* resourceURL = audioFile.resourceURL;

    if ([resourceURL isFileURL]) {
        NSLog(@"iOS: prepareToPlay: resourceURL is file, creating new CDVAudioPlayer");
        audioFile.player = [[CDVAudioPlayer alloc] initWithContentsOfURL:resourceURL error:&playerError];
        
    } else {
        NSLog(@"prepareToPlay: ORPHANED ELSE");
        /*      
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:resourceURL];
        NSString* userAgent = [self.commandDelegate userAgent];
        if (userAgent) {
            [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        }
        NSURLResponse* __autoreleasing response = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&playerError];
        if (playerError) {
            NSLog(@"Unable to download audio from: %@", [resourceURL absoluteString]);
        } else {
            // bug in AVAudioPlayer when playing downloaded data in NSData - we have to download the file and play from disk
            CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
            CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
            NSString* filePath = [NSString stringWithFormat:@"%@/%@", [NSTemporaryDirectory()stringByStandardizingPath], uuidString];
            CFRelease(uuidString);
            CFRelease(uuidRef);
            [data writeToFile:filePath atomically:YES];
            NSURL* fileURL = [NSURL fileURLWithPath:filePath];
            audioFile.player = [[CDVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&playerError];
        }
        */
    }

    if (playerError != nil) {
        NSLog(@"iOS: Failed to initialize AVAudioPlayer: %@\n", [playerError localizedDescription]);
        audioFile.player = nil;
        if (self.avSession) {
            [self.avSession setActive:NO error:nil];
        }
        bError = YES;
    } else {
        NSLog(@"iOS: prepareToPlay: Created media player");
        audioFile.player.mediaId = mediaId;
        audioFile.player.delegate = self;
        if (avPlayer == nil) {
            NSLog(@"iOS: prepareToPlay: avPlayer is nil... recursive call to preprareToPlay");
            // AVAudioPlayer:prepareToPlay takes no arguments and returns YES/NO on success/failure
            bError = ![audioFile.player prepareToPlay];
        }
    }
    return bError;
}

- (void)stopPlayingAudio:(CDVInvokedUrlCommand*)command {
    NSString* mediaId = [command argumentAtIndex:0];
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSLog(@"iOS: Stopped playing audioFile sample '%@'", audioFile.resourcePath);
        [audioFile.player stop];
        audioFile.player.currentTime = 0;
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_STOP];
    }
    
    if (avPlayer.currentItem && avPlayer.currentItem.asset) {
        NSLog(@"iOS: Stopped playing avPlayer audio sample '%@'", audioFile.resourcePath);
        [avPlayer seekToTime: kCMTimeZero
                     toleranceBefore: kCMTimeZero
                      toleranceAfter: kCMTimeZero
                   completionHandler: ^(BOOL finished){
                           if (finished) [avPlayer pause];
                       }];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_STOP];
    }
    // ignore if no media playing
    if (jsString) {
        [self stopAudioMetering];
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)pausePlayingAudio:(CDVInvokedUrlCommand*)command {
    NSString* mediaId = [command argumentAtIndex:0];
    NSString* jsString = nil;
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];

    if ((audioFile != nil) && ((audioFile.player != nil) || (avPlayer != nil))) {
        if (audioFile.player != nil) {
            NSLog(@"iOS: Paused playing audioFile audio sample '%@'", audioFile.resourcePath);
            [audioFile.player pause];
        } else if (avPlayer != nil) {
            NSLog(@"iOS: Paused playing avPlayer audio sample '%@'", audioFile.resourcePath);
            [avPlayer pause];
        }

        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_PAUSE];
    }
    // ignore if no media playing

    if (jsString) {
        [self stopAudioMetering];
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)seekToAudio:(CDVInvokedUrlCommand*)command {
    // args:
    // 0 = Media id
    // 1 = seek to location in milliseconds

    NSString* mediaId = [command argumentAtIndex:0];

    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    double position = [[command argumentAtIndex:1] doubleValue];
    double posInSeconds = position / 1000;
    NSString* jsString;

    if ((audioFile != nil) && (audioFile.player != nil)) {

        if (posInSeconds >= audioFile.player.duration) {
            // The seek is past the end of file.  Stop media and reset to beginning instead of seeking past the end.
            [audioFile.player stop];
            audioFile.player.currentTime = 0;
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);\n%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_POSITION, 0.0, @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_STOP];
            // NSLog(@"seekToEndJsString=%@",jsString);
        } else {
            audioFile.player.currentTime = posInSeconds;
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%f);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_POSITION, posInSeconds];
            // NSLog(@"seekJsString=%@",jsString);
        }

    } else if (avPlayer != nil) {
        int32_t timeScale = avPlayer.currentItem.asset.duration.timescale;
        CMTime timeToSeek = CMTimeMakeWithSeconds(posInSeconds, timeScale);
           
        BOOL isPlaying = (avPlayer.rate > 0 && !avPlayer.error);
        BOOL isReadyToSeek = (avPlayer.status == AVPlayerStatusReadyToPlay) && (avPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay);
        
        // CB-10535:
        // When dealing with remote files, we can get into a situation where we start playing before AVPlayer has had the time to buffer the file to be played.
        // To avoid the app crashing in such a situation, we only seek if both the player and the player item are ready to play. If not ready, we send an error back to JS land.
        if(isReadyToSeek) {
            [avPlayer seekToTime: timeToSeek
                 toleranceBefore: kCMTimeZero
                  toleranceAfter: kCMTimeZero
               completionHandler: ^(BOOL finished) {
                   if (isPlaying) [avPlayer play];
               }];
        } else {
            CDVMediaError errcode = MEDIA_ERR_ABORTED;
            NSString* errMsg = @"AVPlayerItem cannot service a seek request with a completion handler until its status is AVPlayerItemStatusReadyToPlay.";
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:errcode message:errMsg]];
        }
    }

    [self.commandDelegate evalJs:jsString];
}


- (void)release:(CDVInvokedUrlCommand*)command {
    NSString* mediaId = [command argumentAtIndex:0];

    if (mediaId != nil) {
        CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];

        if (audioFile != nil) {
            if (audioFile.player && [audioFile.player isPlaying]) {
                [audioFile.player stop];
            }
            if (audioFile.recorder && [audioFile.recorder isRecording]) {
                [audioFile.recorder stop];
            }
            if (avPlayer != nil) {
                [avPlayer pause];
                avPlayer = nil;
            }
            if (self.avSession) {
                [self.avSession setActive:NO error:nil];
                self.avSession = nil;
            }
            [[self soundCache] removeObjectForKey:mediaId];
            NSLog(@"iOS: AudioMRP with id %@ released", mediaId);
        }
    }
    
    if (self.meterTimer != nil) {
        [self.meterTimer invalidate];
        self.meterTimer = nil;
    }
}

- (void)getCurrentPositionAudio:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
    NSString* mediaId = [command argumentAtIndex:0];

#pragma unused(mediaId)
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    double position = -1;

    if ((audioFile != nil) && (audioFile.player != nil) && [audioFile.player isPlaying]) {
        position = round(audioFile.player.currentTime * 1000) / 1000;
    }
    if (avPlayer) {
       CMTime time = [avPlayer currentTime];
       position = CMTimeGetSeconds(time);
    }

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:position];
    
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_POSITION, position];
    [self.commandDelegate evalJs:jsString];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)getDurationAudio:(CDVInvokedUrlCommand*)command {
    NSLog(@"iOS: Requesting audio file duration");
    NSString* callbackId = command.callbackId;
    NSString* mediaId = [command argumentAtIndex:0];

#pragma unused(mediaId)
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
//    double duration = -1;
//
//    NSLog(@"iOS: audioFile (nil=%s) audioFile.player (nil=%s)", (audioFile = nil)?"true":"false", (audioFile.player = nil)?"true":"false");
//    if ((audioFile != nil) && (audioFile.player != nil)) {
//        duration = audioFile.player.duration;
//    }
//    
//    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:duration];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble: self.currDuration];
    
//    NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_DURATION, duration];
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_DURATION, self.currDuration];
    [self.commandDelegate evalJs:jsString];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)startRecordingAudio:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;

#pragma unused(callbackId)

    NSString* mediaId = [command argumentAtIndex:0];
    NSLog(@"iOS: StartRecordingAudio with ID: %@, and PATH: %@", mediaId, [command argumentAtIndex:1]);
    CDVAudioFile* audioFile = [self audioFileForResource:[command argumentAtIndex:1] withId:mediaId doValidation:YES forRecording:YES];
    __block NSString* jsString = nil;
    __block NSString* errorMsg = @"";

    if ((audioFile != nil) && (audioFile.resourceURL != nil)) {

        __weak CDVSound* weakSelf = self;

        // START: Recording block
        void (^startRecording)(void) = ^{
            NSError* __autoreleasing error = nil;
            
            if (audioFile.recorder != nil) {
                [audioFile.recorder stop];
                audioFile.recorder = nil;
            }
            // get the audioSession and set the category to allow recording when device is locked or ring/silent switch engaged
            if ([weakSelf hasAudioSession]) {
                if (![weakSelf.avSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
                    [weakSelf.avSession setCategory:AVAudioSessionCategoryRecord error:nil];
                }

                if (![weakSelf.avSession setActive:YES error:&error]) {
                    // other audio with higher priority that does not allow mixing could cause this to fail
                    errorMsg = [NSString stringWithFormat:@"Unable to record audio: %@", [error localizedFailureReason]];
                    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [weakSelf createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
                    [weakSelf.commandDelegate evalJs:jsString];
                    return;
                }
            }
            
            
            NSDictionary* recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:AVAudioQualityMedium], AVEncoderAudioQualityKey,
                                            [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                            [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                            [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                            nil];
            // create a new recorder for each start record
            audioFile.recorder = [[CDVAudioRecorder alloc] initWithURL:audioFile.resourceURL
                                                              settings:recordSettings
                                                                 error:&error];
            
            bool recordingSuccess = NO;
            if (error == nil) {
                audioFile.recorder.delegate = weakSelf;
                audioFile.recorder.mediaId = mediaId;
                recordingSuccess = [audioFile.recorder record];
                
                if (recordingSuccess) {
                    NSLog(@"iOS: Started recording audio sample '%@'", audioFile.resourcePath);
                    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_RECORD_START];
                    [weakSelf.commandDelegate evalJs:jsString];
                    
                    [self runAudioMetering: audioFile.recorder];
                }
            }
            
            if ((error != nil) || (recordingSuccess == NO)) {
                if (error != nil) {
                    errorMsg = [NSString stringWithFormat:@"iOS: Failed to initialize AVAudioRecorder: %@\n", [error localizedFailureReason]];
                } else {
                    errorMsg = @"iOS: Failed to start recording using AVAudioRecorder";
                }
                audioFile.recorder = nil;
                if (weakSelf.avSession) {
                    [weakSelf.avSession setActive:NO error:nil];
                }
                jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [weakSelf createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
                [weakSelf.commandDelegate evalJs:jsString];
            }
        };
        // END: Recording block
        
        SEL rrpSel = NSSelectorFromString(@"requestRecordPermission:");
        if ([self hasAudioSession] && [self.avSession respondsToSelector:rrpSel])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.avSession performSelector:rrpSel withObject:^(BOOL granted){
                if (granted) {
                    startRecording();
                } else {
                    NSString* msg = @"iOS: Error creating audio session, microphone permission denied.";
                    NSLog(@"%@", msg);
                    audioFile.recorder = nil;
                    if (weakSelf.avSession) {
                        [weakSelf.avSession setActive:NO error:nil];
                    }
                    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:msg]];
                    [weakSelf.commandDelegate evalJs:jsString];
                }
            }];
#pragma clang diagnostic pop
        } else {
            startRecording();
        }
        
    } else {
        // file did not validate
        NSString* errorMsg = [NSString stringWithFormat:@"iOS: Could not record audio at '%@'", audioFile.resourcePath];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)stopRecordingAudio:(CDVInvokedUrlCommand*)command {
    NSString* mediaId = [command argumentAtIndex:0];
    NSLog(@"iOS: StopRecordingAudio with ID: %@", mediaId);
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.recorder != nil)) {
        NSLog(@"iOS: Stopped recording audio sample '%@'", audioFile.resourcePath);
        [audioFile.recorder stop];
        
        [self stopAudioMetering];
        // no callback - that will happen in audioRecorderDidFinishRecording
    }
    // ignore if no media recording
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}


/** START: HELPER METHODS AND EVENT HANDLERS **/

// Creates or gets the cached audio file resource object
- (CDVAudioFile*)audioFileForResource:(NSString*)resourcePath withId:(NSString*)mediaId doValidation:(BOOL)bValidate forRecording:(BOOL)bRecord {
    NSLog(@"iOS: Creating audioFile: path: %@, id: %@", resourcePath, mediaId);
    
    BOOL bError = NO;
    CDVMediaError errcode = MEDIA_ERR_NONE_SUPPORTED;
    NSString* errMsg = @"";
    NSString* jsString = nil;
    CDVAudioFile* audioFile = nil;
    NSURL* resourceURL = nil;
    
    if ([self soundCache] == nil) {
        [self setSoundCache:[NSMutableDictionary dictionaryWithCapacity:1]];
    } else {
        audioFile = [[self soundCache] objectForKey:mediaId];
    }
    if (audioFile == nil) {
        // validate resourcePath and create
        if ((resourcePath == nil) || ![resourcePath isKindOfClass:[NSString class]] || [resourcePath isEqualToString:@""]) {
            bError = YES;
            errcode = MEDIA_ERR_ABORTED;
            errMsg = @"invalid media src argument";
        } else {
            audioFile = [[CDVAudioFile alloc] init];
            audioFile.resourcePath = resourcePath;
            audioFile.resourceURL = nil;  // validate resourceURL when actually play or record
            [[self soundCache] setObject:audioFile forKey:mediaId];
        }
    }
    if (bValidate && (audioFile.resourceURL == nil)) {
        if (bRecord) {
            resourceURL = [self urlForRecording:resourcePath];
        } else {
            resourceURL = [self urlForPlaying:resourcePath];
        }
        if (resourceURL == nil) {
            bError = YES;
            errcode = MEDIA_ERR_ABORTED;
            errMsg = [NSString stringWithFormat:@"Cannot use audio file from resource '%@'", resourcePath];
        } else {
            audioFile.resourceURL = resourceURL;
        }
    }
    
    if (bError) {
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:errcode message:errMsg]];
        [self.commandDelegate evalJs:jsString];
    }
    
    return audioFile;
}


// Maps a url for a resource path for recording
- (NSURL*)urlForRecording:(NSString*)resourcePath
{
    NSURL* resourceURL = nil;
    NSString* filePath = nil;
    NSString* docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    // first check for correct extension
    if ([[resourcePath pathExtension] caseInsensitiveCompare:RECORDING_WAV] != NSOrderedSame) {
        resourceURL = nil;
        NSLog(@"Resource for recording must have %@ extension", RECORDING_WAV);
    } else if ([resourcePath hasPrefix:DOCUMENTS_SCHEME_PREFIX]) {
        // try to find Documents:// resources
        filePath = [resourcePath stringByReplacingOccurrencesOfString:DOCUMENTS_SCHEME_PREFIX withString:[NSString stringWithFormat:@"%@/", docsPath]];
        NSLog(@"Will use resource '%@' from the documents folder with path = %@", resourcePath, filePath);
    } else if ([resourcePath hasPrefix:CDVFILE_PREFIX]) {
        CDVFile *filePlugin = [self.commandDelegate getCommandInstance:@"File"];
        CDVFilesystemURL *url = [CDVFilesystemURL fileSystemURLWithString:resourcePath];
        filePath = [filePlugin filesystemPathForURL:url];
        if (filePath == nil) {
            resourceURL = [NSURL URLWithString:resourcePath];
        }
    } else {
        // if resourcePath is not from FileSystem put in tmp dir, else attempt to use provided resource path
        NSString* tmpPath = [NSTemporaryDirectory()stringByStandardizingPath];
        BOOL isTmp = [resourcePath rangeOfString:tmpPath].location != NSNotFound;
        BOOL isDoc = [resourcePath rangeOfString:docsPath].location != NSNotFound;
        if (!isTmp && !isDoc) {
            // put in temp dir
            filePath = [NSString stringWithFormat:@"%@/%@", tmpPath, resourcePath];
        } else {
            filePath = resourcePath;
        }
    }
    
    if (filePath != nil) {
        // create resourceURL
        resourceURL = [NSURL fileURLWithPath:filePath];
    }
    return resourceURL;
}

// Maps a url for a resource path for playing
// "Naked" resource paths are assumed to be from the www folder as its base
- (NSURL*)urlForPlaying:(NSString*)resourcePath
{
    NSURL* resourceURL = nil;
    NSString* filePath = nil;
    
    // first try to find HTTP:// or Documents:// resources
    
    if ([resourcePath hasPrefix:HTTP_SCHEME_PREFIX] || [resourcePath hasPrefix:HTTPS_SCHEME_PREFIX]) {
        // if it is a http url, use it
        NSLog(@"Will use resource '%@' from the Internet.", resourcePath);
        resourceURL = [NSURL URLWithString:resourcePath];
    } else if ([resourcePath hasPrefix:DOCUMENTS_SCHEME_PREFIX]) {
        NSString* docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        filePath = [resourcePath stringByReplacingOccurrencesOfString:DOCUMENTS_SCHEME_PREFIX withString:[NSString stringWithFormat:@"%@/", docsPath]];
        NSLog(@"Will use resource '%@' from the documents folder with path = %@", resourcePath, filePath);
    } else if ([resourcePath hasPrefix:CDVFILE_PREFIX]) {
        CDVFile *filePlugin = [self.commandDelegate getCommandInstance:@"File"];
        CDVFilesystemURL *url = [CDVFilesystemURL fileSystemURLWithString:resourcePath];
        filePath = [filePlugin filesystemPathForURL:url];
        if (filePath == nil) {
            resourceURL = [NSURL URLWithString:resourcePath];
        }
    } else {
        // attempt to find file path in www directory or LocalFileSystem.TEMPORARY directory
        filePath = [self.commandDelegate pathForResource:resourcePath];
        if (filePath == nil) {
            // see if this exists in the documents/temp directory from a previous recording
            NSString* testPath = [NSString stringWithFormat:@"%@/%@", [NSTemporaryDirectory()stringByStandardizingPath], resourcePath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:testPath]) {
                // inefficient as existence will be checked again below but only way to determine if file exists from previous recording
                filePath = testPath;
                NSLog(@"Will attempt to use file resource from LocalFileSystem.TEMPORARY directory");
            } else {
                // attempt to use path provided
                filePath = resourcePath;
                NSLog(@"Will attempt to use file resource '%@'", filePath);
            }
        } else {
            NSLog(@"Found resource '%@' in the web folder.", filePath);
        }
    }
    // if the resourcePath resolved to a file path, check that file exists
    if (filePath != nil) {
        // create resourceURL
        resourceURL = [NSURL fileURLWithPath:filePath];
        // try to access file
        NSFileManager* fMgr = [NSFileManager defaultManager];
        if (![fMgr fileExistsAtPath:filePath]) {
            resourceURL = nil;
            NSLog(@"Unknown resource '%@'", resourcePath);
        }
    }
    
    return resourceURL;
}


// returns whether or not audioSession is available - creates it if necessary
- (BOOL)hasAudioSession
{
    BOOL bSession = YES;
    
    if (!self.avSession) {
        NSError* error = nil;
        
        self.avSession = [AVAudioSession sharedInstance];
        if (error) {
            // is not fatal if can't get AVAudioSession , just log the error
            NSLog(@"error creating audio session: %@", [[error userInfo] description]);
            self.avSession = nil;
            bSession = NO;
        }
    }
    return bSession;
}

// helper function to create a error object string
- (NSString*)createMediaErrorWithCode:(CDVMediaError)code message:(NSString*)message
{
    NSMutableDictionary* errorDict = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [errorDict setObject:[NSNumber numberWithUnsignedInteger:code] forKey:@"code"];
    [errorDict setObject:message ? message:@"" forKey:@"message"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:errorDict options:0 error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


// AVAudioRecorderDelegate protocol
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder*)recorder successfully:(BOOL)flag
{
    CDVAudioRecorder* aRecorder = (CDVAudioRecorder*)recorder;
    NSString* mediaId = aRecorder.mediaId;
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if (audioFile != nil) {
        NSLog(@"Finished recording audio sample '%@'", audioFile.resourcePath);
    }
    
    if (flag) {
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_RECORD_STOP];
    } else {
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_DECODE message:nil]];
    }
    
    if (self.avSession) {
        [self.avSession setActive:NO error:nil];
    }
    
    [self stopAudioMetering];
    [self.commandDelegate evalJs:jsString];
}

// AVAudioPlayerDelegate protocol
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    //commented as unused
    CDVAudioPlayer* aPlayer = (CDVAudioPlayer*)player;
    NSString* mediaId = aPlayer.mediaId;
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if (audioFile != nil) {
        NSLog(@"Finished playing audio sample '%@'", audioFile.resourcePath);
    }
    
    if (flag) {
        audioFile.player.currentTime = 0;
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_COMPLETE];
    } else {
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_DECODE message:nil]];
    }
    
    if (self.avSession) {
        [self.avSession setActive:NO error:nil];
    }
    
    [self stopAudioMetering];
    [self.commandDelegate evalJs:jsString];
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    NSString* mediaId = self.currMediaId;
    NSString* jsString = nil;
    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_STATE, MEDIA_PLAY_COMPLETE];

    if (self.avSession) {
        [self.avSession setActive:NO error:nil];
    }
    
    [self stopAudioMetering];
    [self.commandDelegate evalJs:jsString];
}

-(void)runAudioMetering: (id<CDVPlayer>) player {
    NSLog(@"iOS: runAudioMetering: isMeteringEnabled: %s", self.isMeteringEnabled ? "TRUE":"FALSE");
    if (self.isMeteringEnabled == YES) {
        player.meteringEnabled = YES;
        [self stopAudioMetering];
        self.meterTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                           target:self
                                                         selector:@selector(reportAudioLevel:)
                                                         userInfo:player
                                                          repeats:YES];
    }
}

-(void)stopAudioMetering {
    if (self.isMeteringEnabled) {
        [self.meterTimer invalidate];
        self.meterTimer = nil;
    }
}

-(NSNumber*)calcAudioLevel:(id<CDVPlayer>) player {
    [player updateMeters];
    NSNumber* level = [NSNumber numberWithFloat: [player averagePowerForChannel:0]];
    return level;
}

/*
 Sends audio level back up to Javascript layer
*/
-(void)reportAudioLevel:(NSTimer *) timer {
    // userInfo is ref to AVAudioRecorder or AVAudioPlayer
    NSNumber* audioLevel = [self calcAudioLevel: timer.userInfo];
    
    // Convert audioLevel from dB's logarithmic scale to a linear scale.
    // AVAudioPlayer docs say minimum audio level is -160 dB and maximum is 0 dB, but that
    // the dB value can go into positive values.
   
    // Convert from dB to percentage
    // Ten to the power of dB value divided by 20, multiplied by 100 to get percentage
    // Formula: 10^(dB/20) * 100
    // (NOTE: By changing divide by to 10, you'll get a 'truer' conversion, but that also ads
    // more variability -- a lower floor -- to the linear values.)
    double percentageAudioLevel = (pow(10, [audioLevel doubleValue]/20)) * 100;
    // Round up and remove decimal points
    percentageAudioLevel = ceil(percentageAudioLevel);
    // Limit upper value of audio to 100
    percentageAudioLevel = fmin(percentageAudioLevel, 100);
    int scaledAudioLevel = (int)percentageAudioLevel;
    
    //NSLog(@"iOS: Raw Audio Level   : %@", audioLevel);
    //NSLog(@"iOS: Scaled Audio Level: %@", [NSNumber numberWithInt: scaledAudioLevel]);
    
    NSString* mediaId = self.currMediaId;
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-plugin-audio-mrp.AudioMRP').onStatus", mediaId, MEDIA_AUDIO_LEVEL, [NSNumber numberWithInt: scaledAudioLevel]];
    [self.commandDelegate evalJs:jsString];
}

-(void)itemStalledPlaying:(NSNotification *) notification {
    // Will be called when playback stalls due to buffer empty
    NSLog(@"Stalled playback");
}

- (void)onMemoryWarning {
    [[self soundCache] removeAllObjects];
    [self setSoundCache:nil];
    [self setAvSession:nil];

    [super onMemoryWarning];
}

- (void)dealloc {
    [[self soundCache] removeAllObjects];
}

- (void)onReset {
    for (CDVAudioFile* audioFile in [[self soundCache] allValues]) {
        if (audioFile != nil) {
            if (audioFile.player != nil) {
                [audioFile.player stop];
                audioFile.player.currentTime = 0;
            }
            if (audioFile.recorder != nil) {
                [audioFile.recorder stop];
            }
        }
    }

    [[self soundCache] removeAllObjects];
}

@end

@implementation CDVAudioFile

@synthesize resourcePath;
@synthesize resourceURL;
@synthesize player, volume, rate;
@synthesize recorder;

@end
@implementation CDVAudioPlayer
@synthesize mediaId;

@end

@implementation CDVAudioRecorder
@synthesize mediaId;

@end