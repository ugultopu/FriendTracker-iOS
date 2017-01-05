//
//  Location.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/5/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit
import CoreLocation

extension CLLocationCoordinate2D {
    static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude
            && lhs.longitude == rhs.longitude
    }
}

class Location: NSObject, Comparable {
    let timestamp: TimeInterval
    let coordinate: CLLocationCoordinate2D
    
    init(timestamp: TimeInterval, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.timestamp  = timestamp
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func ==(lhs: Location, rhs: Location) -> Bool {
        return lhs.timestamp == rhs.timestamp
            && lhs.coordinate == rhs.coordinate
    }
    
    static func <(lhs: Location, rhs: Location) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    static func <=(lhs: Location, rhs: Location) -> Bool {
        return lhs.timestamp <= rhs.timestamp
    }
    
    static func >=(lhs: Location, rhs: Location) -> Bool {
        return lhs.timestamp >= rhs.timestamp
    }
    
    static func >(lhs: Location, rhs: Location) -> Bool {
        return lhs.timestamp > rhs.timestamp
    }
}
