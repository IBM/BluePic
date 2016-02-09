//
//  Package.swift
//  PhoenixSample
//
//  Created by Daniel Firsht on 12/10/15.
//  Copyright © 2015 Daniel Firsht. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "SwiftBluePic-server",
          dependencies: [
               .Package(url: "https://github.com/IBM-Swift/Kitura-router.git", majorVersion: 1),
               .Package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", majorVersion: 1),
               .Package(url: "https://github.com/IBM-Swift/Kitura-redis.git", majorVersion: 1)
          ]
)

