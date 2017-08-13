//
//  PhotoCell.swift
//  myGIFproject
//
//  Created by Nihar Agrawal on 7/23/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    var leftVerticalView : UIView!
    var rightVerticalView : UIView!
    var leftHorizontalView : UIView!
    var rightHorizontalView : UIView!
    
    public func applySelectionFormat(cellRect rect : CGRect, betweenCells frameSpace : CGFloat)
    {
        let verticalBorderSize = CGSize(width: frameSpace/2, height: rect.height)
        let horizontalBorderSize = CGSize(width: rect.width, height: frameSpace/2)
        
        let leftVerticalOrigin = CGPoint(x: 0, y: 0)
        let rightVerticalOrigin = CGPoint(x: rect.width - frameSpace/2, y: 0)
        let topHorizontalOrigin = CGPoint(x: 0, y: 0)
        let bottomHorizontalOrigin = CGPoint(x: 0, y: rect.height-frameSpace/2)
        
        let leftVerticalRect = CGRect(origin: leftVerticalOrigin, size: verticalBorderSize)
        let rightVerticalRect = CGRect(origin: rightVerticalOrigin, size: verticalBorderSize)
        let leftHorizontalRect = CGRect(origin: topHorizontalOrigin, size: horizontalBorderSize)
        let rightHorizontalRect = CGRect(origin: bottomHorizontalOrigin, size: horizontalBorderSize)

        leftVerticalView = UIView(frame: leftVerticalRect)
        rightVerticalView = UIView(frame: rightVerticalRect)
        leftHorizontalView = UIView(frame: leftHorizontalRect)
        rightHorizontalView = UIView(frame: rightHorizontalRect)
        
        leftVerticalView.backgroundColor = UIColor.blue
        rightVerticalView.backgroundColor = UIColor.blue
        leftHorizontalView.backgroundColor = UIColor.blue
        rightHorizontalView.backgroundColor = UIColor.blue

        imageView.addSubview(leftVerticalView)
        imageView.addSubview(rightVerticalView)
        imageView.addSubview(leftHorizontalView)
        imageView.addSubview(rightHorizontalView)
        
    }
    
    public func removeSelectionFormat() {
        leftVerticalView.removeFromSuperview()
        rightVerticalView.removeFromSuperview()
        leftHorizontalView.removeFromSuperview()
        rightHorizontalView.removeFromSuperview()

    }
    
}



/* import UIKit
 
 class PhotoCell: UICollectionViewCell {
 
 @IBOutlet weak var imageView: UIImageView!
 }
 
 */
