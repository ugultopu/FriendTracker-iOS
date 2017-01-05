//
//  FadingPolyline.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/5/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit
import MapKit

class FadingPolyline: NSObject, MKOverlay {
    var locations: [Location]
    
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    
    init(locations: [Location]) {
        let color = FadingPolyline.getColor()
        self.red = color.red
        self.green = color.green
        self.blue = color.blue
        
        self.locations = locations
        
        let numberOfLocations = Double(locations.count)
        let firstPoint = MKMapPointForCoordinate(locations[0].coordinate)
        var latitudeSum = 0.0
        var longitudeSum = 0.0
        var bottommostPoint = firstPoint
        var topmostPoint = firstPoint
        var leftmostPoint = firstPoint
        var rightmostPoint = firstPoint
        
        // TODO - This code will fail at longitudes greater than 180. Apple's note as it appears before the boundingMapRect property of the MKOverlay protocol:
        // boundingMapRect should be the smallest rectangle that completely contains the overlay.
        // For overlays that span the 180th meridian, boundingMapRect should have either a negative MinX or a MaxX that is greater than MKMapSizeWorld.width.
        for location in locations {
            let point = MKMapPointForCoordinate(location.coordinate)
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            latitudeSum += latitude
            longitudeSum += longitude
            if point.y < topmostPoint.y { topmostPoint = point }
            if point.y > bottommostPoint.y { bottommostPoint = point }
            if point.x < leftmostPoint.x { leftmostPoint = point }
            if point.x > rightmostPoint.x { rightmostPoint = point }
        }
        
        let centerLatitude = latitudeSum / numberOfLocations
        let centerLongitude = longitudeSum / numberOfLocations
        self.coordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        let width = rightmostPoint.x - leftmostPoint.x
        let height = bottommostPoint.y - topmostPoint.y
        let mapSize = MKMapSize(width: width, height: height)
        self.boundingMapRect = MKMapRect(origin: MKMapPointMake(leftmostPoint.x, topmostPoint.y), size: mapSize)
    }
    
    static func getColor() -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        struct Color {
            static let colors = [UIColor.blue, UIColor.red, UIColor.green, UIColor.yellow, UIColor.cyan, UIColor.magenta]
            static var colorIndex = 0
        }
        
        let color = Color.colors[Color.colorIndex]
        Color.colorIndex = (Color.colorIndex + 1) % Color.colors.count
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red: red, green: green, blue: blue)
    }
    
    func add(location: Location) {
        let newCoordinate = location.coordinate
        let newPoint = MKMapPointForCoordinate(newCoordinate)
        
        let numberOfLocations = Double(self.locations.count)
        let latitudeSum = (self.coordinate.latitude * numberOfLocations) + newCoordinate.latitude
        let longitudeSum = (self.coordinate.longitude * numberOfLocations) + newCoordinate.longitude
        let centerLatitude = latitudeSum / (numberOfLocations + 1)
        let centerLongitude = longitudeSum / (numberOfLocations + 1)
        
        self.coordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        
        let origin = self.boundingMapRect.origin
        let width = self.boundingMapRect.size.width
        let height = self.boundingMapRect.size.height
        
        var bottommostPoint = MKMapPoint(x: origin.x, y: origin.y + height)
        var topmostPoint = MKMapPoint(x: origin.x, y: origin.y)
        var leftmostPoint = MKMapPoint(x: origin.x, y: origin.y)
        var rightmostPoint = MKMapPoint(x: origin.x + width, y: origin.y)
        
        if newPoint.y < topmostPoint.y { topmostPoint = newPoint }
        if newPoint.y > bottommostPoint.y { bottommostPoint = newPoint }
        if newPoint.x < leftmostPoint.x { leftmostPoint = newPoint }
        if newPoint.x > rightmostPoint.x { rightmostPoint = newPoint }
        
        let newWidth = rightmostPoint.x - leftmostPoint.x
        let newHeight = bottommostPoint.y - topmostPoint.y
        let mapSize = MKMapSize(width: newWidth, height: newHeight)
        self.boundingMapRect = MKMapRect(origin: MKMapPointMake(leftmostPoint.x, topmostPoint.y), size: mapSize)
        
        locations.append(location)
    }
    
}
