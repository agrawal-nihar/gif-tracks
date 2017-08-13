//
//  File.swift
//  myGIFproject
//
//  Created by Nihar Agrawal on 8/6/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import Foundation
import AVFoundation

class AudioVideoJoiner {
    var videoFilename : String //init
    var videoAsset : AVAsset
    var audioFilename : String //init
    var audioAsset : AVAsset
    var outputFilePath : String
    var mutableComposition : AVMutableComposition
    var videoAssetTrack : AVAssetTrack!
    var audioAssetTrack : AVAssetTrack!
    var outputFileType : String
    var shouldOptimizeForNetworkUse : Bool
    var videoCompTrack : AVMutableCompositionTrack
    var audioCompTrack : AVMutableCompositionTrack
    
    init(videoAt videoFilename : String, audioAt audioFilename : String, outputAt outputFilePath: String, outputWith outputFileType : String, forNetworks shouldOptimizeForNetworkUse : Bool) {
        self.videoFilename = videoFilename
        self.audioFilename = audioFilename
        self.outputFilePath = outputFilePath
        self.shouldOptimizeForNetworkUse = shouldOptimizeForNetworkUse
        self.mutableComposition = AVMutableComposition()
        self.outputFileType = outputFileType
        
        print("1")
        //initialize videoAsset
        let videoPath = NSTemporaryDirectory() + self.videoFilename
        //use do-try-catch blocks later
        //for video in filemanager
        let videoURL = URL(fileURLWithPath: videoPath)
        let videoExists = FileManager.default.fileExists(atPath: videoURL.path)
        assert(videoExists)
        self.videoAsset = AVAsset(url: videoURL)
        self.videoAssetTrack = videoAsset.tracks[0] as AVAssetTrack
        
        print("2")
        //initialize audioAsset
        let audioPath = NSTemporaryDirectory() + self.audioFilename
        let audioURL = URL(fileURLWithPath: audioPath)
        let audioExists = FileManager.default.fileExists(atPath: audioURL.path)
        assert(audioExists)
        self.audioAsset = AVAsset(url: audioURL)
        self.audioAssetTrack = audioAsset.tracks[0] as AVAssetTrack
        
        let videoWidth = videoAssetTrack.naturalSize.width
        let videoHeight = videoAssetTrack.naturalSize.height
        //mutableComposition.naturalSize = CGSize(width: videoWidth, height: videoHeight) //need video composition for this
        //mutableComposition.frameDuration = CMTimeMake(1,60)
        
        print("3")
        //initialize composition tracks
        self.videoCompTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        self.audioCompTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        
    }
    
    public func join() {
        self.insertTracks()
        self.compose()
    }
    
    private func insertTracks() {
        print("4")
        do {
            try videoCompTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration), of: videoAssetTrack, at: kCMTimeZero)
        }
        catch {
            print(error.localizedDescription)
            print("Error in inserting video track into videoCompTrack")
        }
        
        print("5")
        do {
            try audioCompTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration), of: audioAssetTrack, at: kCMTimeZero)
        }
        catch {
            print(error.localizedDescription)
            print("Error in inserting audio track into audioCompTrack")
        }
    }
    
    private func compose() {
        let exportSessionWithMutableComposition = AVAssetExportSession(asset: mutableComposition, presetName: "AVAssetExportPresetHighestQuality")
        assert(exportSessionWithMutableComposition != nil)
        
        let outputFile = NSTemporaryDirectory() + self.outputFilePath
        exportSessionWithMutableComposition!.outputURL = URL(fileURLWithPath: outputFile)
        
        exportSessionWithMutableComposition!.outputFileType = self.outputFileType
        exportSessionWithMutableComposition!.shouldOptimizeForNetworkUse = self.shouldOptimizeForNetworkUse
        
        exportSessionWithMutableComposition?.exportAsynchronously(completionHandler: ({
            switch exportSessionWithMutableComposition!.status{
            case .failed:
                print("failed")
            case .cancelled:
                print("cancelled")
            default:
                print("complete")
            }
        }))
        
        //better way to unwrap??
        switch exportSessionWithMutableComposition!.status {
        case .waiting:
            print("Export Session Waiting")
        case .cancelled:
            print("Export Session cancelled")
        case .failed:
            print("Export Session failed")
        default:
            print("woops. Another export session status. Yikes")
        }
        
    }
    
}
