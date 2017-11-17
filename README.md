# BluePic

[![Build Status - Master](https://travis-ci.org/IBM/BluePic.svg?branch=master)](https://travis-ci.org/IBM/BluePic)
![IBM Cloud Deployments](https://deployment-tracker.mybluemix.net/stats/c45eeb765e77bf2bffd747e8d910e37d/badge.svg)

BluePic is a photo and image sharing sample application that allows you to take photos and share them with other BluePic users. This sample application demonstrates how to leverage, in a mobile iOS 10 application, a Kitura-based server application written in Swift.

BluePic takes advantage of Swift in a typical iOS client setting, but also on the server-side using the new Swift web framework and HTTP Server, Kitura. An interesting feature of Bluepic, is the way it handles photos on the server. When an image is posted, it's data is recorded in Cloudant and the image binary is stored in Object Storage. From there, an [OpenWhisk](http://www.ibm.com/cloud-computing/IBM Cloud/openwhisk/) sequence is invoked causing weather data like temperature and current condition (e.g. sunny, cloudy, etc.) to be calculated based on the location an image was uploaded from. Watson Visual Recognition is also used in the OpenWhisk sequence to analyze the image and extract text tags based on the content of the image. A push notification is finally sent to the user, informing them their image has been processed and now includes weather and tag data.

## Swift version
The back-end components (i.e. Kitura-based server and Cloud Functions actions) and the iOS component of the BluePic app work with specific versions of the Swift binaries, see following table:

| Component | Swift Version |
| --- | --- |
| Kitura-based server | `4.0` |
| Cloud Functions actions | `3.1.1` |
| iOS App | Xcode 9.0 default (`Swift 4.0`)

You can download the development snapshots of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

Optionally, if you'd like to run the BluePic Kitura-based server using Xcode, you should use Xcode 9 and configure it to use the default toolchain. For details on how to set up Xcode, see [Building your Kitura application on XCode](https://github.com/IBM-Swift/Kitura/wiki/Building-your-Kitura-application-on-XCode/d43b796976bfb533d3d209948de17716fce859b0). Please note that any other versions of Xcode are not guaranteed to work with the back-end code.


## Getting started

### 1. Install system dependencies
The following system level dependencies should be installed on macOS using [Homebrew](http://brew.sh/):

```bash
brew install curl
```

If you are using Linux as your development platform, you can find full details on how to set up your environment for building Kitura-based applications at [Getting started with Kitura](https://github.com/IBM-Swift/Kitura).

### 2. Clone the BluePic Git repository
Execute the following command to clone the Git repository:

```bash
git clone https://github.com/IBM/BluePic.git
```

If you'd like to, you can spend a few minutes to get familiar with the folder structure of the repo as described in the [About](Docs/About.md) page.

### 3. Create BluePic application on IBM Cloud

#### Cloud Foundry Deployment
Clicking on the button below deploys the BluePic application to IBM Cloud. The [`manifest.yml`](manifest.yml) file [included in the repo] is parsed to obtain the name of the application and to determine the Cloud Foundry services that should be instantiated. For further details on the structure of the `manifest.yml` file, see the [Cloud Foundry documentation](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html#minimal-manifest). After clicking the button below, you will be able to name your application, keep in mind that your IBM Cloud application name needs to match the name value in your `manifest.yml`. Therefore, you may have to change the name value in your `manifest.yml` if there is a naming conflict in your IBM Cloud account.

[![Deploy to IBM Cloud](https://deployment-tracker.mybluemix.net/stats/c45eeb765e77bf2bffd747e8d910e37d/button.svg)](https://bluemix.net/deploy?repository=https://github.com/IBM/BluePic.git&cm_mmc=github-code-_-native-_-bluepic-_-deploy2bluemix)

Once deployment to IBM Cloud is completed, you should access the route assigned to your application using the web browser of your choice. You should see the Kitura welcome page!

Note that the [IBM Cloud buildpack for Swift](https://github.com/IBM-Swift/swift-buildpack) is used for the deployment of BluePic to IBM Cloud. This buildpack is currently installed in the following IBM Cloud regions: US South, United Kingdom, and Sydney.

#### Manual Command Line Deployment
##### Deploy as Cloud Foundry Application
You will need to install the following:
- [IBM Cloud Dev Plugin](https://console.bluemix.net/docs/cloudnative/dev_cli.html#developercli)
```
sh ./Cloud-Scripts/deploy.sh
```
##### Deploy as Kubernetes Container Cluster with Docker
- For information on deploying to Kubernetes please read our [docs](./Docs/Kubernetes.md)

### 4. Populate Cloudant database
To populate your Cloudant database instance with sample data, you need to obtain the following credential values:

- `username` - The username for your Cloudant instance.
- `password` - The password for your Cloudant instance.
- `projectId` - The project ID for your Object Storage instance.

You can obtain the above credentials by accessing your application's page on IBM Cloud and clicking on the `Show Credentials` twisty found on your Cloudant service and Object Storage service instances. Once you have these credentials, navigate to the `Cloud-Scripts/cloudantNoSQLDB/` directory in the BluePic repo and execute the `populator.sh` script as shown below:

```bash
./populator.sh --username=<cloudant username> --password=<cloudant password> --projectId=<object storage projectId>

```

### 5. Populate Object Storage
To populate your Object Storage instance with sample data, you need to obtain the following credential values (region is optional):

- `userId` - The userId for your Object Storage instance.
- `password` - The password for your Object Storage instance.
- `projectId` - The project ID for your Object Storage instance.
- `region` - Optionally, you can set the region for Object Storage to save your data in, either `london` for London or `dallas` for Dallas. If not set, region defaults to `dallas`.

You can obtain the above credentials by accessing your application's page on IBM Cloud and clicking on the `Show Credentials` twisty found on your Object Storage instance. Once you have these credentials,  navigate to the `./Cloud-Scripts/Object-Storage/` directory in the BluePic repo and execute the `populator.sh` script as shown below:

```bash
./populator.sh --userId=<object storage userId> --password=<object storage password> --projectId=<object storage projectId> --region=<object storage region>
```

### 6. Update `BluePic-Server/config/configuration.json` file
You should now update the credentials for each one of the services listed in the `BluePic-Server/config/configuration.json` file. This will allow you to run the Kitura-based server locally for development and testing purposes. You will find placeholders in the `configuration.json` file (e.g. `<username>`, `<projectId>`) for each of the credential values that should be provided.

Remember that you can obtain the credentials for each service listed in the `configuration.json` file by accessing your application's page on IBM Cloud and clicking on the `Show Credentials` twisty found on each of the service instances bound to the BluePic app.

You can take a look at the contents of the `configuration.json` file by clicking [here](BluePic-Server/configuration.json).

### 7. Update configuration for iOS app
Go to the `BluePic-iOS` directory and open the BluePic workspace with Xcode using `open BluePic.xcworkspace`. Let's now update the `cloud.plist` in the Xcode project (you can find this file in `Configuration` folder of the Xcode project).

1. You should set the `isLocal` value to `YES` if you'd like to use a locally running server; if you set the value to `NO`, then you will be accessing the server instance running on IBM Cloud.

2. To get the `appRouteRemote` value, you should go to your application's page on IBM Cloud. There, you will find a `View App` button near the top right. Clicking on it should open up your app in a new tab, the url for this page is your `route` which maps to the `appRouteRemote` key in the plist. Make sure to include the `http://` protocol in your `appRouteRemote` and to exclude a forward slash at the end of the url.

3. Lastly, we need to get the value for `cloudAppRegion`, which can be one of three options currently:

REGION US SOUTH | REGION UK | REGION SYDNEY
--- | --- | ---
`.ng.IBM Cloud.net` | `.eu-gb.IBM Cloud.net` | `.au-syd.IBM Cloud.net`

You can find your region in multiple ways. For instance, by just looking at the URL you use to access your application's page (or the IBM Cloud dashboard). Another way is to look at the `configuration.json` file you modified earlier. If you look at the credentials under your `AppID` service, there is a value called `oauthServerUrl` which should contain one of the regions mentioned above. Once you insert your `cloudAppRegion` value into the `cloud.plist`, your app should be configured.

## Optional features to configure
This section describes the steps to take in order to leverage Facebook authentication with App ID, Push Notifications, and Cloud Functions.

*API endpoints in BluePic-Server are currently not protected due to dependency limitations, but they will be as soon as that functionality is available with the Kitura and App ID SDKs*

### 1. Create an application instance on Facebook
In order to have the app authenticate with Facebook, you must create an application instance on Facebook's website.

1. Go to the `BluePic-iOS` directory and open the BluePic workspace with Xcode using `open BluePic.xcworkspace`.

1. Choose a bundle identifier for your app and update the Xcode project accordingly: Select the project navigator folder icon located in the top left of Xcode; then select the BluePic project at the top of the file structure and then select the BluePic target. Under the identity section, you should see a text field for the bundle identifier. Update this field with a bundle identifier of your choosing. (i.e. com.bluepic)

1. Go to [Facebook's Quick Start for iOS](https://developers.facebook.com/quickstarts/?platform=ios) page to create an application instance. Type `BluePic` as the name of your new Facebook app and click the `Create New Facebook App ID` button. Choose any Category for the application, and click the `Create App ID` button.

1. On the screen that follows, note that you **do not** need to download the Facebook SDK. The App ID SDK (already included in the iOS project) has all the code needed to support Facebook authentication. In the `Configure your info.plist` section, copy the `FacebookAppID` value and insert into the `URL Schemes` and `FacebookAppID` fields in your `info.plist` so that your plist looks similar to the image below. The `info.plist` file is found in the `Configuration` folder of the Xcode project.
<p align="center"><img src="Imgs/infoplist.png"  alt="Drawing" height=150 border=0 /></p>

1. Next, scroll to the bottom of the Facebook quick start page where it says `Supply us with your Bundle Identifier` and enter the app's bundle identifier you chose earlier in step 2.

1. That's it for setting up the BluePic application instance on the Facebook Developer website. In the following section, we will link this Facebook application instance to your IBM Cloud App ID service.

### 2. Configure IBM Cloud App ID
1. Go to your application's page on IBM Cloud and open your `App ID` service instance:
<p align="center"><img src="Imgs/app-id-service.png"  alt="Drawing" height=125 border=0 /></p>

1. On the page that follows, click the `Identity Providers` button on the side and you should see something like this:
<p align="center"><img src="Imgs/configure-facebook.png"  alt="Drawing" height=125 border=0 /></p>

1. Flip the toggle switch to On for Facebook and click the edit button. Here, enter your Facebook application ID and secret from your Facebook app's page (see [Create an application instance on Facebook](#1-create-an-application-instance-on-facebook) section for further details).
<p align="center"><img src="Imgs/facebook-appid-setup.png"  alt="Drawing" height=250 border=0 /></p>

1. On this page, you will also see a "Redirect URL for Facebook for Developers", copy it because we need it in a minute. On your Facebook Developer app page, navigate to the Facebook login product. That URL is `https://developers.facebook.com/apps/<facebookAppId>/fb-login/`. Here, paste that link into the "Valid OAuth redirect URIs" field and click Save changes. Back on IBM Cloud, you can also click the Save button.

2. One more thing that needs to be done for App ID to work properly is that you need add the `tenantId` for App ID into the `cloud.plist` for BluePic-iOS. We get the `tenantId ` by viewing our credentials for the App ID service in IBM Cloud, all your services should be under the "Connections" tab of your app on IBM Cloud. Once there, click on the "View Credentials" or "Show Credentials" button for your App ID service and you should see the `tenantId ` pop up, among other values. Now, simply put that value into your `cloud.plist` corresponding with the `appIdTenantId` key.

3. Facebook authentication with IBM Cloud App ID is now completely set up!

### 3. Configure IBM Cloud Push service
To utilize push notification capabilities on IBM Cloud, you need to configure a notification provider. For BluePic, you should configure credentials for the Apple Push Notification Service (APNS). As part of this configuration step, you will need to use the **bundle identifier** you chose in the [Create an application instance on Facebook](#1-create-an-application-instance-on-facebook) section.

Luckily, IBM Cloud has [instructions](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html) to walk you through the process of configuring APNS with your IBM Cloud Push service. Please note that you'd need to upload a `.p12` certificate to IBM Cloud and enter the password for it, as described in the IBM Cloud instructions.

Additionally, the `appGuid ` for your Push service acts independently of the BluePic app so we will need to add that value to our `cloud.plist`. Additionally, we need the `clientSecret` value for the push service. We get both, the `appGuid` and `clientSecret` by viewing our credentials for the Push service in IBM Cloud, all your services should be under the "Connections" of your app. Once there, click on the "View Credentials" or "Show Credentials" button for your Push Notifications service and you should see the `appGuid` pop up, among other values. Now, simply put that value into your `cloud.plist` corresponding with the `pushAppGUID` key. Next, you should see the `clientSecret` value which you can use to populate the `pushClientSecret` field in the `cloud.plist`. This should ensure your device gets registered properly with the Push service.

Lastly, remember that push notifications will only show up on a physical iOS device. To ensure your app can run on a device and receive push notifications, make sure you followed the [IBM Cloud instructions](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html) above. At this point, open the `BluePic.xcworkspace` in Xcode and navigate to the `Capabilities` tab for the BluePic app target. Here, flip the switch for push notifications, like so:

<p align="center"><img src="Imgs/enablePush.png"  alt="Drawing" height=145 border=0 /></p>

Now, make sure your app is using the push enabled provisioning profile you created earlier in the IBM Cloud instructions. Then at this point, you can run the app on your device and be able to receive push notifications.

### 4. Configure Cloud Functions
BluePic leverages Cloud Functions actions written in Swift for accessing the Watson Visual Recognition and Weather APIs. For instructions on how to configure Cloud Functions, see the following [page](Docs/CloudFunctions.md). You will find there details on configuration and invocation of Cloud Functions commands.

### 5. Redeploy BluePic app to IBM Cloud

#### Using the IBM Cloud command line interface
After configuring the optional features, you should redeploy the BluePic app to IBM Cloud.

###### Cloud Foundry
You can use the IBM Cloud CLI to do that, download it [here](http://clis.ng.bluemix.net/ui/home.html). Once you have logged in to IBM Cloud using the command line, you can execute `bx app push` from the root folder of this repo on your local file system. This will push the application code and configuration to IBM Cloud.

###### Kubernetes Cluster
If you are using a Kubernetes Cluser and have already gone through the initial deployment process [here](#deploy-as-kubernetes-container-cluster-with-docker)
```
  # Using defaults parameters from earlier setup instructions:
  bx dev deploy --target=container --deploy-image-target=bluepic --ibm-cluster=BluePic-Cluster
```

## Running the iOS app
If you don't have the iOS project already open, go to the `BluePic-iOS` directory and open the BluePic workspace using `open BluePic.xcworkspace`.

You can now build and run the iOS app in the simulator using the Xcode capabilities you are used to!

### Running the iOS app on a physical device

For IBM developers, see our [Wiki](https://github.com/IBM/BluePic/wiki/Code-Signing-Configuration-for-Internal-Developers) for details on the steps to follow.

The easiest method for running the iOS app on a physical device is to change the bundle ID for BluePic to a unique value (if you haven't already). Afterwards, check the box for `Automatically manage signing` located under the `General` tab for the BluePic app target (in Xcode). After checking that box, you need to ensure the team for your personal Apple Developer account is selected from the dropdown. Assuming you have the Apple Developer Program team role of `Agent` or `Admin`, either a provisioning profile will be created for the BluePic app or a wildcard profile will be used (if exists), allowing you to run on a device.

Alternatively, you can manually configure code signing of the app by using a wildcard App ID to run the app on your device. If already created, simply select it in the provisioning profile dropdown in the `Signing (Debug)` section. If not created, you can create one through the Apple Developer Portal. This [link](https://developer.apple.com/library/content/qa/qa1713/_index.html) should be helpful in providing more info about wildcard App IDs.

## Running the Kitura-based server locally
You can build the BluePic-Server by going to the `BluePic-Server` directory of the cloned repository and running `swift build`. To start the Kitura-based server for the BluePic app on your local system, go to the `BluePic-Server` directory of the cloned repository and run `.build/debug/BluePicServer`. You should also update the `cloud.plist` file in the Xcode project in order to have the iOS app connect to this local server. See the [Update configuration for iOS app](#7-update-configuration-for-ios-app) section for details.

## Using BluePic
BluePic was designed with a lot of useful features. To see further information and details on how to use the iOS app, check out our walkthrough on [Using BluePic](Docs/Usage.md) page.

## About BluePic
To learn more about BluePic's folder structure, its architecture, and the Swift packages it depends on, see the [About](Docs/About.md) page.

## Learn More
[Transition to Server-Side Swift with BluePic](https://developer.ibm.com/swift/2016/11/15/transition-to-server-side-swift-with-bluepic/)
[Introducing Kitura 2.0](https://developer.ibm.com/swift/2017/10/30/kitura-20/)
[Build a server-side Swift application using the Kitura command-line interface](https://developer.ibm.com/swift/2017/10/30/kitura-cli/)

## Privacy Notice
The BluePic-Server application includes code to track deployments to [IBM Cloud](https://www.IBM Cloud.net/) and other Cloud Foundry platforms. The following information is sent to [Deployment Tracker](https://github.com/IBM-bluemix/cf-deployment-tracker-service) and [Metrics collector](https://github.com/IBM/metrics-collector-service) service on each deployment:

* Swift project code version (if provided)
* Swift project repository URL
* Application Name (`application_name`)
* Space ID (`space_id`)
* Application Version (`application_version`)
* Application URIs (`application_uris`)
* Labels and names of bound services
* Number of instances for each bound service and associated plan information

This data is collected from the parameters of the `CloudFoundryDeploymentTracker` and `MetricsTrackerClient`, the `VCAP_APPLICATION` and `VCAP_SERVICES` environment variables in IBM Cloud and other Cloud Foundry platforms. This data is used by IBM to track metrics around deployments of sample applications to IBM Cloud to measure the usefulness of our examples, so that we can continuously improve the content we offer to you. Only deployments of sample applications that include code to ping the Deployment Tracker service will be tracked.

### Disabling Deployment Tracking
Deployment tracking can be disabled by removing the following lines from `main.swift`:

    CloudFoundryDeploymentTracker(repositoryURL: "https://github.com/IBM-Swift/BluePic.git", codeVersion: nil).track()
    MetricsTrackerClient(repository: "BluePic", organization: "IBM").track()

## License
This application is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).

For a list of demo images used, view the [Image Sources](Docs/ImageSources.md) file.
