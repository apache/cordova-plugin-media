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
package org.apache.cordova.media;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaResourceApi;
import org.apache.cordova.PermissionHelper;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.AudioManager;
import android.media.AudioManager.OnAudioFocusChangeListener;

import android.net.Uri;

import java.util.ArrayList;

import org.apache.cordova.PluginResult;
import org.apache.cordova.LOG;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;

/**
 * This class called by CordovaActivity to play and record audio.
 * The file can be local or over a network using http.
 *
 * Audio formats supported for player(tested):
 * 	.mp3, .wav
 * 
 * Audio recording uses MPEG-4 encoding, in a m4a wrapper.
 *
 * Local audio files must reside in one of two places:
 * 		android_asset: 		file name must start with /android_asset/sound.mp3
 * 		sdcard:				file name is just sound.mp3
 */
public class AudioHandler extends CordovaPlugin {

    public static String TAG = "AudioHandler";
    HashMap<String, AudioPlayer> players;       // Audio player object
    ArrayList<AudioPlayer> pausedForPhone;      // Audio players that were paused when phone call came in
    ArrayList<AudioPlayer> pausedForFocus;      // Audio players that were paused when focus was lost

    private int origVolumeStream = -1;
    private CallbackContext messageChannel;
    private int audioChannels;
    private int audioSampleRate;
    private boolean useCompression;

    public static String [] permissions = { Manifest.permission.RECORD_AUDIO, Manifest.permission.WRITE_EXTERNAL_STORAGE};
    public static int RECORD_AUDIO = 0;
    public static int WRITE_EXTERNAL_STORAGE = 1;

    public static final int PERMISSION_DENIED_ERROR = 20;

    private String recordId;
    private String fileUriStr;


    /**
     * Constructor.
     */
    public AudioHandler() {
        this.players = new HashMap<String, AudioPlayer>();
        this.pausedForPhone = new ArrayList<AudioPlayer>();
        this.pausedForFocus = new ArrayList<AudioPlayer>();
        this.audioChannels = 1;
        this.audioSampleRate = 44100;
        this.useCompression = false;

    }

    protected void getWritePermission(int requestCode)
    {
        PermissionHelper.requestPermission(this, requestCode, permissions[WRITE_EXTERNAL_STORAGE]);
    }


    protected void getMicPermission(int requestCode)
    {
        PermissionHelper.requestPermission(this, requestCode, permissions[RECORD_AUDIO]);
    }


    /**
     * Executes the request and returns PluginResult.
     * @param action 		The action to execute.
     * @param args 			JSONArry of arguments for the plugin.
     * @param callbackContext		The callback context used when calling back into JavaScript.
     * @return 				A PluginResult object with a status and message.
     */
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        CordovaResourceApi resourceApi = webView.getResourceApi();
        PluginResult.Status status = PluginResult.Status.OK;
        String result = "";

        if (action.equals("startRecordingAudio")) {
            recordId = args.getString(0);
            String target = args.getString(1);

            try {
                Uri targetUri = resourceApi.remapUri(Uri.parse(target));
                fileUriStr = targetUri.toString();
            } catch (IllegalArgumentException e) {
                fileUriStr = target;
            }
            this.useCompression = false;
            promptForRecord(this.useCompression);
        }
		
