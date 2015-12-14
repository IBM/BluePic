# BluePic


## Overview

BluePic is a sample application for iOS that shows how quickly and simple it is to get started developing with IBM Bluemix services. It is a photo sharing application that allows you to take photos and upload them to a server.

## About IBM Bluemix

[Bluemix™](https://developer.ibm.com/sso/bmregistration?lang=en_US&ca=dw-_-bluemix-_-cl-bluemixfoundry-_-article) is the latest cloud offering from IBM®. It enables organizations and developers to quickly and easily create, deploy, and manage applications on the cloud. Bluemix is an implementation of IBM's Open Cloud Architecture based on Cloud Foundry, an open source Platform as a Service (PaaS). Bluemix delivers enterprise-level services that can easily integrate with your cloud applications without you needing to know how to install or configure them.

## Requirements
Currently, BluePic supports Xcode 7.1.1, iOS 9+, and Swift 2.

## Project Structure
//show where things are located, including the Configuration folder with the .plist files

## Getting Started

### 1. Generating Bluemix Services
Click the Deploy to Bluemix button in order to create an application on your personal Bluemix account that's already set up with the required services.

The button will also create a DevOps Services project and link it to the newly created application.

[![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/rolandoasmat/MyBluemixApp.git)

### 2. Create an application instance on Facebook
In order to authenticate, you must create an application instance on Facebook's website and connect it to your Bluemix app's Mobile Client Access by following [these instructions](https://www.ng.bluemix.net/docs/services/mobileaccess/security/facebook/t_fb_config.html). Make sure you are viewing the sample code in Swift by selecting the drop down at the top right of that page.

### 3. Connect BluePic to your Bluemix Account
//user then needs to put the keys generated into info.plist and keys.plist

### 4. Optional - Pre-populate Feed with Stock Photos
//show how to run the prepopulate photos test


## Using BluePic
//show main features of the app

### Facebook Login
BluePic was designed so that anyone can quickly launch the app and view photos posted without needing to log in. However, to view the profile or post photos, the user can easily login with his/her Facebook account. This is only used for a unique user id, as well as to display the user's profile photo.

### View Feed

### Post a Photo

### View Profile


## Bluemix Services Implemented
### Mobile Client Access Facebook Authentication
[Bluemix Mobile Client Access Facebook Authentication](https://www.ng.bluemix.net/docs/services/mobileaccess/gettingstarted/ios/index.html) is used for logging into BluePic. It's necessary to also create an application instance on Facebook's website and connect it to your Bluemix app's Mobile Client Access by following [these instructions](https://www.ng.bluemix.net/docs/services/mobileaccess/security/facebook/t_fb_config.html). Make sure you are viewing the sample code in Swift by selecting the drop down at the top right of that page. You will need to replace your AppID with the one in BluePic's `info.plist`. 

The `FacebookDataManager` handles the code responsible for Facebook authentication.

//put sample code from BluePic here!

### Cloudant Sync (CDTDatastore)
Cloudant Sync [(CDTDatastore)](https://www.ng.bluemix.net/docs/services/mobileaccess/gettingstarted/ios/index.html) is used in BluePic for profile and picture metadata storage. Make sure to replace your Cloudant keys with the keys found in BluePics' `keys.plist` to connect the application to your Bluemix account. 


`CloudantSyncDataManager` was created to handle communicating between iOS and Cloudant Sync.

//put sample code from BluePic here!

You can view the Cloudant database (including profile and picture documents) by navigating to your Cloudant NoSQL DB service instance on the Bluemix Dashboard.


### Object Storage
[Object Storage](https://console.ng.bluemix.net/catalog/services/object-storage/) is used in BluePic for hosting images. Make sure to replace your Cloudant keys with the keys found in BluePics' `keys.plist` to connect the application to your Bluemix account. You can also view any data on the backend database by navigating to the service on your Bluemix Dashboard.

`ObjectStorageDataManager` and `ObjectStorageClient` were created based on [this link](http://developer.openstack.org/api-ref-objectstorage-v1.html) for communicating between iOS and Object Storage.

//put sample code from BluePic here!

You can view the Object Storage database (including all photos uploaded) by navigating to your Cloudant NoSQL DB service instance on the Bluemix Dashboard.


## Architecture Forethought

For BluePic, we used a simple architecture where there is no middle tier component between the mobile app and the storage components (e.g. Cloudant) on the server. To roll out BluePic to a production environment, a few architectural changes should be made.

Cloudant Sync requires a complete replica of the database on each mobile client. This may not be feasible for apps with large databases. Under such scenarios, instead of leveraging Cloudant Sync, the REST API provided by Cloudant could be used to perform CRUD and query operations against the remote Cloudant instance. Having said this, the Cloudant team is planning to introduce new capabilities [in 2016] for Cloudant Sync that should securely replicate subsets of a large remote database onto devices. Though replicating subsets of records can be done today with Cloudant Sync, doing so with large databases where only a small subset of records should be replicated can introduce performance problems. New functionality that is expected to be delivered next year by the Cloudant team should address such performance issues. 

Using Cloudant Sync without an additional middle tier component between the mobile app and the database requires the mobile code to know the username and password for accessing the Cloudant database. This will lead to security breaches if someone gets their hands on those credentials. Hence, security could be a reason for having all database operations go first through a middleware component (e.g. Liberty, Node.js) to verify that only authenticated and authorized users of the app can perform such operations. In this architecture, the credentials to access the database are only known by the middleware component.


## License
