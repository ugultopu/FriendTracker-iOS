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
import SwiftValidator

class RouteDrawViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ValidationDelegate, WebSocketDelegate {
    
    enum ConnectionStatus {
        case connecting
        case send_receive
        case send_only
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var followTextField: UITextField!
    @IBOutlet weak var pinLocationTextField: UITextField!
    
    let locationManager = CLLocationManager()
    let followTextFieldValidator = Validator()
    let pinLocationTextFieldValidator = Validator()
    var sessionid = ""
    var socket = WebSocket(url: URL(string: "ws://\(host)")!)
    var users = [UserID: User]()
    var firstOverlay = true
    var connectionStatus = ConnectionStatus.connecting
    var currentLocation = CLLocationCoordinate2D()
    var pinnedLocations: [MKPointAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        followTextFieldValidator.registerField(followTextField, rules: [RequiredRule()])
        pinLocationTextFieldValidator.registerField(pinLocationTextField, rules: [RequiredRule()])
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        mapView.delegate = self
        socket = WebSocket(url: URL(string: "wss://\(host):\(port)/location/?session_key=\(sessionid)")!)
        // TODO: Remove the following line on production. (That is, when you get your certificate signed by a CA (certificate authority).
        socket.disableSSLCertValidation = true
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
    
    func updateSessionID(sessionid: String) {
        let cookieStorage = sessionManager.session.configuration.httpCookieStorage!
        let cookies = cookieStorage.cookies(for: URL(string: "https://\(host)")!)!
        // Delete the old session ID cookie
        var expires = Date()
        for cookie in cookies {
            if(cookie.name == "sessionid") {
                expires = cookie.expiresDate!
                cookieStorage.deleteCookie(cookie)
                break
            }
        }
        // Set new session ID cookie
        // FIXME Determine if
        //   1. Setting expiresDate
        //   2. Making "sessionOnly:FALSE"
        // needed or not.
        // FIXME "expires" and "discard" are not being set.
        let cookie = HTTPCookie(properties: [HTTPCookiePropertyKey.name: "sessionid", HTTPCookiePropertyKey.value: sessionid, HTTPCookiePropertyKey.domain: host, HTTPCookiePropertyKey.path: "/", HTTPCookiePropertyKey.expires: expires, HTTPCookiePropertyKey.discard: "FALSE"])!
        cookieStorage.setCookie(cookie)
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        // TODO: Switch case w.r.t the 'socket' parameter.
        let json = JSON.parse(text)
//        print("Received:")
//        print(text)
        switch connectionStatus {
        case .connecting:
            let sessionid = json["sessionid"].stringValue
            updateSessionID(sessionid: sessionid)
            connectionStatus = .send_receive
            break
        case .send_receive:
            let user = UserID(json["user"].intValue)
            let timestamp = TimeInterval(json["timestamp"].doubleValue)
            let latitude = CLLocationDegrees(json["latitude"].doubleValue)
            let longitude = CLLocationDegrees(json["longitude"].doubleValue)
            let location = Location(timestamp: timestamp, latitude: latitude, longitude: longitude)
            if let user = users[user] {
                remove(overlay: user.overlay)
                user.add(location: location)
                add(overlay: user.overlay)
                //            print("Existing user is:")
                //            print(user)
                //            print("Number of locations: \(user.overlay.locations.count)")
            } else {
                let newUser = User(withId: user, atLocation: location)
                users[user] = newUser
                //            print("New user is:")
                //            print(newUser)
                add(overlay: newUser.overlay)
            }
            break
        case .send_only:
            break
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
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.activityType = CLActivityType.fitness
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO: Read the locations in a loop.
        let currentLocationCoordinate = locations[0].coordinate
        currentLocation = currentLocationCoordinate
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
    
    func follow(username: String) {
        let parameters: Parameters = [
            "username": username,
            ]
        sessionManager.request("https://\(host):\(port)/follow/", method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let status = json["status"]
                switch status {
                case "Success":
//                    self.alert(title: "Success", message: "Success.")
                    break
                case "Followee not found":
                    self.alert(title: "Followee not found", message: "Either you have entered a wrong username, or the user has not been found in database.")
                    break
                case "Follow action failed":
                    self.alert(title: "Follow action failed", message: "You have tried to follow a valid user but follow action failed.")
                    break
                default:
                    self.alert(title: "Follow action failed", message: "Follow action failed for an unkown reason")
                    break
                }
            case .failure(let error):
                // TODO: Handle error here
                self.alert(title: "Server Error", message: "The server has returned a non 200 response.")
                print(error)
                break
            }
        }
    }
    
    func validationSuccessful(for: Validator) {
        if `for` === followTextFieldValidator {
            let username = followTextField.text!
            follow(username: username)
        } else if `for` === pinLocationTextFieldValidator {
            let parameters: Parameters = [
                "command": "save",
                "name": pinLocationTextField.text!,
                "latitude": currentLocation.latitude,
                "longitude": currentLocation.longitude,
                ]
            sessionManager.request("https://\(host):\(port)/location/ops/", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                switch response.result {
                case .success(let data):
                    let json = JSON(data)
                    let status = json["status"]
                    switch status {
                    case "Success":
                        //                    self.alert(title: "Success", message: "Success.")
                        break
                    default:
                        self.alert(title: "Cannot save location", message: "Cannot save location due to an unkown reason")
                        break
                    }
                case .failure(let error):
                    // TODO: Handle error here
                    self.alert(title: "Server Error", message: "The server has returned a non 200 response.")
                    print(error)
                    break
                }
            }
        }
    }
    
    @IBAction func onFollowClicked(_ sender: Any) {
        followTextFieldValidator.validate(self)
    }
    
    @IBAction func onPinLocationClicked(_ sender: Any) {
        pinLocationTextFieldValidator.validate(self)
    }
    
    @IBAction func onShowLocationsClicked(_ sender: Any) {
        let parameters: Parameters = [
            "command": "load"
            ]
        sessionManager.request("https://\(host):\(port)/location/ops/", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let status = json["status"]
                switch status {
                case "Success":
                    self.mapView.removeAnnotations(self.pinnedLocations)
                    self.pinnedLocations.removeAll()
                    let locations = JSON.parse(json["locations"].stringValue)
                    for (index, locationJson) in locations {
                        let fields = locationJson["fields"]
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: fields["latitude"].doubleValue, longitude: fields["longitude"].doubleValue)
                        annotation.accessibilityLabel = "Test"
                        self.pinnedLocations.append(annotation)
                    }
                    self.mapView.addAnnotations(self.pinnedLocations)
                    break
                default:
                    self.alert(title: "Cannot load location", message: "Cannot load location due to an unkown reason")
                    break
                }
            case .failure(let error):
                // TODO: Handle error here
                self.alert(title: "Server Error", message: "The server has returned a non 200 response.")
                print(error)
                break
            }
        }
    }
}