        else if (action.equals("startRecordingAudioWithCompression")) {
            recordId = args.getString(0);
            String target = args.getString(1);

            try {
                Uri targetUri = resourceApi.remapUri(Uri.parse(target));
                fileUriStr = targetUri.toString();
            } catch (IllegalArgumentException e) {
                fileUriStr = target;
            }

            JSONObject options = args.getJSONObject(2);

            try {
                this.audioChannels = options.getInt("NumberOfChannels");
                this.audioSampleRate = options.getInt("SampleRate");
            } catch (JSONException e) {
                this.audioChannels = 1;
                this.audioSampleRate = 44100;
            }
            this.useCompression = true;
            promptForRecord(this.useCompression);

        }
        else if (action.equals("pauseRecordingAudio")) {
            this.pauseRecordingAudio(args.getString(0));
        }
		else  if (action.equals("resumeRecordingAudio")) {
            String target = args.getString(1);
            String fileUriStr;
            try {
                Uri targetUri = resourceApi.remapUri(Uri.parse(target));
                fileUriStr = targetUri.toString();
            } catch (IllegalArgumentException e) {
                fileUriStr = target;
            }
            
            this.resumeRecordingAudio(args.getString(0), FileHelper.stripFileProtocol(fileUriStr), this.audioChannels, this.audioSampleRate);
        }
        else if (action.equals("stopRecordingAudio")) {
            this.stopRecordingAudio(args.getString(0));
        }
        else if (action.equals("startPlayingAudio")) {
            String target = args.getString(1);
            String fileUriStr;
            try {
                Uri targetUri = resourceApi.remapUri(Uri.parse(target));
                fileUriStr = targetUri.toString();
            } catch (IllegalArgumentException e) {
                fileUriStr = target;
            }
            this.startPlayingAudio(args.getString(0), FileHelper.stripFileProtocol(fileUriStr));
        }
        else if (action.equals("seekToAudio")) {
           try {
                this.seekToAudio(args.getString(0), args.getInt(1));
            } catch (NumberFormatException nfe) {
               //no-op
           }
        }
        else if (action.equals("pausePlayingAudio")) {
            this.pausePlayingAudio(args.getString(0));
        }
        else if (action.equals("stopPlayingAudio")) {
            this.stopPlayingAudio(args.getString(0));
        } else if (action.equals("setVolume")) {
           try {
               this.setVolume(args.getString(0), Float.parseFloat(args.getString(1)));
           } catch (NumberFormatException nfe) {
               //no-op
           }
        } else if (action.equals("getCurrentPositionAudio")) {
            float f = this.getCurrentPositionAudio(args.getString(0));
            callbackContext.sendPluginResult(new PluginResult(status, f));
            return true;
        }
        else if (action.equals("getDurationAudio")) {
            float f = this.getDurationAudio(args.getString(0), args.getString(1));
            callbackContext.sendPluginResult(new PluginResult(status, f));
            return true;
        }
		
		//REM mods
		else if (action.equals("getRecordDbLevel")) {
            float f = this.getAudioRecordDbLevel(args.getString(0));
            callbackContext.sendPluginResult(new PluginResult(status, f));
            return true;
        }
		//---
		
        else if (action.equals("create")) {
            String id = args.getString(0);
            String src = FileHelper.stripFileProtocol(args.getString(1));
            getOrCreatePlayer(id, src);
        }
        else if (action.equals("release")) {
            boolean b = this.release(args.getString(0));
            callbackContext.sendPluginResult(new PluginResult(status, b));
            return true;
        }
        else if (action.equals("messageChannel")) {
            messageChannel = callbackContext;
            return true;
        }
        else { // Unrecognized action.
            return false;
        }

        callbackContext.sendPluginResult(new PluginResult(status, result));

