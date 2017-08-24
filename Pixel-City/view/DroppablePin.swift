//
//  DroppablePin.swift
//  Pixel-City
//
//  Created by Tushar Katyal on 24/08/17.
//  Copyright © 2017 Tushar Katyal. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class DroppablePin : NSObject , MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var identifier : String
    
    init(coordinate : CLLocationCoordinate2D, identifier : String) {
        
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
