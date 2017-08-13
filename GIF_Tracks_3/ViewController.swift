//
//  ViewController.swift
//  AV Framework Test
//
//  Created by Nihar Agrawal on 6/1/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreAudio
import CoreVideo
import CoreMedia
import ImageIO
import MobileCoreServices
import Photos

import FacebookLogin


protocol DismissModalViewControllerDelegate: class {
    func dismissModalViewController(sender: ImageLoadingViewController)
}

//check against Apple guide and Ray Wenderlich ****
class ViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet var slider : UISlider?
    @IBOutlet var imageCarousel : UIImageView!
    
    var audioProcessor : AudioProcessor!
    var updateSliderTimer: Timer!
    var imageToSet : UIImage? = nil
    var imageArray : [CGImage] = []
    var numberOfImages : Int = 0
    var duration: Double = 0.0
    var temporaryDirectoryPath: String = ""
    var currValue : Float = 0.0
    
    var imageSelector : UIGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider!.value = 0.0
        if let image = imageToSet {
            imageCarousel!.image = image
        }
        else {
            imageCarousel.image = UIImage(named: "homepage")
        }
        imageCarousel.contentMode = UIViewContentMode.scaleAspectFit
        
        //manages already logged in user automatically
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .userFriends ])
        loginButton.center = view.center
        //loginButton.delegate = self
        view.addSubview(loginButton)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleGesture(gestureRecognizer: UIGestureRecognizer) {
        let imageLoadingViewController = ImageLoadingViewController()
        self.present(imageLoadingViewController, animated: true) {
            print("Presenting images from selector")
        }
    }
    
    private func clearTemporaryDirectory() {
        var tempDirectoryContents : [String]
        let fileManager = FileManager()
        do {
            try tempDirectoryContents = fileManager.contentsOfDirectory(atPath: NSTemporaryDirectory())
        }
        catch {
            print("Temporary Directory was empty")
            return
        }
        
        for filePath in tempDirectoryContents {
            print("\(filePath)")
            do {
                let pathToRemove = NSTemporaryDirectory() + filePath
                try fileManager.removeItem(atPath: pathToRemove)
            }
            catch {
                print("\(filePath) was empty, returning early")
                return
            }
        }
        
    }
    
    //link to audio in temp directory!!!!!
    @IBAction func joinAudioVideo() {
        let audioVideoJoiner = AudioVideoJoiner(videoAt: "newmovie.mp4", audioAt: "audioRecorded.caf", outputAt: "movie.mp4", outputWith: AVFileTypeMPEG4, forNetworks: true)
        audioVideoJoiner.join()
        
    }
    
    @IBAction func exportToPhotos() {
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges({
            let outputFilePath = NSTemporaryDirectory() + "movie.mp4"
            let videoURL = URL(fileURLWithPath: outputFilePath)
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { (success, error) in
            print("\(success): in exporting video to Photos")
            if let error = error {
                print("\(error)")
            }
            else {
                print("No errors with exporting to Photos")
            }
        }
        
    }
    
    //reset to original, regardless of state
    @IBAction func cancelComposition() {
        clearTemporaryDirectory()
        //reset slider
        currValue = 0.0
        slider!.setValue(currValue, animated: true)
        imageArray = []
        numberOfImages = 0
        duration = 0.0
        temporaryDirectoryPath = ""
        imageToSet = nil
        
        //@IBOutlet var imageCarousel : UIImageView!
        //reset imageview
    }
    
    func convertGIFToVideo() -> Void {
        let pathToSave = NSTemporaryDirectory() + "sourceGIF.gif"
        let videoPath = NSTemporaryDirectory() + "newmovie.mp4"
        let frameTimeInterval = 0.1
        
        let converter = GIFConverterToVideo(pathToSave, videoPath, frameTimeInterval, imageArray, numberOfImages)
        let success = converter.doConvertGIFtoVideo()
        print("Converting to video: \(success)")
        numberOfImages = converter.numberOfImages
        
        for counter in 0..<numberOfImages {
            imageArray.append(converter.imageArray[counter])
        }
        let duration = converter.duration
        
        slider!.maximumValue = Float(duration)
        //imageCarousel!.image = UIImage(cgImage: imageArray[0])
        return
    }
    
    
    @IBAction func getSound() {
        //fix with global class structure
        //let updateSliderMethod = CADisplayLink(target: slider!, selector: NSSelectorFromString("updateSlider"))
        //updateSliderMethod.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        //updateSliderMethod.preferredFramesPerSecond = 1
        
        let audioPath = NSTemporaryDirectory() + "audioRecorded.caf"
        audioProcessor = AudioProcessor(saveAudioTo: audioPath, timeToRecord: 10)
        
        //imageCarousel = UIImageView(image: UIImage(cgImage: imageArray[0]))
        
        var uiImageArray : [UIImage] = []
        for counter in 0..<numberOfImages {
            uiImageArray.append(UIImage(cgImage: imageArray[counter]))
        }
        
        imageCarousel!.animationImages = uiImageArray
        imageCarousel!.animationDuration = Double(numberOfImages) * 0.1
        imageCarousel!.animationRepeatCount = 1
        imageCarousel!.startAnimating()
        updateSliderTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
        audioProcessor.record()
        print("After audio processor record")
        
    }
    
    @objc func updateSlider() {
        if (currValue < 10.0) {
            slider!.setValue(currValue + 0.1, animated: true)
            currValue += 0.1
        }
        else {
            //audioProcessor.stop()
            //investigate this!!!
            updateSliderTimer.invalidate()
            //try! avAudioSession.setActive(false) ADDD BACK
        }
    }
}

extension ViewController: DismissModalViewControllerDelegate {
    func dismissModalViewController(sender: ImageLoadingViewController) {
        print("IN IMPLEMENTATION OF DELEGATE")
        self.dismiss(animated: true) {
            print("Dismissing images")
        }
        
        let pathToSave = NSTemporaryDirectory() + "sourceGIF.gif"
        let imageDataURL = NSURL.fileURL(withPath: pathToSave)
        let imageData = try! Data(contentsOf: imageDataURL as URL)
        print("in prepare function")
        let gifImages = CGImageSourceCreateWithData(NSData(data: imageData), nil)
        if (Int(CGImageSourceGetCount(gifImages!)) > 0) {
            print("More than one image")
            /*guard let cgImage = CGImageSourceCreateImageAtIndex(gifImages!, 0, nil) else {
             fatalError("Could not create GIF preview")
             }
             let image = UIImage(cgImage: cgImage)
             imageCarousel = UIImageView(image: image) */
            
            imageCarousel!.image = UIImage(cgImage: CGImageSourceCreateImageAtIndex(gifImages!, 0, nil)!)
        }
        
        self.convertGIFToVideo()
    }
}

//DIFFERENTIATE, just var names structure of if
extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Preparing for segue")
        if let destination = segue.destination as? UINavigationController, let imageLoadingVC = destination.topViewController as? ImageLoadingViewController {
            imageLoadingVC.delegate = self
        }
    }
}

