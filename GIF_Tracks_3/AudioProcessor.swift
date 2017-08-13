//
//  AudioProcessor.swift
//  myGIFproject
//
//  Created by Nihar Agrawal on 8/6/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import Foundation
import AVFoundation

class AudioProcessor  {
    var avAudioSession : AVAudioSession
    let settingsDictionary : [String:Any] = [AVFormatIDKey:NSNumber(value: kAudioFormatAppleIMA4),
                                             AVSampleRateKey:NSNumber(value: 44100.0),
                                             AVNumberOfChannelsKey:NSNumber(value: 2),
                                             AVEncoderBitRateKey:NSNumber(value: 12800),
                                             AVLinearPCMBitDepthKey:NSNumber(value: 16),
                                             AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.max.rawValue)]
    let audioOutputPath : String
    var avAudioRecorder : AVAudioRecorder?
    let duration : Double
    
    init(saveAudioTo outputPath: String, timeToRecord recordingDuration: Double) {
        audioOutputPath = outputPath
        duration = recordingDuration
        
        let audioOutputURL = URL(fileURLWithPath: audioOutputPath)
        avAudioSession = AVAudioSession.sharedInstance()
        while (true) {
            do {
                try avAudioSession.setActive(true)
                print("AV Audio Session successfully set active")
                break
            }
            catch {
                print("Re trying to actviate audioSession")
                continue
            }
        }
        
        avAudioRecorder = nil
        do {
            //let errorReceived : NSError -> does not work
            avAudioRecorder = try AVAudioRecorder(url: audioOutputURL, settings: settingsDictionary)
        }
        catch {
            print("Error Received in initialized audio recording session")
        }
        
    }
    
    func record() {
        
        do {
            try avAudioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeDefault, options: [AVAudioSessionCategoryOptions.interruptSpokenAudioAndMixWithOthers]
            )
        }
        catch {
            print("AVAudioSession not initialized correctly. Aborting program")
            return
        }
        
        //determine if other music being played
        if (avAudioSession.isOtherAudioPlaying) { print("Other audio playing") }
        
        avAudioSession.requestRecordPermission { (truthValue : Bool) in
            let recordPermissionGranted = truthValue ? "Record Permission granted" : "Record Permission denied"
            print("\(recordPermissionGranted)")
        }
        
        let recordPermissionStatus = avAudioSession.recordPermission()
        switch (recordPermissionStatus) {
        case AVAudioSessionRecordPermission.granted: print("Access granted")
        case AVAudioSessionRecordPermission.denied: print("Access denied")
        case AVAudioSessionRecordPermission.undetermined: print("Access undetermined")
        default: print("Continuing")
        }
        
        let prepareToRecord = avAudioRecorder!.prepareToRecord()
        let prepareToRecordToPrint = prepareToRecord ? "true" : "false"
        print("Preparing to record: \(prepareToRecordToPrint)")
        //atTime: (avAudioRecorder!.deviceCurrentTime), forDuration: 10
        let recordingCheck = avAudioRecorder!.record(forDuration: duration)
        
        let recordingCheckToPrint = recordingCheck ? "true" : "false"
        print("Recording: \(recordingCheckToPrint)")
        
        return
    }
    
}