        return true;
    }

    /**
     * Stop all audio players and recorders.
     */
    public void onDestroy() {
        if (!players.isEmpty()) {
            onLastPlayerReleased();
        }
        for (AudioPlayer audio : this.players.values()) {
            audio.destroy();
        }
        this.players.clear();
    }

    /**
     * Stop all audio players and recorders on navigate.
     */
    @Override
    public void onReset() {
        onDestroy();
    }

    /**
     * Called when a message is sent to plugin.
     *
     * @param id            The message id
     * @param data          The message data
     * @return              Object to stop propagation or null
     */
    public Object onMessage(String id, Object data) {

        // If phone message
        if (id.equals("telephone")) {

            // If phone ringing, then pause playing
            if ("ringing".equals(data) || "offhook".equals(data)) {

                // Get all audio players and pause them
                for (AudioPlayer audio : this.players.values()) {
                    if (audio.getState() == AudioPlayer.STATE.MEDIA_RUNNING.ordinal()) {
                        this.pausedForPhone.add(audio);
                        audio.pausePlaying();
                    }
                }

            }

            // If phone idle, then resume playing those players we paused
            else if ("idle".equals(data)) {
                for (AudioPlayer audio : this.pausedForPhone) {
                    audio.startPlaying(null);
                }
                this.pausedForPhone.clear();
            }
        }
        return null;
    }

    //--------------------------------------------------------------------------
    // LOCAL METHODS
    //--------------------------------------------------------------------------

    private AudioPlayer getOrCreatePlayer(String id, String file) {
        AudioPlayer ret = players.get(id);
        if (ret == null) {
            if (players.isEmpty()) {
                onFirstPlayerCreated();
            }
            ret = new AudioPlayer(this, id, file);
            players.put(id, ret);
        }
        return ret;
    }

    /**
     * Release the audio player instance to save memory.
     * @param id				The id of the audio player
     */
    private boolean release(String id) {
        AudioPlayer audio = players.remove(id);
        if (audio == null) {
            return false;
        }
        if (players.isEmpty()) {
            onLastPlayerReleased();
        }
        audio.destroy();
        return true;
    }

    /**
     * Start recording and save the specified file.
     * @param id				The id of the audio player
     * @param file				The name of the file
     */
    public void startRecordingAudio(String id, String file) {
        AudioPlayer audio = getOrCreatePlayer(id, file);
        audio.startRecording(file);
    }

    /**
     * Start recording with compression and save the specified file.
     * @param id                The id of the audio player
     * @param file              The name of the file
     * @param channels          1 or 2, mono or stereo, default value is 1
     * @param sampleRate        sample rate in hz, 8000 to 48000, optional, default value is 44100
     */
    public void startRecordingAudioWithCompression(String id, String file, Integer channels, Integer sampleRate) {
        AudioPlayer audio = getOrCreatePlayer(id, file);
        audio.startRecordingWithCompression(file, channels, sampleRate);
    }
	
	/**
     * Pause recording (stop recording) and append to the file specified when recording started.
     * @param id				The id of the audio player
     */
    public void pauseRecordingAudio(String id) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            audio.pauseRecording();
        }
    }

	/**
     * Resume recording and save the specified file.
     * @param id				The id of the audio player
     * @param file				The name of the file
     * @param channels          1 or 2, mono or stereo, default value is 1
     * @param sampleRate        sample rate in hz, 8000 to 48000, optional, default value is 44100
     */
     public void resumeRecordingAudio(String id, String file, Integer channels, Integer sampleRate) {
       AudioPlayer audio = getOrCreatePlayer(id, file);
             audio.resumeRecording(file, channels, sampleRate);
     }

    /**
     * Stop recording.
     * Note: This plugin never calls audio.stopRecording. 
     * Instead it calls the pauseRecording method.
     * stopRecording is not required since it does not append.
     * @param id				The id of the audio player
     */
    public void stopRecordingAudio(String id) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            audio.pauseRecording();
        }
    }

    /**
     * Start or resume playing audio file.
     * @param id				The id of the audio player
     * @param file				The name of the audio file.
     */
    public void startPlayingAudio(String id, String file) {
        AudioPlayer audio = getOrCreatePlayer(id, file);
        audio.startPlaying(file);
    }

    /**
     * Seek to a location.
     * @param id				The id of the audio player
     * @param milliseconds		int: number of milliseconds to skip 1000 = 1 second
     */
    public void seekToAudio(String id, int milliseconds) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            audio.seekToPlaying(milliseconds);
        }
    }

    /**
     * Pause playing.
     * @param id				The id of the audio player
     */
    public void pausePlayingAudio(String id) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            audio.pausePlaying();
        }
    }

    /**
     * Stop playing the audio file.
     * @param id				The id of the audio player
     */
    public void stopPlayingAudio(String id) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            audio.stopPlaying();
        }
    }
	
	 /**
     * Get dB level of recording microphone power
     * @param id
     * @return dB power level
     */

    public float getAudioRecordDbLevel(String id) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            return audio.getRecordDbLevel();
        }
        return -1;
    }


    /**
     * Get current position of playback.
     * @param id				The id of the audio player
     * @return 					position in msec
     */
    public float getCurrentPositionAudio(String id) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            return (audio.getCurrentPosition() / 1000.0f);
        }
        return -1;
    }

    /**
     * Get the duration of the audio file.
     * @param id				The id of the audio player
     * @param file				The name of the audio file.
     * @return					The duration in msec.
     */
    public float getDurationAudio(String id, String file) {
        AudioPlayer audio = getOrCreatePlayer(id, file);
        return audio.getDuration(file);
    }

    /**
     * Set the audio device to be used for playback.
     *
     * @param output			1=earpiece, 2=speaker
     */
    @SuppressWarnings("deprecation")
    public void setAudioOutputDevice(int output) {
        AudioManager audiMgr = (AudioManager) this.cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);
        if (output == 2) {
            audiMgr.setRouting(AudioManager.MODE_NORMAL, AudioManager.ROUTE_SPEAKER, AudioManager.ROUTE_ALL);
        }
        else if (output == 1) {
            audiMgr.setRouting(AudioManager.MODE_NORMAL, AudioManager.ROUTE_EARPIECE, AudioManager.ROUTE_ALL);
        }
        else {
            System.out.println("AudioHandler.setAudioOutputDevice() Error: Unknown output device.");
        }
    }


    /**
     * Get the audio device to be used for playback.
     *
     * @return					1=earpiece, 2=speaker
     */
    @SuppressWarnings("deprecation")
    public int getAudioOutputDevice() {
        AudioManager audiMgr = (AudioManager) this.cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);
        if (audiMgr.getRouting(AudioManager.MODE_NORMAL) == AudioManager.ROUTE_EARPIECE) {
            return 1;
        }
        else if (audiMgr.getRouting(AudioManager.MODE_NORMAL) == AudioManager.ROUTE_SPEAKER) {
            return 2;
        }
        else {
            return -1;
        }
    }

    /**
     * Set the volume for an audio device
     *
     * @param id				The id of the audio player
     * @param volume            Volume to adjust to 0.0f - 1.0f
     */
    public void setVolume(String id, float volume) {
        AudioPlayer audio = this.players.get(id);
        if (audio != null) {
            audio.setVolume(volume);
        } else {
            System.out.println("AudioHandler.setVolume() Error: Unknown Audio Player " + id);
        }
    }


    public void pauseAllLostFocus() {
        for (AudioPlayer audio : this.players.values()) {
            if (audio.getState() == AudioPlayer.STATE.MEDIA_RUNNING.ordinal()) {
                this.pausedForFocus.add(audio);
                audio.pausePlaying();
            }
        }
    }

    public void resumeAllGainedFocus() {
        for (AudioPlayer audio : this.pausedForFocus) {
            audio.startPlaying(null);
        }
        this.pausedForFocus.clear();
    }

    /**
     * Get the the audio focus
     */
    private OnAudioFocusChangeListener focusChangeListener = new OnAudioFocusChangeListener() {
        public void onAudioFocusChange(int focusChange) {
            switch (focusChange) {
                case (AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) :
                case (AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) :
                case (AudioManager.AUDIOFOCUS_LOSS) :
                    pauseAllLostFocus();
                    break;
                case (AudioManager.AUDIOFOCUS_GAIN):
                    resumeAllGainedFocus();
                    break;
                default:
                    break;
            }
        }
    };

    public void getAudioFocus() {
        String TAG2 = "AudioHandler.getAudioFocus(): Error : ";

        AudioManager am = (AudioManager) this.cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);
        int result = am.requestAudioFocus(focusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN);

        if (result != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            LOG.e(TAG2,result + " instead of " + AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
        }

    }

    private void onFirstPlayerCreated() {
        origVolumeStream = cordova.getActivity().getVolumeControlStream();
        cordova.getActivity().setVolumeControlStream(AudioManager.STREAM_MUSIC);
    }

    private void onLastPlayerReleased() {
        if (origVolumeStream != -1) {
            cordova.getActivity().setVolumeControlStream(origVolumeStream);
            origVolumeStream = -1;
        }
    }

    void sendEventMessage(String action, JSONObject actionData) {
        JSONObject message = new JSONObject();
        try {
            message.put("action", action);
            if (actionData != null) {
                message.put(action, actionData);
            }
        } catch (JSONException e) {
            LOG.e(TAG, "Failed to create event message", e);
        }

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message);
        pluginResult.setKeepCallback(true);
        if (messageChannel != null) {
            messageChannel.sendPluginResult(pluginResult);
        }
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException
    {
        for(int r:grantResults)
        {
            if(r == PackageManager.PERMISSION_DENIED)
            {
                this.messageChannel.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, PERMISSION_DENIED_ERROR));
                return;
            }
        }
        promptForRecord(this.useCompression);
    }

    /*
     * This little utility method catch-all work great for multi-permission stuff.
     *
     */

    private void promptForRecord(boolean withCompression)
    {
        if(PermissionHelper.hasPermission(this, permissions[WRITE_EXTERNAL_STORAGE])  &&
                PermissionHelper.hasPermission(this, permissions[RECORD_AUDIO])) {
            if (withCompression) {
                this.startRecordingAudioWithCompression(recordId, FileHelper.stripFileProtocol(fileUriStr),this.audioChannels,this.audioSampleRate);
            } else {
                this.startRecordingAudio(recordId, FileHelper.stripFileProtocol(fileUriStr));
            }
        }
        else if(PermissionHelper.hasPermission(this, permissions[RECORD_AUDIO]))
        {
            getWritePermission(WRITE_EXTERNAL_STORAGE);
        }
        else
        {
            getMicPermission(RECORD_AUDIO);
        }

    }
}
