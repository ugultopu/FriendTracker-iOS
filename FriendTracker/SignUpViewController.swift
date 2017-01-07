//
//  SignUpViewController.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/5/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class SignUpViewController: UIViewController {
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var password0TextField: UITextField!
    @IBOutlet weak var password1TextField: UITextField!

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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onClickSignUpButton(_ sender: Any) {
        if let firstname = firstNameTextField.text, let lastname = lastNameTextField.text, let email = emailAddressTextField.text, let phonenumber = phoneNumberTextField.text, let username = usernameTextField.text, let password0 = password0TextField.text, let password1 = password1TextField.text {
            if(password0 != password1) {
                let alert = UIAlertController(title: "Password Mismatch", message: "Your passwords do not match", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            // TODO: Validate the input here. Better yet, write input validators for the respective text fields.

            let parameters: Parameters = [
                "firstname": firstname,
                "lastname": lastname,
                "email": email,
                "phonenumber": phonenumber,
                "username": username,
                "password": password0
            ]

            sessionManager.request("https://localhost:8443/register/", method: .post, parameters: parameters).responseJSON { response in
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
                        // TODO: Sign up failed. Handle it.
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