extension ViewController {
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
    }
}

/*
 let mutableComposition = AVMutableComposition()
 let filename = "newmovie.mp4"
 let videoPath = NSTemporaryDirectory() + filename
 
 //use do-try-catch blocks later
 //for video in filemanager
 let videoURL = URL(fileURLWithPath: videoPath)
 let videoExists = FileManager.default.fileExists(atPath: videoURL.path)
 assert(videoExists)
 let videoAsset = AVAsset(url: videoURL)
 
 
 //for audio in filemanager
 let audioPath = NSTemporaryDirectory() + "audioRecorded.caf"
 let audioURL = URL(fileURLWithPath: audioPath)
 let audioExists = FileManager.default.fileExists(atPath: audioURL.path)
 
 if (audioExists) {
 print("Audio File Exists")
 }
 else {
 print("Audio File Does Not Exist")
 }
 let audioAsset = AVAsset(url: audioURL)
 
 //??? Changed from sheet
 /*for assetTrack in videoAsset.tracks {
 print("\(assetTrack.timeRange)")
 } */
 let videoAssetTrack = videoAsset.tracks[0] as AVAssetTrack
 
 let audioAssetTrack = audioAsset.tracks[0] as AVAssetTrack //not sure about this
 //audioAssetTrack.mediaType = AVMediaTypeAudio
 //audioAssetTrack.trackID = kCMPersistentTrackID_Invalid
 
 //new stuff
 let videoCompTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
 do {
 try videoCompTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration), of: videoAssetTrack, at: kCMTimeZero)
 }
 catch {
 print(error.localizedDescription)
 print("Error in inserting video track into videoCompTrack")
 }
 
 
 let audioCompTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
 do {
 try audioCompTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration), of: audioAssetTrack, at: kCMTimeZero)
 }
 catch {
 print(error.localizedDescription)
 print("Error in inserting audio track into audioCompTrack")
 }
 
 //wrap in try/catch block or do T/F return value check??
 //or use Asset.duration ??
 
 /* rendering and frames
 let videoWidth = videoAssetTrack.naturalSize.width
 let videoHeight = videoAssetTrack.naturalSize.height
 mutableComposition.renderSize = CGSizeMake(videoWidth, videoHeight) //need video composition for this
 mutableComposition.frameDuration = CMTimeMake(1,30) */
 
 //export session
 
 //for type in AVAssetExportSession.exportPresets(compatibleWith: mutableComposition) {
 //print("\(type)")
 //}
 
 let exportSessionWithMutableComposition = AVAssetExportSession(asset: mutableComposition, presetName: "AVAssetExportPresetHighestQuality")
 
 if (exportSessionWithMutableComposition == nil) {
 print("Export Sesion is nil")
 }
 
 //FIX THIS!!!!!
 let outputFilePath = NSTemporaryDirectory() + "movie.mp4"
 exportSessionWithMutableComposition!.outputURL = URL(fileURLWithPath: outputFilePath)
 
 /*for filetype in (exportSessionWithMutableComposition?.supportedFileTypes)! {
 print("\(filetype)")
 } */
 
 exportSessionWithMutableComposition!.outputFileType = AVFileTypeMPEG4
 exportSessionWithMutableComposition!.shouldOptimizeForNetworkUse = true
 
 //DON’T INCLUDE: exportSessionWithMutableComposition.videoComposition = videoComp
 //FIX THIS
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
 
 /* if (exportSessionWithMutableComposition?.error) != nil {
 print("\(exportSessionWithMutableComposition?.error! ?? "None" as! Error)")
 } */
 
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
 
 } */



