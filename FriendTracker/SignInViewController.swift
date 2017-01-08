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
    
    // TODO: Remove the following line on production. (That is, when you get your certificate signed by a CA (certificate authority).
    let sessionManager = SessionManager(serverTrustPolicyManager: ServerTrustPolicyManager(policies: ["localhost": .disableEvaluation])
    )
    
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
    
    func validationSuccessful() {
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        let parameters: Parameters = [
            "username": username,
            "password": password
        ]
        
        sessionManager.request("https://localhost:8443/login/", method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let status = json["status"]
                switch status {
                case "Success":
                    // TODO: Put username and password into keychain
                    let sessionid = json["sessionid"].stringValue
                    self.performSegue(withIdentifier: "ShowRouteDrawView", sender: sessionid)
                    break
                case "Cannot authenticate":
                    self.alert(title: "Sign In Failed", message: "The server couldn't authenticate you.")
                    break
                case "Cannot log in":
                    self.alert(title: "Sign In Failed", message: "The server couldn't log you in.")
                    break
                case "Empty session key":
                    self.alert(title: "Sign In Failed", message: "Session key is empty.")
                    break
                default:
                    self.alert(title: "Sign In Failed", message: "Sign in has failed for an unknown reason.")
                    break
                }
                break
            case .failure(let error):
                // TODO: Handle error here
                self.alert(title: "Server Error", message: "The server has returned a non 200 response.")
                print(error)
                break
            }
        }
    }
    
}
