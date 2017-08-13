//
//  GetUserFBFriends.swift
//  GIF_Tracks
//
//  Created by Nihar Agrawal on 8/11/17.
//  Copyright © 2017 Nihar Agrawal. All rights reserved.
//

import Foundation
import FacebookShare
import FacebookCore

//supports generation of news feed of GIFs


struct FriendsRequest: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        var dictionaryValue = [String: AnyObject]()
        
        init(rawResponse: Any?) {
            // Decode JSON from rawResponse into other properties here.
            
            let canConvertRawToJSON = JSONSerialization.isValidJSONObject(rawResponse)
            print("\(canConvertRawToJSON): can convert rawResponse to JSON")
            
            //cannot conver tto Raw Data
            /* let rawData = rawResponse as! Data
            let canConvertDataToJSON = JSONSerialization.isValidJSONObject(rawData)
            print("\(canConvertDataToJSON): can convert raw Response as data to JSON") */
    
            //let jsonData = try? JSONSerialization.data(withJSONObject: rawResponse)
            //let json = try? JSONSerialization.jsonObject(with: jsonData!, options: [])
            
            if let dataDictionary = rawResponse as? NSDictionary {
                print("Success")
                print("\(dataDictionary["summary"])")
                let friends = dataDictionary["data"] as! NSArray

                for userElement in friends {
                    let user = userElement as! [String: Any]
                    let key = user["id"] as! String
                    print("\(key)")
                    let value = user["name"] as AnyObject
                    print("\(value)")

                    dictionaryValue[key] = value
                }
                print("\(friends.count)") //only number that installed the app!!!!!!!

            }
            else {
                print("Failed at high level")
            }
        }
    
    }
    
    
    var graphPath = "/me/friends?"
    let parameters : [String : Any]? = ["fields" : "name, id"]
    let accessToken = AccessToken.current
    let httpMethod = GraphRequestHTTPMethod.GET
    var apiVersion = GraphAPIVersion.defaultVersion

}


extension ViewController {
    @IBAction func getUserFBFriends() {
        let graphRequestConnection = GraphRequestConnection()
        graphRequestConnection.networkProgressHandler = networkProgressHandler(bytesSent:totalBytesSent:totalExpectedBytes:)

        /* let request = GraphRequest(graphPath: graphPath, parameters: parameters, accessToken: accessToken, httpMethod: httpMethod)
        let response : HTTPURLResponse?
        var requestResult : GraphRequestResult<GraphRequest>
        var responseDictionary = [String : AnyObject]()

        
        request.start { (response, requestResult) in
            let networkDescription = HTTPURLResponse.localizedString(forStatusCode: (response?.statusCode)!)
            print("\(networkDescription)")
            
            responseDictionary = requestResult.dictionaryValue
        } */

        let connection = GraphRequestConnection()
        connection.add(FriendsRequest()) { response, result in
            switch result {
            case .success(let response):
                print("In success of 77")
                print("Count in dictionaryValue in View Controller: \(response.dictionaryValue["1260232664098847"])")
                //print("Custom Graph Request Succeeded: \(response)")
                //print("My facebook id is \(response.dictionaryValue?["id"])")
                //print("My name is \(response.dictionaryValue?["name"])")
                connection.cancel()

            case .failed(let error):
                print("Custom Graph Request Failed: \(error)")
                connection.cancel()

            }
            
        }
        connection.start()
        
        
        //configure connection request
        /*graphRequestConnection.add(request, batchEntryName: "fetchUserFriends") { conectionHTTPResponse, result in
            let networkDescription = HTTPURLResponse.localizedString(forStatusCode: (conectionHTTPResponse?.statusCode)!)
            print("\(networkDescription)")
            
            var responseDictionary = [String : AnyObject]()
            var response = GraphResponse(rawResponse: responseDictionary)
            if result == GraphRequestResult.success(response: response) {
                let friendsDict = response.dictionaryValue
                print("Successful")
            }
            else {
                
            }
        
    } */
        
        
    } //end of function
} //end of extension

func networkProgressHandler(bytesSent : Int64, totalBytesSent: Int64, totalExpectedBytes: Int64) -> Void {
    print("Bytes Sent: \(bytesSent)")
    print("Total Bytes Sent: \(totalBytesSent)")
    print("Total Expected Sent: \(totalExpectedBytes)")
    
    return
}
