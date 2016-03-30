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

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

#import <Cordova/CDVPlugin.h>

enum CDVMediaError {
    MEDIA_ERR_ABORTED = 1,
    MEDIA_ERR_NETWORK = 2,
    MEDIA_ERR_DECODE = 3,
    MEDIA_ERR_NONE_SUPPORTED = 4
};
typedef NSUInteger CDVMediaError;

enum CDVMediaStates {
    MEDIA_NONE = 0,
    MEDIA_RECORD_START = 1,
    MEDIA_RECORD_STOP = 2,
    MEDIA_PLAY_START = 3,
    MEDIA_PLAY_PAUSE = 4,
    MEDIA_PLAY_STOP = 5,
    MEDIA_PLAY_COMPLETE = 6
};
typedef NSUInteger CDVMediaStates;

enum CDVMediaMsg {
    MEDIA_STATE = 1,
    MEDIA_DURATION = 2,
    MEDIA_POSITION = 3,
    MEDIA_AUDIO_LEVEL = 4,
    MEDIA_ERROR = 9
};
typedef NSUInteger CDVMediaMsg;

@protocol CDVPlayer
- (void) updateMeters;
- (float) averagePowerForChannel: (NSUInteger) channelNumber;
@end

@interface CDVAudioPlayer : AVAudioPlayer <CDVPlayer> {
    NSString* mediaId;
}
@property (nonatomic, copy) NSString* mediaId;
@end

@interface CDVAudioRecorder : AVAudioRecorder <CDVPlayer> {
    NSString* mediaId;
}
@property (nonatomic, copy) NSString* mediaId;
@end

@interface CDVAudioFile : NSObject {
    NSString* resourcePath;
    NSURL* resourceURL;
    CDVAudioPlayer* player;
    CDVAudioRecorder* recorder;
    NSNumber* volume;
    NSNumber* rate;
}

@property (nonatomic, strong) NSString* resourcePath;
@property (nonatomic, strong) NSURL* resourceURL;
@property (nonatomic, strong) CDVAudioPlayer* player;
@property (nonatomic, strong) NSNumber* volume;
@property (nonatomic, strong) NSNumber* rate;

@property (nonatomic, strong) CDVAudioRecorder* recorder;

@end

@interface CDVSound : CDVPlugin <AVAudioPlayerDelegate, AVAudioRecorderDelegate> {
    NSMutableDictionary* soundCache;
    NSString* currMediaId;
    AVAudioSession* avSession;
    AVPlayer* avPlayer;
}

@property (nonatomic, strong) NSMutableDictionary* soundCache;
@property (nonatomic, strong) AVAudioSession* avSession;
@property (nonatomic, strong) NSString* currMediaId;
@property (nonatomic, strong) NSTimer* meterTimer;
@property (nonatomic, assign) BOOL isMeteringEnabled;


- (void)startPlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)pausePlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)stopPlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)startRecordingAudio:(CDVInvokedUrlCommand*)command;
- (void)stopRecordingAudio:(CDVInvokedUrlCommand*)command;
- (void)seekToAudio:(CDVInvokedUrlCommand*)command;
- (void)release:(CDVInvokedUrlCommand*)command;
- (void)getCurrentPositionAudio:(CDVInvokedUrlCommand*)command;
- (void)setVolume:(CDVInvokedUrlCommand*)command;
- (void)setRate:(CDVInvokedUrlCommand*)command;

// helper methods
- (BOOL)hasAudioSession;
- (NSURL*)urlForRecording:(NSString*)resourcePath;
- (NSURL*)urlForPlaying:(NSString*)resourcePath;
- (CDVAudioFile*)audioFileForResource:(NSString*)resourcePath withId:(NSString*)mediaId doValidation:(BOOL)bValidate forRecording:(BOOL)bRecord;
- (BOOL)prepareToPlay:(CDVAudioFile*)audioFile withId:(NSString*)mediaId;
- (NSString*)createMediaErrorWithCode:(CDVMediaError)code message:(NSString*)message;
- (void)runAudioMetering: (id<CDVPlayer> *) recorder;
- (void)stopAudioMetering;
- (NSNumber*)generateAudioLevel:(id<CDVPlayer> *) recorder;
- (void)reportAudioLevel: (NSNumber*)audioLevel;

@end