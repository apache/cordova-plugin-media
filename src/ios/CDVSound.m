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

 /* 
 Modified by R.E. Moore Jr. 4-30-2015
 Added new method startRecordAudioWithCompression
 Using background thread for audio record and play

 */

 /* 

 5/13/2015: switched to .m4a file with using kAudioFormatMPEG4AAC 
for significantly better compression.

 */

/*
01/08/2016: Added methods to pause  and resume audio recording, get audio levels. 
*/

/*
 02/03/2016: Added AVAudioSessionCategoryOptionMixWithOthers for Play and Record
 See: http://stackoverflow.com/questions/31881565/cordova-media-plugin-breaks-html5-audio-tag-on-ios
 */

 /*
 02/12/2016: Revised recorder(s) block code to use weak var instead of self
 */

 /*
 03/11/2016: From recorder methods, added override to send all audio ouput to speaker. 
 Resolves playback to earpiece from HTML5 audio tag if the media play method is not called prior to the app using HTML5 audio tag for playback 
 */

 /*06/07/2016: resolve compile error with Cordova 4.x
 Remove: #import <Cordova/NSArray+Comparisons.h>
 Add: #import <AVFoundation/AVFoundation.h>
 */

#import "CDVSound.h"
#import "CDVFile.h"
#import <AVFoundation/AVFoundation.h>


#define DOCUMENTS_SCHEME_PREFIX @"documents://"
#define HTTP_SCHEME_PREFIX @"http://"
#define HTTPS_SCHEME_PREFIX @"https://"
#define CDVFILE_PREFIX @"cdvfile://"
#define RECORDING_M4A @"m4a"

@implementation CDVSound

@synthesize soundCache, avSession;

// Maps a url for a resource path for recording
- (NSURL*)urlForRecording:(NSString*)resourcePath
{
    NSURL* resourceURL = nil;
    NSString* filePath = nil;
    NSString* docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

    // first check for correct extension
    if ([[resourcePath pathExtension] caseInsensitiveCompare:RECORDING_M4A] != NSOrderedSame) {
        resourceURL = nil;
        NSLog(@"Resource for recording must have %@ extension", RECORDING_M4A);
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

// Creates or gets the cached audio file resource object
- (CDVAudioFile*)audioFileForResource:(NSString*)resourcePath withId:(NSString*)mediaId doValidation:(BOOL)bValidate forRecording:(BOOL)bRecord
{
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
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:errcode message:errMsg]];
        [self.commandDelegate evalJs:jsString];
    }

    return audioFile;
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

- (void)create:(CDVInvokedUrlCommand*)command
{
    
    NSString* mediaId = [command argumentAtIndex:0];
    NSString* resourcePath = [command argumentAtIndex:1];

    CDVAudioFile* audioFile = [self audioFileForResource:resourcePath withId:mediaId doValidation:NO forRecording:NO];

    if (audioFile == nil) {
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize Media file with path %@", resourcePath];
        NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMessage]];
        [self.commandDelegate evalJs:jsString];
    } else {
        
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)setVolume:(CDVInvokedUrlCommand*)command
{
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

- (void)startPlayingAudio:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{

        NSString* callbackId = command.callbackId;

    #pragma unused(callbackId)
        NSString* mediaId = [command argumentAtIndex:0];
        NSString* resourcePath = [command argumentAtIndex:1];
        NSDictionary* options = [command argumentAtIndex:2 withDefault:nil];

        BOOL bError = NO;
        NSString* jsString = nil;

        CDVAudioFile* audioFile = [self audioFileForResource:resourcePath withId:mediaId doValidation:YES forRecording:NO];
        if ((audioFile != nil) && (audioFile.resourceURL != nil)) {
            if (audioFile.player == nil) {
                bError = [self prepareToPlay:audioFile withId:mediaId];
            }
            if (!bError) {
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
                    NSLog(@"Playing audio sample '%@'", audioFile.resourcePath);
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

                    [audioFile.player play];
                    double position = round(audioFile.player.duration * 1000) / 1000;
                    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);\n%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_DURATION, position, @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_RUNNING];
                    [self.commandDelegate evalJs:jsString];
                }
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
                // jsString = [NSString stringWithFormat: @"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR,  MEDIA_ERR_NONE_SUPPORTED];
                jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_NONE_SUPPORTED message:nil]];
                [self.commandDelegate evalJs:jsString];
            }
        }
        // else audioFile was nil - error already returned from audioFile for resource
        return;
    }];
}

