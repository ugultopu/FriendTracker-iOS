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
import SwiftValidator

class SignUpViewController: UIViewController, ValidationDelegate {
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var password0TextField: UITextField!
    @IBOutlet weak var password1TextField: UITextField!
    
    let validator = Validator()
    
    // TODO: Remove the following line on production. (That is, when you get your certificate signed by a CA (certificate authority).
    let sessionManager = SessionManager(serverTrustPolicyManager: ServerTrustPolicyManager(policies: ["\(host)": .disableEvaluation])
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validator.registerField(firstNameTextField, rules: [RequiredRule()])
        validator.registerField(lastNameTextField, rules: [])
        validator.registerField(emailAddressTextField, rules: [RequiredRule(), EmailRule()])
        validator.registerField(phoneNumberTextField, rules: [RequiredRule(), PhoneNumberRule()])
        validator.registerField(usernameTextField, rules: [RequiredRule()])
        validator.registerField(password0TextField, rules: [RequiredRule()])
        validator.registerField(password1TextField, rules: [ConfirmationRule(confirmField: password0TextField)])
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
        validator.validate(self)
    }
    
    func validationSuccessful() {
        let firstname = firstNameTextField.text!
        let lastname = lastNameTextField.text!
        let email = emailAddressTextField.text!
        let phonenumber = phoneNumberTextField.text!
        let username = usernameTextField.text!
        let password = password0TextField.text!
        
        let parameters: Parameters = [
            "firstname": firstname,
            "lastname": lastname,
            "email": email,
            "phonenumber": phonenumber,
            "username": username,
            "password": password
        ]
        
        sessionManager.request("https://\(host):8443/register/", method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let status = json["status"]
                switch status {
                case "Success":
                    SignInViewController.signIn(username: username, password: password, view: self)
                    break
                case "Cannot create user":
                    self.alert(title: "Sign Up Failed", message: "The server couldn't create a user.")
                    break
                default:
                    self.alert(title: "Sign Up Failed", message: "Sign up has failed for an unknown reason.")
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
