# Setup OpenWhisk
1) Create an OpenWhisk account on the [Welcome to Bluemix OpenWhisk](https://new-console.ng.bluemix.net/openwhisk/) page.

2) Download and install the [OpenWhisk CLI](https://new-console.ng.bluemix.net/openwhisk/cli).

3) On that same [OpenWhisk CLI](https://new-console.ng.bluemix.net/openwhisk/cli) page, you can find the values needed to populate the [properties.json](../BluePic-Server/properties.json) file under the `Bluepic-Server` directory.

1. In step 2 on the "OpenWhisk - Configure CLI" page, you will see a command that looks similar to:

    `wsk property set --apihost <hostName> --auth <authKey> --namespace "<namespace>"`

2. Take the value after `--apihost` and put it as the `hostName` value in `properties.json`.
3. Next, insert the value after `--namespace`, within the existing `urlPath` value in `properties.json`. In the `<namespace>` spot to be exact:
`"/api/v1/namespaces/<namespace>/actions/bluepic/processImage?blocking=false"`
4. Lastly, take the value after `--auth` and put it as the `authToken` value in `properties.json`. That value will later be converted to a base64 encoded string that OpenWhisk needs for authentication.


# Installing OpenWhisk Actions for BluePic
## Service Credentials
Before you run the installation script, you will first need to set configuration variables (e.g. cloudant credentials, object storage credentials, etc.) inside of the `local.env` file.  All of these values can be obtained from the `Connections` tab when viewing the Bluemix app with your provisioned services.

For `Cloudant` you will need:
* username (with read/write access)
* password
* host (hostname for your cloudant instance, such as `d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com`)
* cloudant database name (default `bluepic_db`)

For `Alchemy` you will need:
* api key - this is from your Alchemy service instance

    *Note:* If you get an error message that says `Only one free key is allowed per account in a 24-hour period` when creating your Alchemy service instance, then be sure to check if you already have an Alchemy service created for your Bluemix account.  Only one Alchemy service instance is allowed per Bluemix account. You can reuse your Alchemy key from an existing app without having to create a new Alchemy instance. This error message is misleading because you won't be able to create a new Alchemy instance in 24 hours.

For `Weather Insights` you will need:
* username
* password

For `Mobile Client Access` you will need:
* client id - this is the unique GUID for your app instance
* secret - secret key from configuring the MCA service

For the `Kitura` callback you will need to obtain the route for your Bluemix application. You can find the route by clicking on the `View App` button near the top right of your application's dashboard page on Bluemix. This will open the welcome page for the BluePic app; the route is the URL value shown on the browser, which consists of the schema, host, and port (please note that port values 80 and 443 maybe not be shown in the URL in the browser since these are the default port values for http and https respectively):
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
The overall processing of an image is handled by a sequence comprised of single-purpose OpenWhisk actions.  Each individual action can be invoked separately from the sequence. Parameters will need to be passed in to each individual action.  

The `bluepic.sh` shell script is used to create all sequences and actions used by the BluePic app.  The most important of which is the `bluepic/processImage` sequence. This is a sequence of individual actions that process the image entry for BluePic through its entirety.

To invoke the sequence, you just need to pass in an `imageId` parameter (i.e. ID of the cloudant document for the image that needs to be processed).

From the CLI, this can be invoked as (you'll need to use your own image id):

```
wsk action invoke processImage -p imageId <image id>  
```

This sequence is made up of the following actions.

* `bluepic/prepareReadImage` - prepare params to read image from cloudant
* `bluepic/cloudantRead` - read image document from cloudant
* `bluepic/prepareWeatherRequest` - prepare request to weather and alchemy services based on data from retrieved image document
* `bluepic/weather` - request weather data for location
* `bluepic/alchemy` - request alchemy tagging for image
* `bluepic/prepareCloudantWrite` - merge alchemy and and weather data into the Cloudant document JSON/prepare for writing back to cloudant
* `bluepic/cloudantWrite` - save data back to Cloudant
* `bluepic/kituraRequestAuth` - request auth crednetials for Kitura from MCA
* `bluepic/kituraCallback` - make request back to Kitura server to invoke push notification service

# Debugging/Monitoring

For general OpenWhisk details, be sure to review the complete [OpenWhisk documentation](https://new-console.ng.bluemix.net/docs/openwhisk/index.html)

You can monitor OpenWhisk activity using the [IBM Bluemix OpenWhisk Dashboard](https://new-console.ng.bluemix.net/openwhisk/dashboard), or by using the commdand line `wsk activation poll` command.  The dashboard provides a visual experience where you can drill into details for each request.  The CLI command provides you with a sequential output stream.  

There are two very important things to know when developing OpenWhisk actions:
* Swift compiler error messages are in both the `wsk activation poll` output, and also in the stderr result of the `wsk action invoke` command.  Pay attention to both.
* Swift `print()` or Node.js `console.log()` commands invoked from inside of OpenWhisk actions will also be visible in the `wsk activation poll` output.

These can be extremely helpful for debugging OpenWhisk actions.  Since you cannot connect a debugger with breakpoints to an OpenWhisk action, excessive use of print() statements and using early `return` values at interim steps are your best routes for debugging values during OpenWhisk development - just be sure to remove or comment-out your debug `return` statements before making the actions live for production use.

## Debugging Sequence Logic & Flow

The following sequences have also been created specifically for debugging, which process the request incrementally through each step. You will need to view source for each action to see specific parameters for each step, but all of sequences except for `bluepic/processCallback` can be invoked with the only required parameter passed in being the imageId, exactly as the main `processImage` sequence shows above:

```
wsk action invoke {sequence name} -p imageId {cloudant document id}  
```

 * `bluepic/processRequestThroughReadImage`
    * prepareReadImage
    * cloudantRead
 * `bluepic/processRequestToWeather`
    * prepareReadImage
    * cloudantRead
    * prepareWeatherRequest
 * `bluepic/processRequestThroughWeather`
    * prepareReadImage
    * cloudantRead
    * prepareWeatherRequest
    * weather
 * `bluepic/processRequestThroughAlchemy`
    * prepareReadImage
    * cloudantRead
    * prepareWeatherRequest
    * weather
    * alchemy
 * `bluepic/processRequestToCloudantWrite`
    * prepareReadImage
    * cloudantRead
    * prepareWeatherRequest
    * weather
    * alchemy
    * prepareCloudantWrite
 * `bluepic/processRequestThroughCloudantWrite`
    * prepareReadImage
    * cloudantRead
    * prepareWeatherRequest
    * weather
    * alchemy
    * prepareCloudantWrite
    * cloudantWrite
 * `bluepic/processCallback`
    * `bluepic/kituraRequestAuth`
    * `bluepic/kituraCallback`