- (BOOL)prepareToPlay:(CDVAudioFile*)audioFile withId:(NSString*)mediaId
{
    BOOL bError = NO;
    NSError* __autoreleasing playerError = nil;

    // create the player
    NSURL* resourceURL = audioFile.resourceURL;

    if ([resourceURL isFileURL]) {
        audioFile.player = [[CDVAudioPlayer alloc] initWithContentsOfURL:resourceURL error:&playerError];
    } else {
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
    }

    if (playerError != nil) {
        NSLog(@"Failed to initialize AVAudioPlayer: %@\n", [playerError localizedDescription]);
        audioFile.player = nil;
        if (self.avSession) {
            [self.avSession setActive:NO error:nil];
        }
        bError = YES;
    } else {
        audioFile.player.mediaId = mediaId;
        audioFile.player.delegate = self;
        bError = ![audioFile.player prepareToPlay];
    }
    return bError;
}

- (void)stopPlayingAudio:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command argumentAtIndex:0];
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSLog(@"Stopped playing audio sample '%@'", audioFile.resourcePath);
        [audioFile.player stop];
        audioFile.player.currentTime = 0;
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_STOPPED];
    }  // ignore if no media playing
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)pausePlayingAudio:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command argumentAtIndex:0];
    NSString* jsString = nil;
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSLog(@"Paused playing audio sample '%@'", audioFile.resourcePath);
        [audioFile.player pause];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_PAUSED];
    }
    // ignore if no media playing

    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)seekToAudio:(CDVInvokedUrlCommand*)command
{
    // args:
    // 0 = Media id
    // 1 = path to resource
    // 2 = seek to location in milliseconds

    NSString* mediaId = [command argumentAtIndex:0];

    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    double position = [[command argumentAtIndex:1] doubleValue];

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSString* jsString;
        double posInSeconds = position / 1000;
        if (posInSeconds >= audioFile.player.duration) {
            // The seek is past the end of file.  Stop media and reset to beginning instead of seeking past the end.
            [audioFile.player stop];
            audioFile.player.currentTime = 0;
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);\n%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_POSITION, 0.0, @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_STOPPED];
            // NSLog(@"seekToEndJsString=%@",jsString);
        } else {
            audioFile.player.currentTime = posInSeconds;
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%f);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_POSITION, posInSeconds];
            // NSLog(@"seekJsString=%@",jsString);
        }

        [self.commandDelegate evalJs:jsString];
    }
}

- (void)release:(CDVInvokedUrlCommand*)command
{
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
            if (self.avSession) {
                [self.avSession setActive:NO error:nil];
                self.avSession = nil;
            }
            [[self soundCache] removeObjectForKey:mediaId];
            NSLog(@"Media with id %@ released", mediaId);
        }
    }
}

- (void)getCurrentPositionAudio:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* mediaId = [command argumentAtIndex:0];

