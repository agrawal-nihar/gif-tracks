//
//  File.swift
//  myGIFproject
//
//  Created by Nihar Agrawal on 7/29/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import Foundation
import CoreData
import AVKit
import CoreAudio
import CoreVideo
import AVFoundation
import ImageIO

class GIFConverterToVideo {
    var duration : Double
    var GIFSourceFilePath : String
    var mult16imageSize : CGSize
    var outputFilePath : String
    var outputSettings : [String: Any]
    var sourcePixelAttributesDictionary : [String : NSNumber]
    var secondsPerFrame : Double
    var numberOfImages : Int
    var imageArray : [CGImage]
    var mult16width : Int
    var mult16height : Int
    
    
    init( _ sourcePath: String, _ outputPath:String, _ frameTimeInterval:Double, _ images: [CGImage], _ numImages : Int) {
        GIFSourceFilePath = sourcePath
        outputFilePath = outputPath
        secondsPerFrame = frameTimeInterval
        imageArray = images
        numberOfImages = numImages
        mult16imageSize = CGSize(width: 0, height: 0) //default
        outputSettings = [String: Any]()
        sourcePixelAttributesDictionary = [String: NSNumber]()
        duration = 0
        
        //get data behind GIF
        let imageDataURL = NSURL.fileURL(withPath: GIFSourceFilePath)
        let imageData = try! Data(contentsOf: imageDataURL as URL)
        let gifImages = CGImageSourceCreateWithData(NSData(data: imageData), nil)
        numberOfImages = Int(CGImageSourceGetCount(gifImages!))
        
        for imageIndex in 0..<numberOfImages {
            let imageToAppend = CGImageSourceCreateImageAtIndex(gifImages!, imageIndex, nil)
            if let imageforArray = imageToAppend {
                imageArray.append(imageforArray)
            }
            else {
                print("Error in getting image \(imageIndex)")
            }
        }
        mult16width = Int(floor(CGFloat(imageArray[0].width) / 16)) * 16
        mult16height = Int(floor(CGFloat(imageArray[0].height) / 16)) * 16
        
        mult16imageSize = CGSize(width: mult16width, height: mult16height)
        
        outputSettings =  [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber(value: Float(mult16imageSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(mult16imageSize.height)),
        ]
        sourcePixelAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(mult16imageSize.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(mult16imageSize.height))
        ]

    }
    
    public func doConvertGIFtoVideo() -> Bool {
        //self.createGIFSource()
        return self.implementConversion()
    }
    
    /* private func createGIFSource() -> Void {
        
        //get data behind GIF
        let imageDataURL = NSURL.fileURL(withPath: GIFSourceFilePath)
        let imageData = try! Data(contentsOf: imageDataURL as URL)
        let gifImages = CGImageSourceCreateWithData(NSData(data: imageData), nil)
        numberOfImages = Int(CGImageSourceGetCount(gifImages!))
        
        for imageIndex in 0..<numberOfImages {
            let imageToAppend = CGImageSourceCreateImageAtIndex(gifImages!, imageIndex, nil)
            if let imageforArray = imageToAppend {
                imageArray.append(imageforArray)
            }
            else {
                print("Error in getting image \(imageIndex)")
            }
        }
        mult16imageSize = CGSize(width: floor(CGFloat(imageArray[0].width) / 16) * 16, height: floor(CGFloat(imageArray[0].height) / 16) * 16)
        
        outputSettings =  [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber(value: Float(mult16imageSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(mult16imageSize.height)),
        ]
        sourcePixelAttributesDictionary = [
            kCVpixBufPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVpixBufWidthKey as String: NSNumber(value: Float(mult16imageSize.width)),
            kCVpixBufHeightKey as String: NSNumber(value: Float(mult16imageSize.height))
        ]
        
        return
    } */
 
    
        //DONE
    private func implementConversion() -> Bool {
        let assetWriter = try? AVAssetWriter(url: URL(fileURLWithPath: outputFilePath), fileType: AVFileTypeMPEG4)
        if (assetWriter != nil) {
            print("No error in initializing asset writer")
        }
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        writerInput.expectsMediaDataInRealTime = true
        let assetWriterInitErr = assetWriter!.canAdd(writerInput) ? "Input is compatible" : "Input to writer is not compatible"
        print("\(assetWriterInitErr)")
        assert(assetWriter!.canAdd(writerInput))
        assetWriter!.add(writerInput)
        
        let assetWriterInputpixBufAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelAttributesDictionary)
        
        assetWriter!.startWriting()
        
        switch assetWriter!.status {
        case .cancelled:
            print("Cancelled")
        case .unknown:
            print("Unknown")
        case .writing:
            print("writing")
        case .failed:
            print("failed")
        case .completed:
            print("completed")
        }
        
        assetWriter!.startSession(atSourceTime: kCMTimeZero)
        switch assetWriter!.status {
        case .cancelled:
            print("Cancelled")
        case .unknown:
            print("Unknown")
        case .writing:
            print("writing")
        case .failed:
            print("failed")
        case .completed:
            print("completed")
        }
        
        if (writerInput.isReadyForMoreMediaData ) {
            print("ready for more data") //ISSUE
        }
        else {
            print("not ready for more data")
        }
        
        let numberOfSecondsPerFrame = 0.1
        var frameSeconds = -1 * numberOfSecondsPerFrame
        
        for image in imageArray {
            let presentationTime = CMTime(seconds: frameSeconds, preferredTimescale: 600)
            
            guard let pixBufPool = assetWriterInputpixBufAdaptor.pixelBufferPool else {
                print("pixBufPool is nil ")
                return false
            }
            
            var pixBufOut: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixBufPool, &pixBufOut)
            if status != kCVReturnSuccess {
                fatalError("CVpixBufPoolCreatepixBuf() failed")
            }
            let pixBuf = pixBufOut!
            
            CVPixelBufferLockBaseAddress(pixBuf, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            let pixBufAddress = CVPixelBufferGetBaseAddress(pixBuf)
            let color = CGColorSpaceCreateDeviceRGB()
            
            let cgContext = CGContext(data: pixBufAddress, width: mult16width, height: mult16height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: 4*mult16width, space: color, bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue, releaseCallback: nil, releaseInfo: nil)

            let rectToClear = CGRect(x: 0, y: 0, width: mult16width, height: mult16height)
            cgContext?.clear(rectToClear)
            cgContext?.draw(image, in: rectToClear, byTiling: false)
            CVPixelBufferUnlockBaseAddress(pixBuf, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            assetWriterInputpixBufAdaptor.append(pixBuf, withPresentationTime: presentationTime)
            
            frameSeconds += numberOfSecondsPerFrame
        }
        
        duration = round(numberOfSecondsPerFrame * Double(numberOfImages) * 1000.0 / 1000.0)
        
        
        writerInput.markAsFinished()
        print("after mark as finished")
        assetWriter!.finishWriting {
            print("Finished Writing")
            switch assetWriter!.status {
            case .cancelled:
                print("Cancelled")
            case .unknown:
                print("Unknown")
            case .writing:
                print("writing")
            case .failed:
                print("failed")
            case .completed:
                print("completed")
            }
        }
        print("after finish writing")
        
        return true
    }
}
