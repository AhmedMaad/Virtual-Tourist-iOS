//
//  FlickerAPI.swift
//  Virtual Tourist
//
//  Created by Ahmed Maad on 6/16/21.
//  Copyright © 2021 Next Trend. All rights reserved.
//

import Foundation
import UIKit

class FlickerAPI{
    
    //key: 9a2e83f7864c06a9862d86e23585e527
    //Secret: a17cfd44c29edae6
    //refer to this link to get picture link i guess..: https://www.flickr.com/services/api/misc.urls.html
    
    enum Endpoint {
        case endpoint (Double, Double)
        
        var url: URL{
            return URL(string: self.stringValue)!
        }
        
        var stringValue: String{
            switch self {
            case .endpoint (let lat, let lon):
                return "https://api.flickr.com/services/rest?api_key=9a2e83f7864c06a9862d86e23585e527&method=flickr.photos.search&format=json&lat=\(lat)&lon=\(lon)&per_page=15&nojsoncallback=1&extras=url_m&page=\((1...10).randomElement() ?? 1)"
            }
        }
        
    }
    
    class func getPicsEncryptedData(lat: Double, lon: Double, completionHandler: @escaping ([Imagez], Error?)->Void){
        print("Requesting Encrypted Pics")
        let newsEndpoint = FlickerAPI.Endpoint.endpoint(lat, lon).url
        let task = URLSession.shared.dataTask(with: newsEndpoint) { (data, response, error) in
            guard let data = data else{
                completionHandler([], error)
                print("Request Error: " + (error?.localizedDescription)!)
                return
            }
            do{
                let response = try JSONDecoder().decode(EncryptedPictureModel.self, from: data)
                let allEncryptedPhotos = response.photos.photo
                print(allEncryptedPhotos)
                completionHandler(allEncryptedPhotos, nil)
            }
            catch{
                print(error)
            }
            
        }
        task.resume()
    }
    
    class func requestImage(url: URL, completionHandler: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(data, nil)
        })
        task.resume()
    }
    
}
