//
//  SignInViewController.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/5/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftValidator

class SignInViewController: UIViewController, ValidationDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let validator = Validator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validator.registerField(usernameTextField, rules: [RequiredRule()])
        validator.registerField(passwordTextField, rules: [RequiredRule()])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueName = segue.identifier {
            switch segueName {
            case "ShowRouteDrawView":
                let destination = segue.destination as! RouteDrawViewController
                destination.sessionid = sender as! String
            default:
                break
            }
        }
    }
    
    @IBAction func onClickSignInButton(_ sender: Any) {
        validator.validate(self)
    }
    
    func validationSuccessful(for: Validator) {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        SignInViewController.signIn(username: username, password: password, view: self)
    }
    
    // FIXME Decide if you need to delete only the "sessionid", or if you need to delete "crsftoken" as well.
    static func deleteCookies() {
        let cookieStorage = sessionManager.session.configuration.httpCookieStorage!
        let cookies = cookieStorage.cookies(for: URL(string: "https://\(host)")!)!
        for cookie in cookies {
            cookieStorage.deleteCookie(cookie)
        }
    }
    
    static func signIn(username: String, password: String, view: UIViewController) {
        deleteCookies()
        
        let parameters: Parameters = [
            "username": username,
            "password": password
        ]
        
        sessionManager.request("https://\(host):\(port)/login/", method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let status = json["status"]
                switch status {
                case "Success":
                    // TODO: Put username and password into keychain
                    let sessionid = json["sessionid"].stringValue
                    view.performSegue(withIdentifier: "ShowRouteDrawView", sender: sessionid)
                    break
                case "Cannot authenticate":
                    view.alert(title: "Sign In Failed", message: "The server couldn't authenticate you.")
                    break
                case "Cannot log in":
                    view.alert(title: "Sign In Failed", message: "The server couldn't log you in.")
                    break
                case "Empty session key":
                    // FIXME: Understand why does the server sometimes return an empty session key and fix it on the server side.
                    signIn(username: username, password: password, view: view)
                    break
                default:
                    view.alert(title: "Sign In Failed", message: "Sign in has failed for an unknown reason.")
                    break
                }
                break
            case .failure(let error):
                // TODO: Handle error here
                view.alert(title: "Server Error", message: "The server has returned a non 200 response.")
                print(error)
                break
            }
        }
    }
    
}