#pragma unused(mediaId)
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    double position = -1;

    if ((audioFile != nil) && (audioFile.player != nil) && [audioFile.player isPlaying]) {
        position = round(audioFile.player.currentTime * 1000) / 1000;
    }
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:position];
    
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_POSITION, position];
    [self.commandDelegate evalJs:jsString];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)startRecordingAudio:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{

        NSString* callbackId = command.callbackId;

    #pragma unused(callbackId)

        NSString* mediaId = [command argumentAtIndex:0];
        CDVAudioFile* audioFile = [self audioFileForResource:[command argumentAtIndex:1] withId:mediaId doValidation:YES forRecording:YES];
        __block NSString* jsString = nil;
        __block NSString* errorMsg = @"";

        if ((audioFile != nil) && (audioFile.resourceURL != nil)) {

            __weak CDVSound* weakSelf = self;

            void (^startRecording)(void) = ^{
                NSError* __autoreleasing error = nil;
                
                if (audioFile.recorder != nil) {
                    [audioFile.recorder stop];
                    audioFile.recorder = nil;
                }
                // get the audioSession and set the category to allow recording when device is locked or ring/silent switch engaged
                if ([weakSelf hasAudioSession]) {
                    if (![weakSelf.avSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
                        [weakSelf.avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
						// force output to speaker, resolves issues with HTML5 audio playback within the app
						// [weakSelf.avSession overrideOutputAudioPort:AVAudioSessionCategoryOptionDefaultToSpeaker  error:nil];
                    }

                    if (![weakSelf.avSession setActive:YES error:&error]) {
                        // other audio with higher priority that does not allow mixing could cause this to fail
                        errorMsg = [NSString stringWithFormat:@"Unable to record audio: %@", [error localizedFailureReason]];
                        // jsString = [NSString stringWithFormat: @"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, MEDIA_ERR_ABORTED];
                        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
                        [weakSelf.commandDelegate evalJs:jsString];
                        return;
                    }
                }

                 // Set default formatID, quality, sampleRate and audioChannels
                NSNumber* formatID = [NSNumber numberWithInt: kAudioFormatMPEG4AAC];
                NSNumber* quality = [NSNumber numberWithInt:AVAudioQualityMedium];
                NSNumber* sampleRate = [NSNumber numberWithFloat: 44100.0];
                NSNumber* numberOfChannels = [NSNumber numberWithInt: 1];
                
                
                NSDictionary* recorderSettingsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    formatID,AVFormatIDKey,
                    quality,AVEncoderAudioQualityKey,
                    sampleRate,AVSampleRateKey,
                    numberOfChannels,AVNumberOfChannelsKey,
                    nil
                ];
                
                audioFile.recorder = [[CDVAudioRecorder alloc] initWithURL:audioFile.resourceURL settings:recorderSettingsDict error:&error];
                
                //enable metering
                audioFile.recorder.meteringEnabled = YES;


                bool recordingSuccess = NO;
                if (error == nil) {
                    audioFile.recorder.delegate = weakSelf;
                    audioFile.recorder.mediaId = mediaId;
                    recordingSuccess = [audioFile.recorder record];
                    if (recordingSuccess) {
                        NSLog(@"Started recording audio sample '%@'", audioFile.resourcePath);
                        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_RUNNING];
                        [weakSelf.commandDelegate evalJs:jsString];
                    }
                }
                
                if ((error != nil) || (recordingSuccess == NO)) {
                    if (error != nil) {
                        errorMsg = [NSString stringWithFormat:@"Failed to initialize AVAudioRecorder: %@\n", [error localizedFailureReason]];
                    } else {
                        errorMsg = @"Failed to start recording using AVAudioRecorder";
                    }
                    audioFile.recorder = nil;
                    if (weakSelf.avSession) {
                        [weakSelf.avSession setActive:NO error:nil];
                    }
                    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
                    [weakSelf.commandDelegate evalJs:jsString];
                }
            };
            
            SEL rrpSel = NSSelectorFromString(@"requestRecordPermission:");
            if ([self hasAudioSession] && [self.avSession respondsToSelector:rrpSel])
            {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.avSession performSelector:rrpSel withObject:^(BOOL granted){
                    if (granted) {
                        startRecording();
                    } else {
                        NSString* msg = @"Error creating audio session, microphone permission denied.";
                        NSLog(@"%@", msg);
                        audioFile.recorder = nil;
                        if (weakSelf.avSession) {
                            [weakSelf.avSession setActive:NO error:nil];
                        }
                        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [weakSelf createMediaErrorWithCode:MEDIA_ERR_ABORTED message:msg]];
                        [weakSelf.commandDelegate evalJs:jsString];
                    }
                }];
    #pragma clang diagnostic pop
            } else {
                startRecording();
            }
            
        } else {
            // file did not validate
            NSString* errorMsg = [NSString stringWithFormat:@"Could not record audio at '%@'", audioFile.resourcePath];
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
            [self.commandDelegate evalJs:jsString];
        }
    }];
}

