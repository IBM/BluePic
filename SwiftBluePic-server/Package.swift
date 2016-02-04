//
//  Package.swift
//  PhoenixSample
//
//  Created by Daniel Firsht on 12/10/15.
//  Copyright © 2015 Daniel Firsht. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "BluePic-server",
          dependencies: [ .Package(url: "git@github.ibm.com:ibmswift/Phoenix.git", majorVersion: 0),
    ]
)