//converts GIF to vid
/*
 @IBAction func convertsGIFtoVid()
 {
 
 let filename = "sourceGIF.gif"
 let sourceGIFPath = NSTemporaryDirectory() + filename
 
 let imageDataURL = NSURL.fileURL(withPath: sourceGIFPath)
 let imageData = try! Data(contentsOf: imageDataURL as URL)
 let gifImages = CGImageSourceCreateWithData(NSData(data: imageData), nil)
 
 /*
 let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: imageData.count)
 let bufferPointer = UnsafeMutableBufferPointer(start: buffer, count: imageData.count)
 imageData.copyBytes(to: bufferPointer)
 let imageCFData = CFDataCreate(kCFAllocatorDefault, buffer, imageData.count)
 let gifImages = CGImageSourceCreateWithData(imageCFData!, nil)
 */
 
 numberOfImages = Int(CGImageSourceGetCount(gifImages!))
 print("Number of Images: \(numberOfImages)")
 
 //var imageArray : [CGImage] = []
 for imageIndex in 0..<numberOfImages {
 let imageToPlace = CGImageSourceCreateImageAtIndex(gifImages!, imageIndex, nil)
 if let imageforArray = imageToPlace {
 imageArray.append(imageforArray) //need to check for nil return value of initializer?
 }
 else {
 print("Error in loading image \(imageIndex)")
 }
 //CGImageRelease(imageToPlace!)
 }
 
 
 //let cgDataProviderRef = imageArray[0].dataProvider
 //let cfDataRef = cgDataProviderRef!.data
 //assert(cfDataRef != nil)
 //let cfDataByte = CFDataGetBytePtr(cfDataRef!)
 //let dataByte = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 1)
 //dataByte.storeBytes(of: cfDataByte!.pointee, as: UInt8.self)
 
 //let bytesPerRow = imageArray[0].bytesPerRow
 //let cfDataProviderRef = imageArray[0].dataProvider
 //var cfData = cfDataProviderRef!.data
 
 //kCVPixelFormatType_422YpCbCr8
 /* let pixelBufferAttributeDictionary = [
 kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB ,
 kCVPixelBufferWidthKey as String : NSNumber(value: Float(imageArray[0].width)),
 kCVPixelBufferHeightKey as String : NSNumber(value: Float(imageArray[0].height)),
 kCVPixelBufferCGImageCompatibilityKey as String : true as NSNumber
 ] as CFDictionary */
 
 //let pixelBufferAttributeDictionary = CFDictionaryCreate(kCFAllocatorDefault, pixelBufferAttributeDictionaryKeys, pixelBufferAttributeDictionaryValues, numValues, nil, nil)
 
 //let p_CVPixelBufferOut = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: numberOfImages)
 //CVPixelBufferCreateWithBytes(kCFAllocatorDefault, imageArray[0].width, imageArray[0].height, kCVPixelFormatType_32ARGB, &cfData, bytesPerRow, nil, nil, pixelBufferAttributeDictionary, p_CVPixelBufferOut)
 
 //would this approach work???
 //they made pixel buffer from pixel buffer pool
 //for i in 0..<numberOfImages {
 //let string = "\(i)"
 //let cfstring: CFString = string as NSString
 //CVBufferSetAttachment(p_CVPixelBufferOut.pointee!, cfstring, imageArray[i], .shouldPropagate)
 //}
 
 let imageSize = CGSize(width: floor(CGFloat(imageArray[0].width) / 16) * 16, height: floor(CGFloat(imageArray[0].height) / 16) * 16)
 
 
 //check if file already exists at path
 
 //change back to temporary path
 let moviePath = NSTemporaryDirectory() + "newmovie.mp4"
 let assetWriter = try? AVAssetWriter(url: URL(fileURLWithPath: moviePath), fileType: AVFileTypeMPEG4)
 
 if (assetWriter == nil) {
 print("Error in initializing asset writer")
 }
 
 //let vidCompPropertiesKeyDictionary = [
 //AVVideoAverageBitRateKey : NSNumber(value: 128.0*1024.0)
 //]
 
 let outputSettings : [String: Any] =  [
 AVVideoCodecKey: AVVideoCodecH264,
 AVVideoWidthKey: NSNumber(value: Float(imageSize.width)),
 AVVideoHeightKey: NSNumber(value: Float(imageSize.height)),
 ]
 
 //let p_CMVideoFormat = UnsafeMutablePointer<CMVideoFormatDescription?>.allocate(capacity: 1)
 //CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, p_CVPixelBufferOut.pointee!, p_CMVideoFormat)
 let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
 
 let assetWriterInitErr = assetWriter!.canAdd(writerInput) ? "Input is compatible" : "Input to writer is not compatible"
 print("\(assetWriterInitErr)")
 writerInput.expectsMediaDataInRealTime = true
 assert(assetWriter!.canAdd(writerInput))
 assetWriter!.add(writerInput)
 
 let writerInputMoreDataErr = writerInput.isReadyForMoreMediaData ? "Ready for more data" : "Not ready for more data"
 print("\(writerInputMoreDataErr)")
 
 let sourcePixelAttributesDict = [
 kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
 kCVPixelBufferWidthKey as String: NSNumber(value: Float(imageSize.width)),
 kCVPixelBufferHeightKey as String: NSNumber(value: Float(imageSize.height))
 ]
 
 let assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelAttributesDict)
 
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
 
 let numberOfSecondsPerFrame = 0.1
 // let frameTime = CMTimeMake(Int64(frameCount*frameDuration),Int32(fps));
 
 var frameSeconds = -1 * numberOfSecondsPerFrame
 
 for i in 0..<numberOfImages {
 //let cgImage = imageArray[i]
 let presentationTime = CMTime(seconds: frameSeconds, preferredTimescale: 600)
 
 guard let pixelBufferPool = assetWriterInputPixelBufferAdaptor.pixelBufferPool else {
 print("pixelBufferPool is nil ")
 return
 }
 //let pixelBuffer = pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferPool, size: videoSize)
 //func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
 
 var pixelBufferOut: CVPixelBuffer?
 let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
 if status != kCVReturnSuccess {
 fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
 }
 let pixelBuffer = pixelBufferOut!
 
 CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
 
 let data = CVPixelBufferGetBaseAddress(pixelBuffer)
 let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
 let context = CGContext(data: data, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
 
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
 CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
 
 assetWriterInputPixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
 
 frameSeconds += numberOfSecondsPerFrame
 }
 
 
 /* for image in imageArray {
 let presentationTime = CMTime(seconds: frameSeconds, preferredTimescale: 600)
 
 let pixelBufferPool = assetWriterInputPixelBufferAdaptor.pixelBufferPool
 if (pixelBufferPool != nil) {
 print("pixel buffer pool is not null")
 }
 
 var pixelBufferOut: CVPixelBuffer?
 let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool!, &pixelBufferOut)
 let pixelBuffer = pixelBufferOut!
 
 assetWriterInputPixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
 
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
 
 slider!.maximumValue = Float(duration)
 imageCarousel!.image = UIImage(cgImage: imageArray[0])
 } // end of function
 */

//works, backup in updated?
//note: if stops working, do record then stop and wait for at least 10 sec






//end of class

/*
 public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
 {
 let mediaType = info[UIImagePickerControllerMediaType]
 print("Entered imagePickerController function")
 print("\(mediaType!)")
 if (mediaType as! NSString == kUTTypeImage as NSString) {
 print("OK in getting media source type")
 }
 else {
 print("Selected image is NOT Image")
 }
 
 guard let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
 print("Something went wrong")
 return
 }
 
 let selectedImage : Data? = UIImagePNGRepresentation(originalImage)
 guard let imageForSaving = selectedImage else {
 print("Something went wrong in getting PNG Representatino of image")
 return
 }
 
 let pathToSave = NSTemporaryDirectory() + "sourceGIF.gif"
 do {
 try (imageForSaving as NSData).write(to: URL(fileURLWithPath: pathToSave), options: .atomic)
 } catch {
 print("Error in saving image to temporary directory")
 }
 
 //check
 let gifImages = CGImageSourceCreateWithData(selectedImage! as CFData, nil)
 numberOfImages = Int(CGImageSourceGetCount(gifImages!))
 print("Number of Images: \(numberOfImages)")
 
 //let
 //let fetchResult = PHAssetCollection.fetchAssetCollections(
 
 /*
 if let mediaPath = info[UIImagePickerControllerReferenceURL] {
 mediaPathToReturn = (mediaPath as! NSURL)
 print("\(mediaPathToReturn!)")
 }
 else {
 print("No Media URL :(")
 } */
 // Handle a still image picked from a photo album
 //if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
 
 picker.dismiss(animated: true) //add completion handler to pass info?
 print("done with image picker controller")
 }
 
 
 */