// REM Add: 04-30-2015
- (void)startRecordingAudioWithCompression:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{

        NSString* callbackId = command.callbackId;

        #pragma unused(callbackId)

        NSString* mediaId = [command argumentAtIndex:0];
        CDVAudioFile* audioFile = [self audioFileForResource:[command argumentAtIndex:1] withId:mediaId doValidation:YES forRecording:YES];
        __block NSString* jsString = nil;
        __block NSString* errorMsg = @"";
    
        if ((audioFile != nil) && (audioFile.resourceURL != nil)) {

            __weak CDVSound* weakSelf = self;

            void (^startRecording)(void) = ^{
                NSError* __autoreleasing error = nil;
                
                if (audioFile.recorder != nil) {
                    [audioFile.recorder stop];
                    audioFile.recorder = nil;
                }
                // get the audioSession and set the category to allow recording when device is locked or ring/silent switch engaged
                if ([weakSelf hasAudioSession]) {
                    if (![weakSelf.avSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
                        [weakSelf.avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
						// force output to speaker, resolves issues with HTML5 audio playback within the app
						// [weakSelf.avSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
                    }

                    if (![weakSelf.avSession setActive:YES error:&error]) {
                        // other audio with higher priority that does not allow mixing could cause this to fail
                        errorMsg = [NSString stringWithFormat:@"Unable to record audio: %@", [error localizedFailureReason]];
                        // jsString = [NSString stringWithFormat: @"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, MEDIA_ERR_ABORTED];
                        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [weakSelf createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
                        [weakSelf.commandDelegate evalJs:jsString];
                        return;
                    }
                }
                // Set default format as MPEG4, quality min for best compression        
                NSNumber* formatID = [NSNumber numberWithInt:kAudioFormatMPEG4AAC];
                NSNumber* quality = [NSNumber numberWithInt:AVAudioQualityMin];

                // default values, modify as required
                static const float defaultSampleRate = 44100.0;
                static const int defaultChannels = 1;
    
                // Set default SampleRate, NumberOfChannels if values are missing    
                NSNumber* sampleRate = [[command.arguments objectAtIndex:2] objectForKey:@"SampleRate"];
                sampleRate = sampleRate!=nil ? sampleRate:[NSNumber numberWithFloat:defaultSampleRate];
        
                NSNumber* numberOfChannels = [[command.arguments objectAtIndex:2] objectForKey:@"NumberOfChannels"];
                numberOfChannels = numberOfChannels != nil ? numberOfChannels:[NSNumber numberWithInt:defaultChannels];
                
                NSDictionary* recorderSettingsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    formatID,AVFormatIDKey,
                    quality,AVEncoderAudioQualityKey,
                    sampleRate,AVSampleRateKey,
                    numberOfChannels,AVNumberOfChannelsKey,
                    nil
                ];
                
                audioFile.recorder = [[CDVAudioRecorder alloc] initWithURL:audioFile.resourceURL settings:recorderSettingsDict error:&error];

                //enable metering
                audioFile.recorder.meteringEnabled = YES;
                
                bool recordingSuccess = NO;
                if (error == nil) {
                    audioFile.recorder.delegate = weakSelf;
                    audioFile.recorder.mediaId = mediaId;
                    recordingSuccess = [audioFile.recorder record];
                    if (recordingSuccess) {
                        NSLog(@"Started recording audio sample '%@'", audioFile.resourcePath);
                        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_RUNNING];
                        [weakSelf.commandDelegate evalJs:jsString];
                    }
                }
                
                if ((error != nil) || (recordingSuccess == NO)) {
                    if (error != nil) {
                        NSLog(@"Failed to initialize AVAudioRecorder.");
                        errorMsg = [NSString stringWithFormat:@"Failed to initialize AVAudioRecorder: %@\n", [error localizedFailureReason]];
                    } else {
                        NSLog(@"Failed to start recroding using AVAudioRecorder.");
                        errorMsg = @"Failed to start recording using AVAudioRecorder";
                    }
                    audioFile.recorder = nil;
                    if (weakSelf.avSession) {
                        [weakSelf.avSession setActive:NO error:nil];
                    }
                    jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [weakSelf createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
                    [weakSelf.commandDelegate evalJs:jsString];
                }
            };
            
            SEL rrpSel = NSSelectorFromString(@"requestRecordPermission:");
            if ([self hasAudioSession] && [self.avSession respondsToSelector:rrpSel])
            {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.avSession performSelector:rrpSel withObject:^(BOOL granted){
                    if (granted) {
                        startRecording();
                    } else {
                        NSString* msg = @"Error creating audio session, microphone permission denied.";
                        NSLog(@"%@", msg);
                        audioFile.recorder = nil;
                        if (weakSelf.avSession) {
                            [weakSelf.avSession setActive:NO error:nil];
                        }
                        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:msg]];
                        [weakSelf.commandDelegate evalJs:jsString];
                    }
                }];
    #pragma clang diagnostic pop
            } else {
                NSLog(@"Start recording.");
                startRecording();
            }
            
        } else {
            // file did not validate
            NSLog(@"File did not validate.");
            NSString* errorMsg = [NSString stringWithFormat:@"Could not record audio at '%@'", audioFile.resourcePath];
            jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMsg]];
            [self.commandDelegate evalJs:jsString];
        }
    }];
}

