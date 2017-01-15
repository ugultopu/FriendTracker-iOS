//
//  FadingPolylineRenderer.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/6/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit
import MapKit

class FadingPolylineRenderer: MKOverlayRenderer {

    static let earliestDrawableTimeAmount = Double(60 * 30)   // 60 seconds * 30 = 30 minutes

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let fadingPolyline = overlay as! FadingPolyline
        let locations = fadingPolyline.locations.sorted()

        context.saveGState()
        context.setBlendMode(CGBlendMode.exclusion)
        context.setLineWidth(4.0 / zoomScale)
        for i in 0..<(locations.count - 1) {
            let thisLocation = locations[i]
            let nextLocation = locations[i + 1]
            let thisMapPoint = MKMapPointForCoordinate(thisLocation.coordinate)
            let nextMapPoint = MKMapPointForCoordinate(nextLocation.coordinate)

            context.setFillColor(red: fadingPolyline.red, green: fadingPolyline.green, blue: fadingPolyline.blue, alpha: opacity(of: nextLocation))
            context.setStrokeColor(red: fadingPolyline.red, green: fadingPolyline.green, blue: fadingPolyline.blue, alpha: opacity(of: nextLocation))
            context.beginPath()
            context.move(to: point(for: thisMapPoint))
            context.addLine(to: point(for: nextMapPoint))

            context.strokePath()
        }
        context.drawPath(using: CGPathDrawingMode.fillStroke)
        context.restoreGState()
    }

    func opacity(of: Location) -> CGFloat {
        let locationTime = of.timestamp
        let longAgo = NSDate().timeIntervalSince1970 - locationTime
        let remainingTime = FadingPolylineRenderer.earliestDrawableTimeAmount - longAgo < 0 ? 0 : FadingPolylineRenderer.earliestDrawableTimeAmount - longAgo
        return CGFloat(remainingTime / FadingPolylineRenderer.earliestDrawableTimeAmount)
    }

}
