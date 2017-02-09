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
    @IBOutlet weak var bottomStackViewLayoutContraint: NSLayoutConstraint!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.bottomStackViewLayoutContraint.constant = 0.0
            } else {
                self.bottomStackViewLayoutContraint.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
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
        let json = JSON(parseJSON: text)
        print("Received:")
        print(text)
        switch connectionStatus {
        case .connecting:
            let sessionid = json["sessionid"].stringValue
            updateSessionID(sessionid: sessionid)
            connectionStatus = .send_receive
            break
        case .send_receive:
            switch json["command"] {
            case "location":
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
            case "follow":
                let followee_username = json["followee_username"]
                let alert = UIAlertController(title: "Follow Request", message: "\(followee_username) has requested to be followed. Do you accept?", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Follow", style: UIAlertActionStyle.default, handler: {action in
                    // Send follow accept to server.
                }))
                alert.addAction(UIAlertAction(title: "Don't Follow", style: UIAlertActionStyle.cancel, handler: {action in
                    // Send follow reject to server.
                }))
                self.present(alert, animated: true, completion: nil)
                break
            default:
                break
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
        self.view.endEditing(false)
        followTextFieldValidator.validate(self)
    }
    
    @IBAction func onPinLocationClicked(_ sender: Any) {
        self.view.endEditing(false)
        pinLocationTextFieldValidator.validate(self)
    }
    
    @IBAction func onShowLocationsClicked(_ sender: Any) {
        self.view.endEditing(false)
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
                    let locations = JSON(parseJSON: json["locations"].stringValue)
                    for (_, locationJson) in locations {
                        let fields = locationJson["fields"]
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: fields["latitude"].doubleValue, longitude: fields["longitude"].doubleValue)
                        annotation.title = fields["name"].stringValue
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
