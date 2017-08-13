//
//  Cloud.swift
//  GIF_Tracks_3
//
//  Created by Nihar Agrawal on 8/12/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import Foundation
import CloudKit
import FacebookCore
import FacebookShare

var publicDB : CKDatabase!

func saveToPublicDB() {
    print("in saveToPublicDB")
    let cloudContainer = CKContainer.default()
    publicDB = cloudContainer.publicCloudDatabase
    
    
    let gifMovieRecord = CKRecord(recordType: "GIFMovie")
    let currentFacebookID = AccessToken.current?.userId
    gifMovieRecord.setObject(currentFacebookID as CKRecordValue?, forKey: "facebookID")
    
    let gifMovieAssetURL = NSTemporaryDirectory() + "newmovie.mp4"
    let gifMovieAsset = CKAsset(fileURL: URL(fileURLWithPath: gifMovieAssetURL))
    gifMovieRecord.setObject(gifMovieAsset, forKey: "movie")
    
    publicDB.save(gifMovieRecord) { (record, error) in
        if (error != nil) {
            print("Record not saved")
            print("\(error?.localizedDescription)")
        }
        else {
            print("\(record?["recordName"])")
            print("Record successfully uploaded")
        }
    }
    
    getFriendsMovies()
    return
}

func getFriendsMovies() {
    
    var friendList = NSMutableArray()
    for friend in friendsDictionary.keys {
        friendList.add(friend)
        print("\(friend)")
    }
    
    let predicate = NSPredicate(format: "%K IN %@", "facebookID", friendList)
    let friendsMoviesQuery = CKQuery(recordType: "GIFMovie", predicate: predicate)
    
    //can upgrade to NSOperationQuery or whatever it is
    publicDB.perform(friendsMoviesQuery, inZoneWith: nil) { (results, error) in
        print("Found \(results?.count) results")
    }
}
