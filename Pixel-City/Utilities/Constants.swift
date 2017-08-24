//
//  Constants.swift
//  Pixel-City
//
//  Created by Tushar Katyal on 24/08/17.
//  Copyright © 2017 Tushar Katyal. All rights reserved.
//

import Foundation

let API_KEY = "e00dc1b6511d7806b3ce7f9cb8e4fc28"
let API_SECRET = "02ec87f6075e7131"


func flickrURL(forApiKey key : String , withAnnotation annotation : DroppablePin, andNumberOfPhotos number : Int) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
}
