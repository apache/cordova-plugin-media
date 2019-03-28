#!/usr/bin/env node

'use strict';

var fs    = require('fs');
var plist = require('plist');  // www.npmjs.com/package/plist
var xml2js = require('xml2js');

module.exports = function (context) {
    var configPath = './config.xml';
    var configXml = fs.readFileSync(configPath).toString();
    xml2js.parseString(configXml, function(err, config){
        if (err) return console.error(err);
        // var escapedAppName = config.widget.name[0].split(" ").join("\\ ");
        var appName = config.widget.name[0];

        // plist
        var plistPath = context.opts.projectRoot + '/platforms/ios/'+ appName +'/'+ appName +'-Info.plist';
        var xml = fs.readFileSync(plistPath, 'utf8');
        var obj = plist.parse(xml);
        //
        if (!obj.hasOwnProperty('ITSAppUsesNonExemptEncryption')) {
            obj.ITSAppUsesNonExemptEncryption = false;
        }
        if (!obj.hasOwnProperty('NSLocationAlwaysUsageDescription') || obj.NSLocationAlwaysUsageDescription === '') {
            obj.NSLocationAlwaysUsageDescription = 'This app requires location access to function properly';
        }
        if (!obj.hasOwnProperty('NSLocationWhenInUseUsageDescription') || obj.NSLocationWhenInUseUsageDescription === '') {
            obj.NSLocationWhenInUseUsageDescription = 'This app requires location access to function properly';
        }
        // camera
        if (!obj.hasOwnProperty('NSCameraUsageDescription') || obj.NSCameraUsageDescription === '') {
            obj.NSCameraUsageDescription = 'Camera access is required to to use a photo as an avatar';
        }
        if (!obj.hasOwnProperty('NSPhotoLibraryUsageDescription') || obj.NSPhotoLibraryUsageDescription === '') {
            obj.NSPhotoLibraryUsageDescription = 'Photo library access is required to use an image as an avatar';
        }
        if (!obj.hasOwnProperty('NSPhotoLibraryAddUsageDescription') || obj.NSPhotoLibraryAddUsageDescription === '') {
            obj.NSPhotoLibraryAddUsageDescription = 'Photo library write-access is required to save an avatar';
        }
        if (!obj.hasOwnProperty('NSBluetoothPeripheralUsageDescription') || obj.NSBluetoothPeripheralUsageDescription === '') {
            obj.NSBluetoothPeripheralUsageDescription = 'This app uses Bluetooth to discover nearby Cast devices';
        }
        if (!obj.hasOwnProperty('NSBluetoothAlwaysUsageDescription') || obj.NSBluetoothAlwaysUsageDescription === '') {
            obj.NSBluetoothAlwaysUsageDescription = 'This app uses Bluetooth to discover nearby Cast devices';
        }
        if (!obj.hasOwnProperty('NSMicrophoneUsageDescription') || obj.NSMicrophoneUsageDescription === '') {
            obj.NSMicrophoneUsageDescription = 'This uses microphone access to listen for ultrasonic tokens when pairing with nearby Cast devices';
        }
        // write
        xml = plist.build(obj);
        fs.writeFileSync(plistPath, xml, { encoding: 'utf8' });

        // manifest
        var manifestPath = context.opts.projectRoot + '/platforms/android/app/src/main/AndroidManifest.xml';
        var androidManifest = fs.readFileSync(manifestPath).toString();
        if (androidManifest) {
            xml2js.parseString(androidManifest, function(err, manifest) {
                if (err) return console.error(err);
                
                var manifestRoot = manifest['manifest'];
                
                var applicationTag = manifestRoot.application[0]['$'];
                applicationTag['android:usesCleartextTraffic'] = true;
                applicationTag['android:allowBackup'] = false;
                
                var activityTag = manifestRoot.application[0].activity[0]['$'];
                activityTag['android:windowSoftInputMode'] = 'adjustPan';

                var builder = new xml2js.Builder();
                fs.writeFileSync(manifestPath, builder.buildObject(manifest), { encoding: 'utf8' });
            })
        }
    });
};
