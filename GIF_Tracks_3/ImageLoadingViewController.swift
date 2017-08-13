//
//  ImageLoadingViewController.swift
//  myGIFproject
//
//  Created by Nihar Agrawal on 7/23/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import UIKit
import Photos

// Implemented significant additions myself: custom formatting, lazy loading, image selection (with delegate), integration with Photos kit
final class ImageLoadingViewController : UICollectionViewController {
    var delegate : ViewController? //CHANGE THIS NAME!!
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "ImageCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 25.0, left: 10.0, bottom: 25.0, right: 10.0)
    fileprivate var images = [PHAsset]()
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate var photoIndexPath : IndexPath = IndexPath()
    fileprivate let imageManager = PHImageManager()
    fileprivate var widthPerItem : CGFloat = 0
    fileprivate var photoCount : Int = 0
    fileprivate var thumbnailLimit : Int = 15
    fileprivate var currPhoto : Int = 0
    fileprivate var allPhotos : PHFetchResult<PHAsset>!

    
    //fileprivate let photoLibrary =
    let pathToSave = NSTemporaryDirectory() + "sourceGIF.gif"
    var currentSelectionMade : Bool = false
    var currentSelectionIndexPath : IndexPath = IndexPath()
    
    var contentSizeHeightReference : CGFloat = 0
    var displayedNewPage : Bool = false

}

private extension ImageLoadingViewController {
    @IBAction func handleImageSelection(sender: UIBarButtonItem) {
        if (delegate == nil) {
            print("delegate is nil")
        }
        print("\(photoIndexPath.item)")
        let photo = photoForIndexPath(indexPath: photoIndexPath)
        switch(photo.mediaType) {
        case .unknown: print("Unknown Asset Type")
        case .audio: print("Audio asset type")
        case .image: print("Image asset type")
        case .video: print("video asset type")
        }
        
        let optionsDict2 = PHImageRequestOptions()
        optionsDict2.isSynchronous = true
        imageManager.requestImageData(for: photo, options: optionsDict2) { (imageData, dataUTI, orientation, info) in
            print("Completion handler for image downloading")
            if let infoDict = info, let error = infoDict[PHImageErrorKey] as? NSError {
                print("\(String(describing: error.localizedDescription))")
            }
            else {
                print("No error")
            }
            
            do {
                try (imageData)?.write(to: URL(fileURLWithPath: self.pathToSave), options: .atomic)
            } catch {
                print("Error in saving image to temporary directory")
            }
            
            
        }
        
        //removed delegate?
        //    func dismissModalViewController(sender: ImageLoadingViewController) {

        delegate?.dismissModalViewController(sender: self)
    }
}
private extension ImageLoadingViewController {
    func photoForIndexPath(indexPath: IndexPath) -> PHAsset {
        print("Index for index path : \((indexPath).item)")
        return images[(indexPath).item]
    }
}

extension ImageLoadingViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized) {
            PHPhotoLibrary.requestAuthorization({ (status : PHAuthorizationStatus) in
                switch status {
                case .denied:
                    print("Denied")
                case .restricted:
                    print("Restricted")
                case .authorized:
                    print("Authorized")
                case .notDetermined:
                    print("Not Determined")
                } //end of switch
            }) //end of escaping block
        }
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", argumentArray: [PHAssetMediaType.image.rawValue])
        allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        photoCount = allPhotos.count
        
        self.loadPageOfImages(scrollViewHeight: 1.0) //dummy value thats greater than 0.0
        /* if (contentSizeHeightReference != self.collectionView!.contentSize.height ) {
            contentSizeHeightReference = self.collectionView!.contentSize.height
        } */
        
        
        /*
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", argumentArray: [PHAssetMediaType.image.rawValue])
        let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        photoCount = allPhotos.count
        
        //calculate thumbnail LIMIT!!
        
        if (allPhotos.count > 0) {
            print("Found \(allPhotos.count) photos from Camera Roll")

            //new if section
            if (allPhotos.count > thumbnailLimit) {
                currPhoto = thumbnailLimit
            }
            else {
                currPhoto = allPhotos.count
            }
            
            var toInsert = [IndexPath]() //new
            for index in 0..<currPhoto {
                print("\(index)")
                self.images.append(allPhotos.object(at: index))
                //new below
                let indexToAdd = NSIndexPath(item: index, section: 0)
                toInsert.append(indexToAdd as IndexPath)
            }
            print("Should load images")
            self.collectionView?.insertItems(at: toInsert)

            //self.collectionView?.reloadData()
            activityIndicator.removeFromSuperview()

        }
        else {
            print("Error in finding Camera Roll pictures: either found none or 0 pictures on roll")
        }
        //declare grid and populate all images, then compare selection with uti from so
    */
    }
}

