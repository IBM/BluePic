#BluePic

**This repo is not ready for consumption yet and please note that this README is still under construction This is a new development effort that has not completed yet. If you are looking for the Kitura-BluePic repo, please visit this URL: https://github.com/IBM-Swift/Kitura-BluePic.**

BluePic is a photo and image sharing sample application that allows you to take photos and share them with other BluePic users. This sample application demonstrates how to leverage a Kitura-based server application [written in Swift] in a mobile iOS 9 application.

## Getting started

There are two ways you can compile and provision BluePic on Bluemix. The first approach uses the IBM Cloud Bridge tool. Using the IBM Cloud Bridge tool is the easiest and quickest path to get BluePic up and running. The second approach is manual, does not leverage this  tool, and, therefore, takes longer but you get to understand exactly the steps that are happening behind the scenes.

### IBM Cloud Bridge
TODO: ADD Contents

### Step by step instructions for configuration and deployment
Instead of using the IBM Cloud Bridge, which gives you a seamless compilation and provisioning experience, you can follow the steps outlined in this section if you'd like to take a peek under the hood!

#### 1. Install system dependencies

The following system level dependencies should be installed on OS X using [Homebrew](http://brew.sh/):

```bash
brew install curl
```

If you are using Linux as your development platform, you can find full details on how to set up your environment for building Kitura-based applications at [Getting started with Kitura](https://github.com/IBM-Swift/Kitura).

#### 2. Clone the BluePic Git repository

Execute the following command to clone the Git repository:

```bash
git clone https://github.com/IBM-Swift/BluePic.git
```

If you'd like to, you can spend a few minutes to get familiar with the folder structure of the repo as described in the [About](Docs/About.md) page.

#### 3. Create BluePic application on Bluemix

Clicking on the button below deploys the BluePic application to Bluemix. The `manifest.yml` file [included in the repo] is parsed to obtain the name of the application and to determine the Cloud Foundry services that should be instantiated. For further details on the structure of the `manifest.yml` file, see the [Cloud Foundry documentation](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html#minimal-manifest).

[![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy)

Note that the [Bluemix buildpack for Swift](https://github.com/IBM-Swift/swift-buildpack) is used for the deployment of BluePic to Bluemix.

#### 4. Create an application instance on Facebook

In order to have the iOS application authenticate with Facebook, you must create an application instance on Facebook's website.

1. Go to [Facebook's Quick Start for iOS](https://developers.facebook.com/quickstarts/?platform=ios) page. Type `BluePic` as the name of your new Facebook app and click the `Create New Facebook App ID` button.

1. Note that you **do not** need to download the Facebook SDK. The Mobile Client Access framework (already included in the iOS project) has all the code needed to support Facebook authentication. In the `Configure your info.plist` section under `step 2`, copy the information into the `info.plist` file. You can find the `info.plist` file in `Configuration` folder of the Xcode project. Among other values, your `info.plist` file should contain the following:
<p align="center"><img src="Imgs/infoplist.png"  alt="Drawing" height=150 border=0 /></p>

1. Scroll to the bottom of the quick start page where it says `Supply us with your Bundle Identifier` and enter the app's bundle ID. To find the bundle ID in the Xcode project, make sure the project navigator folder icon is selected in the top left of Xcode. Select the BluePic project at the top of the file structure and then select the BluePic target. Under the identity section, you should see a text field for the bundle ID that is empty. You can make the bundle ID anything you want, `com.BluePic` for example.

1. Once you've entered the bundle ID on the Facebook quick start page, click `next` to create the Facebook app.

#### 5. Configure Bluemix Mobile Client Access

TODO: ADD CONTENTS

#### 6. Configure Bluemix Push service

To utilize push notification capabilities on Bluemix, you need to configure a notification provider. For BluePic, you should configure credentials for the Apple Push Notification Service (APNS). Luckily, Bluemix has [instructions](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html) to walk you through that process.

Please note that you'd need to upload a ```.p12``` certificate to Bluemix and enter the password for it, as mentioned in the [instructions](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html).

Lastly, remember that push notifications will only show up on a physical iOS device.

#### 7. Configure OpenWhisk

TODO: ADD CONTENTS

#### 8. Populate Cloudant database

To populate your Cloudant database instance with sample data, you can execute the ```populator.sh``` shell script. Please note that this script requires three parameters:

- ```username``` - The Cloudant username.
- ```password``` - The Cloudant password.
- ```projectid``` - The project ID for your Object Storage instance.

You can obtain the above credentials by accessing your application's page on Bluemix and clicking on the ```Show Credentials``` twisty found on your Cloudant service and Object Storage instances.

```bash
./Bridge-Scripts/cloudantNoSQLDB/populator.sh --username=<cloudant username> --password=<cloudant password> --projectid=<object storage projectid>

```

#### 9. Populate Object Storage

To populate your Object Storage instance with sample data, you can execute the ```populator.sh``` shell script. Please note that this script requires three parameters:

- ```userid``` - The Object Storage username.
- ```password``` - The Object Storage password.
- ```projectid``` - The project ID for your Object Storage instance.

You can obtain the above credentials by accessing your application's page on Bluemix and clicking on the ```Show Credentials``` twisty found on your Object Storage instance.

```bash
./Bridge-Scripts/Object-Storage/populator.sh --userid=<object storage username> --password=<object storage password> --projectid=<object storage projectid>
```

#### 10. Update `BluePic-Server/config.json` file

After deploying BluePic to Bluemix and configuring its services, you also have the option to run the Kitura-based server locally for development and testing purposes. To run the Kitura-based server locally, you'd need to update the credentials for each one of the services listed in the ```BluePic-Server/config.json``` file.

Remember that you can obtain the credentials for each service listed in the ```config.json``` file by accessing your application's page on Bluemix and clicking on the ```Show Credentials``` twisty found on each of the service instances.

```json
...
"services": {
  "AdvancedMobileAccess": [
    {
      "name": "Mobile Client Access-ag",
      "label": "AdvancedMobileAccess",
      "plan": "Gold",
      "credentials": {
        "serverUrl": "<serverUrl>",
        "clientId": "<clientId>",
        "secret": "<secret>",
        "tenantId": "<tenantId>",
        "admin_url": "<admin_url>"
      }
    }
  ],
  "imfpush": [
    {
      "name": "IBM Push Notifications-12",
      "label": "imfpush",
      "plan": "Basic",
      "credentials": {
        "url": "<url>",
        "admin_url": "<admin_url>",
        "appSecret": "<appSecret>"
      }
    }
  ],
  "cloudantNoSQLDB": [
    {
      "name": "Cloudant NoSQL DB-fz",
      "label": "cloudantNoSQLDB",
      "plan": "Shared",
      "credentials": {
        "username": "<username>",
        "password": "<password>",
        "host": "<host>",
        "port": 443,
        "url": "<url>"
      }
    }
  ],
  "Object-Storage": [
    {
      "name": "Object Storage-bv",
      "label": "Object-Storage",
      "plan": "standard",
      "credentials": {
        "auth_url": "https://identity.open.softlayer.com",
        "project": "<project>",
        "projectId": "<projectId>",
        "region": "<region>",
        "userId": "<userId>",
        "username": "<username>",
        "password": "<password>",
        "domainId": "<domainId>",
        "domainName": "<domainName>"
      }
    }
  ]
}
...
```

#### 11. Build the BluePic-Server

You can now build the BluePic-Server by going to the `BluePic-Server` directory of the cloned repository and running this command:

```bash
make
```

#### 12. Run the BluePic-Server

To start the Kitura-based server for the BluePic app, go to the `BluePic-Server` directory of the cloned repository and run the following command:

```bash
.build/debug/Server
```

#### 13. Run the iOS app

Go to the BluePic-iOS directory and open the BluePic workspace with Xcode:

```bash
open BluePic.xcworkspace
```

Before running the iOS app, you should update the ```bluemix.plist``` in the Xcode project.

TODO: Add contents

You can now build and run the iOS app using the Xcode capabilities you are used to!

## About BluePic

To learn more about BluePic's folder structure, its architecture, the Swift packages it depends on, and details on how to use the iOS app component, see the [About](Docs/About.md) page.

## License

This application is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
