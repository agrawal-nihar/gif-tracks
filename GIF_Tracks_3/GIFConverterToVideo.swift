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
    var imageSize : CGSize
    var outputFilePath : String
    var outputSettings : [String: Any]
    var sourcePixelAttributesDictionary : [String : NSNumber]
    var secondsPerFrame : Double
    var numberOfImages : Int
    var imageArray : [CGImage]
    
    
    init( _ sourcePath: String, _ outputPath:String, _ frameTimeInterval:Double, _ images: [CGImage], _ numImages : Int) {
        GIFSourceFilePath = sourcePath
        outputFilePath = outputPath
        secondsPerFrame = frameTimeInterval
        imageArray = images
        numberOfImages = numImages
        imageSize = CGSize(width: 0, height: 0) //default
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
        print("Found \(numberOfImages) images")
        imageSize = CGSize(width: floor(CGFloat(imageArray[0].width) / 16) * 16, height: floor(CGFloat(imageArray[0].height) / 16) * 16)
        
        outputSettings =  [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber(value: Float(imageSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(imageSize.height)),
        ]
        sourcePixelAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(imageSize.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(imageSize.height))
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
        imageSize = CGSize(width: floor(CGFloat(imageArray[0].width) / 16) * 16, height: floor(CGFloat(imageArray[0].height) / 16) * 16)
        
        outputSettings =  [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber(value: Float(imageSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(imageSize.height)),
        ]
        sourcePixelAttributesDictionary = [
            kCVpixBufPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVpixBufWidthKey as String: NSNumber(value: Float(imageSize.width)),
            kCVpixBufHeightKey as String: NSNumber(value: Float(imageSize.height))
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
        // let frameTime = CMTimeMake(Int64(frameCount*frameDuration),Int32(fps));
        
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
           // let cgContext = CGContext(data: pixBufAddress, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixBuf), space: color, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
            let imagePixelWidth = Int(image.width)
            let imagePixelHeight = Int(image.height)
            //create bitmap context
            print("Bytes per row: \(CVPixelBufferGetBytesPerRow(pixBuf))")
            print("Color space/Components: \(color)")
            let cgContext = CGContext(data: pixBufAddress, width: imagePixelWidth, height: imagePixelHeight, bitsPerComponent: 5, bytesPerRow: CVPixelBufferGetBytesPerRow(pixBuf), space: color, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue, releaseCallback: nil, releaseInfo: nil)

            //cgContext!.clear(CGRect(x: 0, y: 0, width: image.width, height: imageSize.height))
            cgContext!.clear(CGRect(x: 0, y: 0, width: imagePixelWidth, height: imagePixelHeight))

            
            //let uiimageversion = UIImage(cgImage: image)
            //let horizontalRatio = imageSize.width / uiimageversion.size.width
            //let verticalRatio = imageSize.height / uiimageversion.size.height
            //let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
            //let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
            
            //for image itself use widths and height that originate as CGFloat values
            //let adjustedSize = CGSize(width: uiimageversion.size.width * aspectRatio, height: uiimageversion.size.height * aspectRatio)
            
            //centers new image in frame range
            //let x = adjustedSize.width < imageSize.width ? (imageSize.width - adjustedSize.width) / 2 : -(adjustedSize.width-imageSize.width)/2
            //let y = adjustedSize.height < imageSize.height ? (imageSize.height - adjustedSize.height) / 2 : -(adjustedSize.height-imageSize.height)/2
            
            // context!.draw(uiimageversion.cgImage!, in: CGRect(x:, y:y, width:adjustedSize.width, height:adjustedSize.height))
            //cgContext!.draw(uiimageversion.cgImage!, in: CGRect(x:x, y:y, width:adjustedSize.width, height:adjustedSize.height))
            let gifRectangle = CGRect(x: Int(CGFloat(image.width) * CGFloat(0.5) / 2), y: Int(CGFloat(image.height) * CGFloat(0.5) / 2), width: Int(CGFloat(image.width) * CGFloat(0.5)) , height: Int(CGFloat(image.height) * CGFloat(0.5)))
            cgContext!.draw(image, in: gifRectangle, byTiling: false)
            CVPixelBufferUnlockBaseAddress(pixBuf, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            assetWriterInputpixBufAdaptor.append(pixBuf, withPresentationTime: presentationTime)
            
            frameSeconds += numberOfSecondsPerFrame
        }
        
        
        /* for image in imageArray {
         let presentationTime = CMTime(seconds: frameSeconds, preferredTimescale: 600)
         
         let pixBufPool = assetWriterInputpixBufAdaptor.pixBufPool
         if (pixBufPool != nil) {
         print("pixel buffer pool is not null")
         }
         
         var pixBufOut: CVpixBuf?
         let status = CVpixBufPoolCreatepixBuf(kCFAllocatorDefault, pixBufPool!, &pixBufOut)
         let pixBuf = pixBufOut!
         
         assetWriterInputpixBufAdaptor.append(pixBuf, withPresentationTime: presentationTime)
         
         frameSeconds += numberOfSecondsPerFrame
         } */
        
        duration = round(numberOfSecondsPerFrame * Double(numberOfImages) * 1000.0 / 1000.0)
        
        
        writerInput.markAsFinished()
        print("after mark as finished")
        //HOOK UP TO PHONE AND TRY BGRA OR OTHER PIXEL FORMAT, MAYBE A SIMULATOR ISSUE
        assetWriter!.finishWriting { //issue
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
        //assetWriter!.endSession(atSourceTime: frameTime) //necessary
        
        return true
    }
    
        
        /*
        let assetWriterInputpixBufAdaptor = AVAssetWriterInputpixBufAdaptor(assetWriterInput: writerInput, sourcepixBufAttributes: sourcePixelAttributesDictionary)
        
        print("\(outputFilePath)")
        let assetWriterInitErr = assetWriter!.canAdd(writerInput) ? "Input is compatible" : "Input to writer is not compatible"
        print("\(assetWriterInitErr)")
        assert(assetWriter!.canAdd(writerInput))
        assetWriter!.add(writerInput)
        assetWriter!.startWriting()
        
        
        let writerInputMoreDataErr = writerInput.isReadyForMoreMediaData ? "Ready for more data" : "Not ready for more data"
        print("\(writerInputMoreDataErr)")
        
        print("\(printAssetWriterStatus(&(assetWriter!)))")
        assetWriter!.startSession(atSourceTime: kCMTimeZero)
        print("\(printAssetWriterStatus(&(assetWriter!)))")
        
        if (writerInput.isReadyForMoreMediaData ) {
            print("ready for more data")
        }
        
        var frameSeconds = -1 * secondsPerFrame
        
        for i in 0..<numberOfImages {
            //let cgImage = imageArray[i]
            let presentationTime = CMTime(seconds: frameSeconds, preferredTimescale: 600)
            
            guard let pixBufPool = assetWriterInputpixBufAdaptor.pixBufPool else {
                print("pixBufPool is nil ")
                return false
            }
            //let pixBuf = pixBufFromImage(image: image, pixBufPool: pixBufPool, size: videoSize)
            //func pixBufFromImage(image: UIImage, pixBufPool: CVpixBufPool, size: CGSize) -> CVpixBuf {
            
            var pixBufOut: CVpixBuf?
            let status = CVpixBufPoolCreatepixBuf(kCFAllocatorDefault, pixBufPool, &pixBufOut)
            if (status != kCVReturnSuccess) {
                return false
            }
            let pixBuf = pixBufOut!
            
            CVpixBufLockBaseAddress(pixBuf, CVpixBufLockFlags(rawValue: CVOptionFlags(0)))
            
            let data = CVpixBufGetBaseAddress(pixBuf)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: data, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: CVpixBufGetBytesPerRow(pixBuf), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
            
            context!.clear(CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            
            let uiimageversion = UIImage(cgImage: imageArray[i])
            let horizontalRatio = imageSize.width / uiimageversion.size.width
            let verticalRatio = imageSize.height / uiimageversion.size.height
            let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
            //let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
            
            //for image itself use widths and height that originate as CGFloat values
            let adjustedSize = CGSize(width: uiimageversion.size.width * aspectRatio, height: uiimageversion.size.height * aspectRatio)
            
            //centers new image in frame range
            let x = adjustedSize.width < imageSize.width ? (imageSize.width - adjustedSize.width) / 2 : -(adjustedSize.width-imageSize.width)/2
            let y = adjustedSize.height < imageSize.height ? (imageSize.height - adjustedSize.height) / 2 : -(adjustedSize.height-imageSize.height)/2
            
            //        context!.draw(uiimageversion.cgImage!, in: CGRect(x:, y:y, width:adjustedSize.width, height:adjustedSize.height))
            
            context!.draw(uiimageversion.cgImage!, in: CGRect(x:x, y:y, width:adjustedSize.width, height:adjustedSize.height))
            CVpixBufUnlockBaseAddress(pixBuf, CVpixBufLockFlags(rawValue: CVOptionFlags(0)))
            
            assetWriterInputpixBufAdaptor.append(pixBuf, withPresentationTime: presentationTime)
            
            frameSeconds += secondsPerFrame
        }
        
        
        /* for image in imageArray {
         let presentationTime = CMTime(seconds: frameSeconds, preferredTimescale: 600)
         
         let pixBufPool = assetWriterInputpixBufAdaptor.pixBufPool
         if (pixBufPool != nil) {
         print("pixel buffer pool is not null")
         }
         
         var pixBufOut: CVpixBuf?
         let status = CVpixBufPoolCreatepixBuf(kCFAllocatorDefault, pixBufPool!, &pixBufOut)
         let pixBuf = pixBufOut!
         
         assetWriterInputpixBufAdaptor.append(pixBuf, withPresentationTime: presentationTime)
         
         frameSeconds += numberOfSecondsPerFrame
         } */
        
        duration = round(secondsPerFrame * Double(numberOfImages) * 1000.0 / 1000.0)
        
        writerInput.markAsFinished()
        assetWriter!.finishWriting {
            print("Finished Writing")
        }
        //assetWriter!.endSession(atSourceTime: frameTime) //necessary??
        
        slider.maximumValue = Float(duration)
        imageCarousel.image = UIImage(cgImage: imageArray[0])
        if (printAssetWriterStatus(&(assetWriter!)) == "failed") {
            return false
        }
        
        return true
    }
    
    
    private func printAssetWriterStatus(_ assetWriter : inout AVAssetWriter) -> String {
        switch assetWriter.status {
        case .cancelled:
            return "Cancelled"
        case .unknown:
            return "Unknown"
        case .writing:
            return "writing"
        case .failed:
            return "failed"
        case .completed:
            return "completed"
        }
    } */
    
} //end of class