private extension ImageLoadingViewController {
    func loadPageOfImages(scrollViewHeight : CGFloat) {
        /*if (scrollViewHeight == contentSizeHeightReference) {
            print("returning early")
            return
        } */
        
        print("Loading page of images")
        print("photoCount: \(photoCount) and current Photo: \(currPhoto)")
        //FIX
        /* let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        sender.addSubview(activityIndicator)
        activityIndicator.frame = sender.bounds
        activityIndicator.startAnimating() */

        
        let oldCurrPhoto = currPhoto
        currPhoto = (currPhoto + thumbnailLimit < photoCount) ? currPhoto + thumbnailLimit : photoCount
        
        //load images
        var toInsert = [IndexPath]() //new
        for index in oldCurrPhoto..<currPhoto {
            print("\(index)")
            self.images.append(allPhotos.object(at: index))
            //new below
            let indexToAdd = NSIndexPath(item: index, section: 0)
            toInsert.append(indexToAdd as IndexPath)
        }
        print("Should load images")
        self.collectionView?.insertItems(at: toInsert)
    }
}


//makes view controller conform to the UICollectionViewDataSource protocol; no explicit declaration of protocol necessary
//since this protocol is inherited from uicollectionview
extension ImageLoadingViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    //referenced https://www.raywenderlich.com/136159/uicollectionview-tutorial-getting-started for basic implementation
    //of UICollectionViewController
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! PhotoCell
        
        let photo = photoForIndexPath(indexPath: indexPath)
        //var thumbnail : UIImage?
        //var info : [AnyHashable : Any]?
        let optionsDict = PHImageRequestOptions()
        //optionsDict.version = PHImageRequestOptionsVersion.current
        optionsDict.isSynchronous = true
        optionsDict.resizeMode = PHImageRequestOptionsResizeMode.exact
        //optionsDict.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        
        cell.backgroundColor = UIColor.white
        
        let retinaMultiplier = UIScreen.main.scale
        let retinaSquare = CGSize(width: cell.imageView.bounds.size.width * retinaMultiplier, height: cell.imageView.bounds.size.height * retinaMultiplier);
        //optionsDict.normalizedCropRect = CGRect(x: 0.5 - retinaSquare.width/2, y: 0.5 - retinaSquare.height/2, width: retinaSquare.width, height: retinaSquare.height)
        optionsDict.normalizedCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)

        imageManager.requestImage(for: photo, targetSize: retinaSquare, contentMode: PHImageContentMode.aspectFill, options: optionsDict) { (result, info) in
            /* if let infoDict = info {
                var error : NSError
                error = infoDict[PHImageErrorKey] as! NSError
                print("Is there an Issue with getting thumbnail??")
                print("\(error.localizedDescription)")
            } */
            //print("Thumbnail generated")
            cell.imageView.image = result!
            cell.imageView.contentMode = UIViewContentMode.scaleAspectFill
            //cell.imageView.clipsToBounds = true

        }
        
        return cell
    }
}

