//
//  BaseLoginController.swift
//  BluePic
//
//  Created by Ira Rosen on 3/1/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import Foundation

class BaseLoginController : UIViewController {
    weak var delegate: LoginControllerDelegate?
}

protocol LoginControllerDelegate: class {
    func signedInAs(userName: String) -> Void
}
