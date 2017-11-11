# Setup Cloud Functions

### Prerequisites
1. [IBM Cloud ClI](https://console-regional.ng.bluemix.net/docs/cli/reference/bluemix_cli/download_cli.html#download_install)
2. Follow the instructions [here](https://console-regional.ng.bluemix.net/docs/openwhisk/bluemix_cli.html#cloudfunctions_cli) to install the Cloud Functions CLI plugin
3. Login by following the instructions the header `IBM Cloud CLI authentication`

# Setup CloudFunctions

2. On that same [Cloud Functions CLI](https://new-console.ng.bluemix.net/openwhisk/cli) page, you can find the values needed to populate the [properties.json](../BluePic-Server/properties.json) file under the `Bluepic-Server` directory.

3. In step 2 on the "Cloud Functions - Configure CLI" page, you will see a command that looks similar to:

    `bx wsk property set --apihost <hostName> --auth <authKey>`

4. Update the CloudFunctions information in `BluePic-Server/config/configuration.json`.
  - Take the value after `--apihost` and put it as the `hostName` value in
  - Next, insert a namespace value within the existing `urlPath` value. In the `<namespace>` spot to be exact:
      `"/api/v1/namespaces/<namespace>/actions/bluepic/processImage?blocking=false"`
      You can find this value at the top of the IBM Cloud UI, it will be a combination of the org and the space name, for example: `swift_dev`. Where `swift` is the org name, and `dev` is the space name.
  - Lastly, take the value after `--auth` and put it as the `authToken` value. That value will later be converted to a base64 encoded string that Cloud Functions needs for authentication.

# Installing Cloud Functions Actions for BluePic
## Service Credentials
Before you run the installation script, you will first need to set configuration variables (e.g. cloudant credentials, object storage credentials, etc.) inside of the `local.env` file.  All of these values can be obtained from the `Connections` tab when viewing the IBM Cloud app with your provisioned services.

For `Cloudant` you will need:
* username (with read/write access)
* password
* host (hostname for your cloudant instance, such as `d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com`)
* cloudant database name (default `bluepic_db`)

For `Visual Recognition` you will need:
* api key - this is from your Visual Recognition service instance

For `Weather Company Data` you will need:
* username
* password

For `App ID` you will need:
* client id - this is the unique GUID for your app instance
* secret - secret key for configuring the App ID service

For the `Kitura` callback you will need to obtain the route for your IBM Cloud application. You can find the route by clicking on the `View App` button near the top right of your application's dashboard page on IBM Cloud. This will open the welcome page for the BluePic app; the route is the URL value shown on the browser, which consists of the schema, host, and port (please note that port values 80 and 443 maybe not be shown in the URL in the browser since these are the default port values for http and https respectively):
* schema (http:// or https://)
* host (e.g. `bluepic-grotty-substantiality.mybluemix.net`)
* port (80 if http, 443 is https, other if dev)

## Installation
Install using the bluepic.sh shell script:

    ./bluepic.sh --install


Remove actions using the bluepic.sh shell script:

    ./bluepic.sh --uninstall


Remove and reinstall actions using the bluepic.sh shell script:

    ./bluepic.sh --reinstall

# Actions
The overall processing of an image is handled by an orchestrator action that delegates to single-purpose Cloud Functions actions.  For testing and development, each  action can be invoked separately as an independent action. Parameters will need to be passed in to each individual action based upon its function.  

The `bluepic.sh` shell script is used to create all actions used by the BluePic app.  The most important of which is the `bluepic/processImage` action. This is the main orchestrator mentioned above.

To invoke the action, you just need to pass in an `imageId` parameter (i.e. ID of the cloudant document for the image that needs to be processed).

From the CLI, this can be invoked as (you'll need to use your own image id):

```
bx wsk action invoke bluepic/processImage -p imageId <image id>  
```

This delegates to the following actions and updates data accordingly:

* `bluepic/cloudantRead` - read image document from cloudant
* `bluepic/weather` - request weather data for location
* `bluepic/visualRecognition` - request Visual Recognition tagging for image
* `bluepic/cloudantWrite` - save data back to Cloudant
* `bluepic/kituraRequestAuth` - request auth credentials for Kitura from App ID
* `bluepic/kituraCallback` - make request back to Kitura server to invoke push notification service

# Debugging/Monitoring

For general Cloud Functions details, be sure to review the complete [Cloud Functions documentation](https://new-console.ng.bluemix.net/docs/openwhisk/index.html)

You can monitor Cloud Functions activity using the [IBM Cloud Cloud Functions Dashboard](https://new-console.ng.bluemix.net/openwhisk/dashboard), or by using the command line `bx wsk activation poll` command.  The dashboard provides a visual experience where you can drill into details for each request.  The CLI command provides you with a sequential output stream.  

There are two very important things to know when developing Cloud Functions actions:
* Swift compiler error messages are in both the `bx wsk activation poll` output, and also in the stderr result of the `bx wsk action invoke` command.  Pay attention to both.
* Swift `print()` or Node.js `console.log()` commands invoked from inside of Cloud Functions actions will also be visible in the `bx wsk activation poll` output. In Swift, if your print statements aren't working, try adding this `setbuf(stdout, nil)` before logging anything.

These can be extremely helpful for debugging Cloud Functions actions.  Since you cannot connect a debugger with breakpoints to an Cloud Functions action, excessive use of print() statements and using early `return` values at interim steps are your best routes for debugging values during Cloud Functions development - just be sure to remove or comment-out your debug `return` statements before making the actions live for production use.

Fortunately, the [CloudFunctions editor](https://console.ng.bluemix.net/openwhisk/editor) allows for running debugging tests quickly on a specific action.

## Debugging Actions & Flow

The following actions are used in development of the Cloud Functions:

---

#### bluepic/processImage
The main orchestrator

```
bx wsk action invoke bluepic/processImage -p imageId <image id>  
```

parameters:

* *imageId* = the id of the cloudant document to be processed

---


#### bluepic/cloudantRead
Read a document from Cloudant

```
bx wsk action invoke bluepic/cloudantRead -p cloudantId <cloudant id>  
```

parameters:

* *cloudantId* = the id of the cloudant document to be read and returned

---

#### bluepic/cloudantWrite
Write a document from Cloudant

```
bx wsk action invoke bluepic/cloudantRead -p cloudantId <cloudant id>  -p cloudantBody <document>
```

parameters:

* *cloudantId* = the id of the cloudant document to be read and returned
* *cloudantBody* = the document JSON string to be written

---

#### bluepic/weather
Retrieve weather data from Weather Company Data service

```
bx wsk action invoke bluepic/weather -p latitude <latitude>  -p longitude <longitude>
```

parameters:

* *latitude* = latitude for location to fetch weather
* *longitude* = longitude for location to fetch weather

---

#### bluepic/visualRecognition
Fetch Watson Visual Recognition image tagging results

```
bx wsk action invoke bluepic/visualRecognition -p imageURL <imageURL>
```

parameters:

* *imageURL* = url for publicly accessible image to be processed

---

#### bluepic/kituraRequestAuth
Fetch App ID authorization headers for calling back to kitura server

```
bx wsk action invoke bluepic/kituraRequestAuth
```

parameters:

* _none - this uses bound parameters from installation script_

---

#### bluepic/kituraCallback
Callback to Kitura server to notify that async processing is complete

```
bx wsk action invoke bluepic/kituraCallback -p cloudantId <cloudant id> -p authHeader <authorization header>
```

parameters:

* *cloudantId* = the id of the image document to notify Kitura about
* *authHeader* = the authorization header retrieved from bluepic/kituraRequestAuth