extension ImageLoadingViewController {
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let visibleViewHeight = scrollView.frame.size.height
        let totalVerticalViewHeight = scrollView.contentSize.height
        let heightToReachBottom = totalVerticalViewHeight - visibleViewHeight
        contentSizeHeightReference = scrollView.contentSize.height

        if (scrollView.contentOffset.y >= CGFloat(roundf(Float(heightToReachBottom)))) {
            print("At Bottom of scrolling area")
            print("Frame Height : \(visibleViewHeight)")
            print("Content Size Height : \(totalVerticalViewHeight)")
            print("Content Offset: \(scrollView.contentOffset.y)")

            if (photoCount > 0 && currPhoto >= photoCount) {
                print("All photos loaded")
                return
            }
            else {
                self.loadPageOfImages(scrollViewHeight: scrollView.contentSize.height)
            }
            /*
                 if (contentSizeHeightReference != scrollView.contentSize.height ) {
                contentSizeHeightReference = scrollView.contentSize.height
            } */
        
            //load more images here
            return
            
        }
        
        print("Not bottom")
        print("Frame Height : \(visibleViewHeight)")
        print("Content Size Height : \(totalVerticalViewHeight)")
        print("Content Offset: \(scrollView.contentOffset.y)")

    }
}

//referenced https://www.raywenderlich.com/136159/uicollectionview-tutorial-getting-started for basic implementation
//of UICollectionViewDelegateFlowLayout
//to make view controller conform to delegate flow layout protocol
extension ImageLoadingViewController : UICollectionViewDelegateFlowLayout {
   
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

extension ImageLoadingViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.photoIndexPath = indexPath

        //set selectedBackground view here
        if let selectedCell = collectionView.cellForItem(at: indexPath), let selectedPhotoCell = selectedCell as? PhotoCell {
            if (currentSelectionMade) {
                if let currentSelection = collectionView.cellForItem(at: currentSelectionIndexPath), let currentSelectionCell = currentSelection as? PhotoCell {
                    currentSelectionCell.removeSelectionFormat()
                }
            }
            
            selectedPhotoCell.applySelectionFormat(cellRect: selectedPhotoCell.frame, betweenCells: sectionInsets.left)
            
            currentSelectionMade = true
            currentSelectionIndexPath = indexPath
        }
        else {
            return
        }

        
        /*
        (for: photo, targetSize: CGSize(width: photo.pixelWidth, height: photo.pixelHeight), contentMode: PHImageContentMode.aspectFill, options: nil) { (result, dict) in
            
                if let infoDict = dict, let error = infoDict[PHImageErrorKey] as? NSError {
                    print("\(String(describing: error.localizedDescription))")
                }
                else {
                    print("No error")
                }
                
                print("Completion handler for image downloading")
            
                guard let imageForSaving = result else {
                    print("Something went wrong in getting PNG Representatino of image")
                    return
                }
            
                let imageData = UIImageJPEGRepresentation(imageForSaving, 0.7)
                let pathToSave = NSTemporaryDirectory() + "sourceGIF.gif"
                do {
                    try (imageData)?.write(to: URL(fileURLWithPath: pathToSave), options: .atomic)
                } catch {
                    print("Error in saving image to temporary directory")
                }
        } */
    }
    
}
/*
extension ImageLoadingViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationViewController = segue.destination as! ViewController
        
        //get data behind GIF
        let imageDataURL = NSURL.fileURL(withPath: pathToSave)
        let imageData = try! Data(contentsOf: imageDataURL as URL)
        print("in prepare function")
        let gifImages = CGImageSourceCreateWithData(NSData(data: imageData), nil)
        if (Int(CGImageSourceGetCount(gifImages!)) > 0) {
            print("More than one image")
            destinationViewController.imageToSet = UIImage(cgImage: CGImageSourceCreateImageAtIndex(gifImages!, 0, nil)!)
        }
    }

} */