- (void)stopRecordingAudio:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command argumentAtIndex:0];

    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.recorder != nil)) {
        NSLog(@"Stopped recording audio sample '%@'", audioFile.resourcePath);
        [audioFile.recorder stop];
        // no callback - that will happen in audioRecorderDidFinishRecording
    }
    // ignore if no media recording
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}



- (void)pauseRecordingAudio:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command argumentAtIndex:0];

    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.recorder != nil)) {
        NSLog(@"Paused recording audio sample '%@'", audioFile.resourcePath);
        [audioFile.recorder pause];
        // no callback - that will happen in audioRecorderDidFinishRecording
    }
    // ignore if no media recording
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)resumeRecordingAudio:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command argumentAtIndex:0];

    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.recorder != nil)) {
        NSLog(@"Resumed recording audio sample '%@'", audioFile.resourcePath);
        [audioFile.recorder record];
        // no callback - that will happen in audioRecorderDidFinishRecording
    }
    // ignore if no media recording
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)getAudioRecordingLevels:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command argumentAtIndex:0];

    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.recorder != nil)) {
        // NSLog(@"Resumed recording audio sample '%@'", audioFile.resourcePath);
        [audioFile.recorder updateMeters];
        float averagePower = [audioFile.recorder averagePowerForChannel:0];
        float peakPower = [audioFile.recorder peakPowerForChannel:0];
        
        NSLog(@"averagePower: '%f' peakPower: '%f'",averagePower,peakPower);
        
        NSMutableDictionary* powerLevels = [NSMutableDictionary dictionaryWithCapacity:2];
        
        [powerLevels setObject:[NSNumber numberWithFloat:averagePower] forKey:@"averagePower"];
        [powerLevels setObject:[NSNumber numberWithFloat:peakPower] forKey:@"peakPower"];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:powerLevels];
        
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        
    }
    // ignore if no media recording
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}


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
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_STOPPED];
    } else {
        // jsString = [NSString stringWithFormat: @"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, MEDIA_ERR_DECODE];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_DECODE message:nil]];
    }
    if (self.avSession) {
        [self.avSession setActive:NO error:nil];
    }
    [self.commandDelegate evalJs:jsString];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    CDVAudioPlayer* aPlayer = (CDVAudioPlayer*)player;
    NSString* mediaId = aPlayer.mediaId;
    CDVAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if (audioFile != nil) {
        NSLog(@"Finished playing audio sample '%@'", audioFile.resourcePath);
    }
    if (flag) {
        audioFile.player.currentTime = 0;
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_STATE, MEDIA_STOPPED];
    } else {
        // jsString = [NSString stringWithFormat: @"%@(\"%@\",%d,%d);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, MEDIA_ERR_DECODE];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova-media-with-compression.Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_DECODE message:nil]];
    }
    if (self.avSession) {
        [self.avSession setActive:NO error:nil];
    }
    [self.commandDelegate evalJs:jsString];
}

- (void)onMemoryWarning
{
    [[self soundCache] removeAllObjects];
    [self setSoundCache:nil];
    [self setAvSession:nil];

    [super onMemoryWarning];
}

- (void)dealloc
{
    [[self soundCache] removeAllObjects];
}

- (void)onReset
{
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
@synthesize player, volume;
@synthesize recorder;

@end
@implementation CDVAudioPlayer
@synthesize mediaId;

@end

@implementation CDVAudioRecorder
@synthesize mediaId;

@end