//    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//picker.dismiss(animated: true)
//}
//deprecated version to select image
/*    var mediaPath : NSURL?
 @IBAction func chooseImage() {
 let imagePicker = UIImagePickerController()
 imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
 
 let availableSourceTypes = UIImagePickerController.availableMediaTypes(for: imagePicker.sourceType)
 var gifAccepted : Bool = false
 for element in availableSourceTypes! {
 print("\(element)")
 }
 if let sourceTypes = availableSourceTypes {
 print("source types found")
 if sourceTypes.contains(kUTTypeImage as String) {
 print("gif accepted is true")
 gifAccepted = true
 }
 else {
 print("gif accepted is false")
 gifAccepted = false
 }
 }
 else {
 print("Error in getting available source types")
 }
 
 if (gifAccepted) {
 imagePicker.mediaTypes = [kUTTypeImage as String]
 }
 else {
 print("GIF Not Accepted")
 }
 imagePicker.delegate = self
 imagePicker.allowsEditing = false
 
 present(imagePicker, animated: true) {
 print("Finished presenting camera roll picker")
 }
 
 //ADD BACK!!
 //let mediaPath = delegateToAssign.mediaPathToReturn!
 //print("\(mediaPath)")*/

//declare global variable

/* WHY AINT THIS WORKING
 class modSlider: UISlider {
 //var duration : Double
 var minValue : Float
 var maxValue : Float
 var currValue : Float
 var username : String
 var anInt : Int
 
 init(_ duration : Double, _ minimumValue : Float, _ maximumValue : Float) {
 let result = super.init(coder: NSCoder())
 if (result)
 {        minValue = minimumValue
 maxValue = maximumValue
 //self.duration = duration
 currValue = 0.0
 super.value = 0.0
 }
 
 }
 
 required init?(coder aDecoder: NSCoder) {
 //uper.init(coder: aDecoder)! //is optional, see notes below
 self.username = aDecoder.decodeObject(forKey: "username") as! String
 self.anInt = aDecoder.decodeInteger(forKey: "anInt")
 }
 
 func encodeWithCoder(aCoder: NSCoder) {
 // super.encodeWithCoder(aCoder) is optional, see notes below
 aCoder.encode(self.username, forKey: "username")
 aCoder.encode(self.anInt, forKey: "anInt")
 }
 
 @objc public func updateSlider() {
 super.setValue(currValue + 1.0, animated: true)
 currValue = currValue + 1.0
 } */
