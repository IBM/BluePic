# Installing OpenWhisk Actions

Install using the bluepic.sh shell script:

```./bluepic.sh --install``` 

Don't forget to set configuration variables (auth creds, etc...) inside of local.env.

## Actions

The following actions are created by the shell script:

---
### processEntry

A sequence of individual actions: 
* bluepic/cloudantRead
* bluepic/weather
* bluepic/alchemy
* bluepic/cloudantWrite

---

### httpGet

Just a test sample to make sure Swift 3 actions with HTTP support using KituraNet is available.


---
### weather 

Action to retrieve current weather observations.  

```wsk action invoke -b bluepic/weather -p latitude 45 -p longitude -75```

Parameters

* latitude
* longitude
* units
* language

See details about weather service documentation here: https://console.ng.bluemix.net/docs/services/Weather/weather_rest_apis.html#rest_apis 

---
### alchemy

Image tagging using the Alchemy Vision services. 

*NOT IMPLEMENTED YET*

---
### cloudantRead

Read data from Cloudant

*NOT IMPLEMENTED YET*

---
### cloudantWrite

Write data to Cloudant

*NOT IMPLEMENTED YET*