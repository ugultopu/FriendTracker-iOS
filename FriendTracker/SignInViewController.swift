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

class SignInViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // TODO: Remove the following line on production. (That is, when you get your certificate signed by a CA (certificate authority).
    let sessionManager = SessionManager(serverTrustPolicyManager: ServerTrustPolicyManager(policies: ["localhost": .disableEvaluation])
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
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
        if let username = usernameTextField.text, let password = passwordTextField.text {
            let parameters: Parameters = [
                "username": username,
                "password": password
            ]
            
            sessionManager.request("https://localhost:8443/login/", method: .post, parameters: parameters).responseJSON { response in
                switch response.result {
                case .success(let data):
                    let json = JSON(data)
                    let status = json["status"]
                    // TODO: Use a boolean for the response status. This way, your switch case statement will be understandable, like the above switch case statement of Alamofire.
                    switch status {
                    case 0:
                        // TODO: Put username and password into keychain
                        let sessionid = json["sessionid"].stringValue
                        self.performSegue(withIdentifier: "ShowRouteDrawView", sender: sessionid)
                        break
                    default:
                        // TODO: Sign in failed. Handle it.
                        break
                    }
                    break
                case .failure(let error):
                    // TODO: Handle error here
                    //                    print("ERROR: Sign In has failed with error: \(error)")
                    print(error)
                    break
                }
            }
        }
    }
    
}
