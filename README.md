#Kitura BluePic

Kitura BluePic is a sample application for iOS that shows you how to connect your mobile application with Kitura server written in Swift. Kitura BluePic is based on [BluePic](./Original-README.md) app. It is a photo sharing app that allows you to take photos, upload them and share them with the SwiftBluePic community.

## Table of Contents

* [Requirements](#requirements)
* [Getting Started](#getting-started)
* [Using Kitura BluePic](#using-kitura-bluepic)
* [Project Structure](#project-structure)
* [Architecture](#architecture)
* [License](#license)

## Requirements

- [Kitura](https://github.com/IBM-Swift/Kitura-BluePic)
- [Kitura CouchDB](https://github.com/IBM-Swift/Kitura-CouchDB)
- [Kitura Redis](https://github.com/IBM-Swift/Kitura-redis)

## Getting Started

#### 1. Install CouchDB and Redis
[CouchDB installation instructions](https://wiki.apache.org/couchdb/Installation).

[Redis installation instructions](http://redis.io/download).

#### 2. Clone the Kitura-Bluepic Git repository

```bash
cd <some directory>
git clone https://github.com/IBM-Swift/Kitura-BluePic
```

#### 3. Configure the SwiftBluePic-server

Update in the `SwiftBluePic-server/config.json` file in your cloned repository:

1. The CouchDB server's IP address and port
2. The name of the CouchDB database you want to use

As in the following example:

```json
{
  "couchDbIpAddress": "<CouchDB IP Address>",
  "couchDbPort": 5984,
  "couchDbDbName": "swift-bluepic"
}
```

#### 4. Build the SwiftBluePic-server

To build the SwiftBluePic-server, you need to have your environment set up to build Kitura applications.

[Getting started with Kitura](https://github.com/IBM-Swift/Kitura)

In `SwiftBluePic-server` directory of the cloned repository run

```bash
swift build
make
```

#### 5. Run the SwiftBluePic-server

In `SwiftBluePic-server` directory of the cloned repository run

```
.build/debug/SwiftBluePic-server
```

#### 6. Setup the CouchDB database
For now, until we have a web based admin UI, you will need to run
```
 curl -X POST http://localhost:8090/admin/setup
```

## Using Kitura BluePic

### Facebook Login
SwiftBluePic was designed so that anyone can quickly launch the app and view photos posted without needing to log in. However, to view the profile or post photos, the user can easily login with his/her Facebook account. This is only used for a unique user id, the user's full name, as well as to display the user's profile photo.

<p align="center">
<img src="img/SwiftBluePic-screen.jpg"  alt="Drawing" height=550 border=0 /></p>
<p align="center">Figure 1. Welcome page.</p>

<br>

### View Feed
The feed (first tab) shows all the latest photos posted to the SwiftBluePic community (regardless if logged in or not).

<p align="center">
<img src="img/feed.PNG"  alt="Drawing" height=550 border=0 /></p>
<p align="center">Figure 2. Main feed view.</p>

### Post a Photo
Posting to the SwiftBluePic community is easy. Tap the middle tab in the tab bar and choose to either Choose a photo from the Camera Roll or Take a photo using the device's camera. You can then give the photo a caption before posting.

<p align="center">
<img src="img/post.PNG"  alt="Drawing" height=550 border=0 /></p>
<p align="center">Figure 3. Posting a photo.</p>

### View Profile
By tapping the third tab, you can view your profile. This shows your Facebook profile photo, lists how many photos you've posted, and shows all the photos you've posted to SwiftBluePic.

<p align="center">
<img src="img/profile.PNG"  alt="Drawing" height=550 border=0 /></p>
<p align="center">Figure 4. Profile feed.</p>

<br>
## Project Structure
* `/SwiftBluePic-iOS` directory for the iOS client.
* `/SwiftBluePic-server` directory for the SwiftBluePic-server.
* `/img` directory for images for this README.

<br>
## Architecture

<p align="center">
<img src="img/Swift-BluePic.jpg"  alt="Drawing" height=400 border=0 /></p>
<p align="center">Figure 5. Swift-BluePic Architecture Diagram.</p>


<br>
## License
This library is licensed under Apache 2.0. Full license text is
available in [LICENSE](LICENSE).
