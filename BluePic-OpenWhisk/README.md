# Setup OpenWhisk

1) Create an OpenWhisk account at: https://new-console.ng.bluemix.net/openwhisk/ 

2) Download and install the OpenWhisk CLI following the instructions at: https://new-console.ng.bluemix.net/openwhisk/cli 


# Installing OpenWhisk Actions

Install using the bluepic.sh shell script:

    ./bluepic.sh --install


Remove actions using the bluepic.sh shell script:

    ./bluepic.sh --uninstall


Remove and reinstall actions using the bluepic.sh shell script:

    ./bluepic.sh --reinstall

You will also need to set configuration variables (auth creds, etc...) inside of the `local.env` file.  All of these values can be obtained from the "Connections" tab when viewing the Bluemix app with your provisioned services.

For `Cloudant` you will need
* username with read/write access
* password
* host (root for your cloudant instance.  ex:d60741e4-629e-48e4-aa5d-da6e7557d5b5-bluemix.cloudant.com)
* cloudant db name (default bluepic_db)

For `Alchemy` you will need:
* api key - this is from your Alchemy service instance

For `Weather Insights` you will need:
* username 
* password

For `Mobile Client Access` you will need:
* client id - this is the unique guid for your app instance 
* secret - secret key from configuring the MCA service

For the `Kitura` callback you will need:
* host - ex:  bluepic-grotty-substantiality.mybluemix.net
* port - (80 if http, 443 is https, other if dev)
* schema - (http:// or https://)


# Actions

Several actions are created by the shell script.  The most important of which is the `bluepic/processImage` sequence:

This is a sequence of individual actions that process the image entry for bluepic through its entirety.

To invoke the sequence, you just need to pass in an `imageId` parameter - this is the ID of the cloudant document for the image that needs to be processed.

From the CLI, this can be invoked as (you'll need to use your own image id):
  
    wsk action invoke processImage -p imageId 77fe40ac39e690328bf0ad978439ecd0  

This sequence is made up of the following actions.
 
* `bluepic/prepareReadImage` - prepare params to read image from cloudant
* `bluepic/cloudantRead` - read image document from cloudant
* `bluepic/prepareWeatherRequest` - prepare request to weather and alchemy services based on data from retrieved image document
* `bluepic/weather` - request weather data for location
* `bluepic/alchemy` - request alchemy tagging for image
* `bluepic/prepareCloudantWrite` - merge alchemy and and weather data into the Cloduant document JSON/prepare for writing back to cloudant
* `bluepic/cloudantWrite` - save data back to Cloudant
* `bluepic/kituraCallback` - make request back to Kitura server to invoke push notification service


# Debugging/Development

Each individual action can be invoked separately from the sequence.  Parameters will need to be passed in to each individual action.  You will need to view source for each action to see required parameters.

You can view the debug console (print statements) using the OpenWhisk CLI command `wsk activation poll`. 

Sequences have also been created specifically for debugging, which process the request incrementally through each step. Each of the following sequences can be invoked, with the only required parameter passed in being the imageId, exactly as the main `processImage` sequence is shown above:

    wsk action invoke {sequence name} -p imageId {cloudant document id}  

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