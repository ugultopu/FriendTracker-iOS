//
//  RouteDrawViewController.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/5/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import SwiftyJSON
import Starscream

class RouteDrawViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, WebSocketDelegate {

    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var sessionid = ""
    var socket = WebSocket(url: URL(string: "ws://localhost")!)
    var users = [UserID: User]()
    var firstOverlay = true

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        mapView.delegate = self
        socket = WebSocket(url: URL(string: "ws://localhost:8000/location/?session_key=\(sessionid)")!)
        socket.delegate = self
        socket.connect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("websocket is disconnected: \(error?.localizedDescription)")
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        // TODO: Switch case w.r.t the 'socket' parameter.
        let json = JSON.parse(text)
        let user = UserID(json["user"].intValue)
        let timestamp = TimeInterval(json["timestamp"].doubleValue)
        let latitude = CLLocationDegrees(json["latitude"].doubleValue)
        let longitude = CLLocationDegrees(json["longitude"].doubleValue)
        let location = Location(timestamp: timestamp, latitude: latitude, longitude: longitude)
        if let user = users[user] {
            remove(overlay: user.overlay)
            user.add(location: location)
            add(overlay: user.overlay)
            print("Existing user is:")
            print(user)
            print("Number of locations: \(user.overlay.locations.count)")
        } else {
            let newUser = User(withId: user, atLocation: location)
            users[user] = newUser
            print("New user is:")
            print(newUser)
            add(overlay: newUser.overlay)
        }
    }

    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("got some data: \(data.count)")
    }

    func add(overlay: FadingPolyline) {
        mapView.add(overlay)

        if(firstOverlay) {
            let span = MKCoordinateSpanMake(0.005, 0.005) // span determines how large of an area is shown on the map initially. The bigger the numbers, we are looking at the map from a higher altitude.
            let region = MKCoordinateRegion(center: overlay.locations[0].coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        firstOverlay = false
    }

    func remove(overlay: FadingPolyline) {
        mapView.remove(overlay)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return FadingPolylineRenderer(overlay: overlay)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO: Read the locations in a loop.
        let currentLocationCoordinate = locations[0].coordinate
        //        print("Current location is: \(currentLocationCoordinate)")
        let parameters: Parameters = [
            "timestamp": NSDate().timeIntervalSince1970,
            "latitude": currentLocationCoordinate.latitude,
            "longitude": currentLocationCoordinate.longitude,
            ]
        let json = JSON(parameters)
        //        print(json.rawString()!)
        socket.write(string: json.rawString()!)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("ERROR: Failed to get location. Cause: \(error)")
    }

}
