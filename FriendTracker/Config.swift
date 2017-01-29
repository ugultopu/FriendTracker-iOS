//
//  Config.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/15/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import Foundation
import Alamofire

let host = "localhost"
// FIXME Remove the following line on production. (That is, when you get your certificate signed by a CA (certificate authority).
let sessionManager = SessionManager(serverTrustPolicyManager: ServerTrustPolicyManager(policies: ["\(host)": .disableEvaluation]) )


