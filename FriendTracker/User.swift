//
//  User.swift
//  FriendTracker
//
//  Created by Utku Gultopu on 1/6/17.
//  Copyright © 2017 FriendTracker. All rights reserved.
//

import UIKit

typealias UserID = Int

class User: NSObject {
    let id: UserID
    var overlay: FadingPolyline

    init(withId: Int, atLocation: Location) {
        self.id = withId
        let locations = [atLocation]
        overlay = FadingPolyline(locations: locations)
    }

    func add(location: Location) {
        overlay.add(location: location)
    }

    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }

}
