# BluePic

## Overview

BluePic is a sample application that shows how quickly and simple it is to get started developing with Bluemix services. It is a photo sharing application that allows you to take photos and upload them to a server.

## Getting Started

Click the Deploy to Bluemix button in order to create an application on your personal Bluemix account that's already set up with the required services.

The button will also create a DevOps Services project and link it to the newly created application.

[![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/rolandoasmat/MyBluemixApp.git)

## Forethought

For BluePic, we used a simple architecture where there is no middle tier component between the mobile app and the storage components (e.g. Cloudant) on the server. To roll out BluePic to a production environment, a few architectural changes should be made.

Cloudant Sync requires a complete replica of the database on each mobile client. This may not be feasible for apps with large databases. Under such scenarios, instead of leveraging Cloudant Sync, the REST API provided by Cloudant could be used to perform CRUD and query operations against the remote Cloudant instance. Having said this, the Cloudant team is planning to introduce new capabilities [in 2016] for Cloudant Sync that should securely replicate subsets of a large remote database onto devices. Though replicating subsets of records can be done today with Cloudant Sync, doing so with with large databases where only a small subset of records should be replicated can introduce performance problems. New functionality that is expected to be delivered next year by the Cloudant team should address such performance issues. 

Using Cloudant Sync without an additional middle tier component between the mobile app and the database requires the mobile code to know the username and password for accessing the Cloudant database. This will lead to security breaches if someone gets their hands on those credentials. Hence, security could be a reason for having all database operations go first through a middleware component (e.g. Liberty, Node.js) to verify that only authenticated and authorized users of the app can perform such operations. In this architecture, the credentials to access the database are only known by the middleware component.

## Documentation

## Project Structure

## License
