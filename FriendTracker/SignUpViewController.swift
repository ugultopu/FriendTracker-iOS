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
    @IBOutlet var stackViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var stackViewVerticalCenterConstraint: NSLayoutConstraint!
    
    let validator = Validator()
    
    // TODO: Remove the following line on production. (That is, when you get your certificate signed by a CA (certificate authority).
    let sessionManager = SessionManager(serverTrustPolicyManager: ServerTrustPolicyManager(policies: ["\(host)": .disableEvaluation])
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stackViewBottomLayoutConstraint.isActive = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        validator.registerField(firstNameTextField, rules: [RequiredRule()])
        validator.registerField(lastNameTextField, rules: [])
        validator.registerField(emailAddressTextField, rules: [RequiredRule(), EmailRule()])
        validator.registerField(phoneNumberTextField, rules: [RequiredRule(), PhoneNumberRule()])
        validator.registerField(usernameTextField, rules: [RequiredRule()])
        validator.registerField(password0TextField, rules: [RequiredRule()])
        validator.registerField(password1TextField, rules: [ConfirmationRule(confirmField: password0TextField)])
    }
    
    deinit {
        self.stackViewVerticalCenterConstraint.isActive = true
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
                self.stackViewBottomLayoutConstraint.constant = 0.0
            } else {
                self.stackViewVerticalCenterConstraint.isActive = false
                self.stackViewBottomLayoutConstraint.isActive = true
                self.stackViewBottomLayoutConstraint.constant = endFrame?.size.height ?? 0.0
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
    
    @IBAction func onClickSignUpButton(_ sender: Any) {
        validator.validate(self)
    }
    
    func validationSuccessful(for: Validator) {
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
        
        sessionManager.request("https://\(host):\(port)/register/", method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let data):
                let json = JSON(data)
                let status = json["status"]
                switch status {
                case "Success":
                    // FIXME This is a workaround for sign in not being performed on server side after a sign up. After you fix this problem on server side, delete the line below and uncomment the line after below.
                    self.performSegue(withIdentifier: "ShowSignInView", sender: self)
//                    SignInViewController.signIn(username: username, password: password, view: self)
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
