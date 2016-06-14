
# About BluePic

## Project folder structure

These are the main folders in this repo:

* `./BluePic-iOS` - Contains the iOS client application.
* `./BluePic-Server` - Contains the Kitura-based server application and its dependencies. This folder contains the artifacts that are deployed to Bluemix.
* `./BluePic-OpenWhisk` - Contains the OpenWhisk actions and sequence code written in Swift.
* `./Bridge-Scripts` - Contains the scripts to be leveraged by the IBM Cloud Tools for Swift.
* `./Docs` - Contains additional project documentation.
* `./Imgs` - Contains images referenced in this `README` file.

## Swift packages

The following Swift packages are used in BluePic:

- [Kitura-CouchDB](https://github.com/IBM-Swift/Kitura-CouchDB)
- [Kitura](https://github.com/IBM-Swift/Kitura.git)
- [Swift-cfenv](https://github.com/IBM-Swift/Swift-cfenv.git)
- [Swift SDK for Bluemix Object Storage Service](https://github.com/ibm-bluemix-mobile-services/bluemix-objectstorage-swift-sdk.git)
- [Kitura Credentials plugin for the Mobile Client Access service](https://github.com/ibm-bluemix-mobile-services/bms-mca-kitura-credentials-plugin.git)
- [Swift SDK for Bluemix Push Notifications Service](https://github.com/ibm-bluemix-mobile-services/bms-pushnotifications-serversdk-swift.git)

## Architecture

The following diagram captures the architecture for the BluePic app:
<p align="center">
<img src="../Imgs/architecture.png"  alt="Drawing" height=450 border=0 /></p>
<p align="center">Figure 1. BluePic Architecture Diagram.</p>
