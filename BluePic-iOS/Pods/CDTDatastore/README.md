# CDTDatastore

[![Version](http://cocoapod-badges.herokuapp.com/v/CDTDatastore/badge.png)](http://cocoadocs.org/docsets/CDTDatastore)
[![Platform](http://cocoapod-badges.herokuapp.com/p/CDTDatastore/badge.png)](http://cocoadocs.org/docsets/CDTDatastore)
[![Build Status](https://travis-ci.org/cloudant/CDTDatastore.png?branch=master)](https://travis-ci.org/cloudant/CDTDatastore)

**Applications use Cloudant Sync to store, index and query local JSON data on a
device and to synchronise data between many devices. Synchronisation is under
the control of the application, rather than being controlled by the underlying
system. Conflicts are also easy to manage and resolve, either on the local
device or in the remote database.**

Cloudant Sync is an [Apache CouchDB&trade;][acdb]
replication-protocol-compatible datastore for
devices that don't want or need to run a full CouchDB instance. It's built
by [Cloudant](https://cloudant.com), building on the work of many others, and
is available under the [Apache 2.0 licence][ap2].

[ap2]: https://github.com/cloudant/sync-android/blob/master/LICENSE
[acdb]: http://couchdb.apache.org/

The API is quite different from CouchDB's; we retain the
[MVCC](http://en.wikipedia.org/wiki/Multiversion_concurrency_control) data
model but not the HTTP-centric API.

This library is for iOS, an [Android version][android] is also available.

[android]: https://github.com/cloudant/sync-android

If you have questions, please join our [mailing list][mlist] and drop us a
line.

[mlist]: https://groups.google.com/forum/#!forum/cloudant-sync

## Using in your project

CDTDatastore is available through [CocoaPods](http://cocoapods.org), to install
it add the following line to your Podfile:

```ruby
pod "CDTDatastore"
```
Note: We only support building on the latest stable release of Xcode

[gs]: https://github.com/cloudant/CDTDatastore/wiki/Getting-Started

### Using in a Swift app

CDTDatastore is useable from Swift out of the box with a few small quirks. Install as per the
instructions above, and import CloudantSync.h into your [bridging header](https://developer.apple.com/library/ios/documentation/swift/conceptual/buildingcocoaapps/MixandMatch.html).

The [Overview](#overview) section below has examples in both Objective-C and Swift.

## Example project

There is an example project in the `Project` folder, for iOS 7. To get
this up and running independently of the main codebase, a Podfile is
included:

```bash
$ cd Project
$ pod install
$ open Project.xcworkspace
```

## Running the tests

See [CONTRIBUTING](CONTRIBUTING.md).

## Tested Platforms

CDTDatastore gets regularly tested on the following platforms:

- OS X 10.10.2 (Yosemite)
- iPhone 4S (Simulator), iOS 8.1 and 7.1
- iPhone 5 (Simulator), iOS 8.1 and 7.1
- iPhone 5S (Simulator), iOS 8.1 and 7.1
- iPhone 6 Plus (Simulator), iOS 8.1
- iPhone 6 (Simulator), iOS 8.1
- iPad 2 (Simulator), iOS 8.1 and 7.1
- iPad Air (Simulator), iOS 8.1 and 7.1
- iPad Retina (Simulator), iOS 8.1 and 7.1

## Cloudant and iOS 9

At the moment, Cloudant has a SHA1-signed SSL certificate. We are working
on rolling out a SHA2-signed certificate, but it's taking longer than
we'd hoped. So meanwhile, you unfortunately need to make an exception to
Apple's [App Transport Security](https://developer.apple.com/library/prerelease/ios/technotes/App-Transport-Security-Technote/index.html) to connect to Cloudant.

Add the following to your application's `info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSExceptionDomains</key>
    <dict>
        <key>cloudant.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

## <a name="overview"></a>Overview of the library

Once the libraries are added to a project, the basics of adding and reading
a document are:

```objc
#import <CloudantSync.h>

// Create a CDTDatastoreManager using application internal storage path
NSError *outError = nil;
NSFileManager *fileManager= [NSFileManager defaultManager];

NSURL *documentsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                           inDomains:NSUserDomainMask] lastObject];
NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"cloudant-sync-datastore"];
NSString *path = [storeURL path];

CDTDatastoreManager *manager =
[[CDTDatastoreManager alloc] initWithDirectory:path
                                         error:&outError];

CDTDatastore *datastore = [manager datastoreNamed:@"my_datastore"
                                            error:&outError];

// Create a document
CDTDocumentRevision *rev = [CDTDocumentRevision revisionWithDocId:@"doc1"];
// Use [CDTDocumentRevision revision] to get an ID generated for you on saving
rev.body = [@{
    @"description": @"Buy milk",
    @"completed": @NO,
    @"type": @"com.cloudant.sync.example.task"
} mutableCopy];

// Add an attachment -- binary data like a JPEG
CDTUnsavedFileAttachment *att1 = [[CDTUnsavedFileAttachment alloc]
                          initWithPath:@"/path/to/image.jpg"
                          name:@"cute_cat.jpg"
                          type:@"image/jpeg"];
rev.attachments[att1.name] = att;

// Save the document to the database
CDTDocumentRevision *revision = [datastore createDocumentFromRevision:rev
                                                                error:&error];
// `revision` will be `nil` on failures.

// Read a document
NSString *docId = revision.docId;
CDTDocumentRevision *retrieved = [datastore getDocumentWithId:docId
                                                        error:&error];
```

If you are using Swift, install the libraries as per the instructions above,
and configure a bridging header for your project. Pull in the CloudantSync.h
header into the bridging header, and you should be good to go:

```objc
#import <CloudantSync.h>
```

To add, and read documents in Swift, the basics are:

```swift
do {
    let fileManager = NSFileManager.defaultManager()

    let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
        inDomains: .UserDomainMask).last!

    let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
    let path = storeURL.path

    let manager = try CDTDatastoreManager(directory: path)
    let datastore = try manager.datastoreNamed("my_datastore")

    // Create a document
    let rev = CDTDocumentRevision(docId: "doc1")
    rev.body = ["description":"Buy Milk",
        "completed": false,
        "type":"com.cloudant.sync.example.task"]

    // Add an attachment - binary data like a JPEG
    let att1 = CDTUnsavedFileAttachment(path: "/path/to/image/jpg",
        name: "cute_cat.jpg",
        type: "image/jpeg")
    rev.attachments[att1.name] = att1

    // Save the document to the database
    let revision = try datastore.createDocumentFromRevision(rev)

    // Read a document
    let docId = revision.docId
    let retrieved = try datastore.getDocumentWithId(docId)


} catch {
    print("Encountered an error: \(error)")
}
```

Read more in [the CRUD document](https://github.com/cloudant/CDTDatastore/blob/master/doc/crud.md).

You can subscribe for notifications of changes in the database, which
is described in
[the events documentation](https://github.com/cloudant/cdtdatastore/blob/master/doc/events.md).
It's still a bit raw right now:

- You receive a notification for all new revisions in replication (which can be more
  than one per updated document).

### Replicating Data Between Many Devices

Replication is used to synchronise data between the local datastore and a
remote database, either a CouchDB instance or a Cloudant database. Many
datastores can replicate with the same remote database, meaning that
cross-device synchronisation is achieved by setting up replications from each
device the the remote database.

Replication is simple to get started in the common cases:

```objc
#import <CloudantSync.h>

// Create and start the replicator -- -start is essential!
CDTReplicatorFactory *replicatorFactory =
[[CDTReplicatorFactory alloc] initWithDatastoreManager:manager];

NSString *s = @"https://apikey:apipassword@username.cloudant.com/my_database";
NSURL *remoteDatabaseURL = [NSURL URLWithString:s];
CDTDatastore *datastore = [manager datastoreNamed:@"my_datastore"];

// Replicate from the local to remote database
CDTPushReplication *pushReplication = [CDTPushReplication replicationWithSource:datastore
                                                                         target:remoteDatabaseURL];
NSError *error;
CDTReplicator *replicator = [replicatorFactory oneWay:pushReplication error:&error];

//check error

// Start the replicator
[replicator start];
```
```swift
do {
    // Create and start the replicator -- -start is essential!
    let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)

    let s = "https://apikey:apipassword@username.cloudant.com/my_database"
    let remoteDatabaseURL = NSURL(string: s)
    let datastore = try manager.datastoreNamed("my_datastore");

    // Replicate from the local to remote database
    let pushReplication = CDTPushReplication(source: datastore, target: remoteDatabaseURL)
    let replicator =  try replicatorFactory.oneWay(pushReplication)

    // Start the replicator
    try replicator.start()


} catch {
    print("Encountered an error: \(error)")
}
```
Read more in [the replication docs](https://github.com/cloudant/CDTDatastore/blob/master/doc/replication.md).

### Finding data

Once you have thousands of documents in a database, it's important to have
efficient ways of finding them. We've added an easy-to-use querying API. Once
the appropriate indexes are set up, querying is as follows:

```objc
NSDictionary *query = @{
    @"name": @"John",         // name equals John
    @"age": @{ @"$gt" : @25}  // age greater than 25
};
CDTQResultSet *result = [datastore find:query];
[result enumerateObjectsUsingBlock:^(CDTDocumentRevision *rev, NSUInteger idx, BOOL *stop) {
    // do something
}];
```

```swift
let query = [
    "name" : "John", // name equals John
    "age" : ["$gt" : 25] // age greater than 25
]
let result = datastore.find(query)
result.enumerateObjectsUsingBlock({ (rev, idx, stop) -> Void in
    // do something
})
```

See [Index and Querying Data](https://github.com/cloudant/CDTDatastore/blob/master/doc/query.md).

As of version 0.16.0 the indexing and querying code has been re-written and
has more features than the previous implementation.  For details about
migrating to a 0.16.0+ indexing and query version from a previous version
see [Index and Querying Migration](https://github.com/cloudant/CDTDatastore/blob/master/doc/query-migration.md).

### Conflicts

An obvious repercussion of being able to replicate documents about the place
is that sometimes you might edit them in more than one place at the same time.
When the databases containing these concurrent edits replicate, there needs
to be some way to bring these divergent documents back together. Cloudant's
MVCC data-model is used to do this.

A document is really a tree of the document and its history. This is neat
because it allows us to store multiple versions of a document. In the main,
there's a single, linear tree -- just a single branch -- running from the
creation of the document to the current revision. It's possible, however,
to create further branches in the tree. At this point your document is
conflicted and needs some surgery to resolve the conflicts and bring it
back to full health.

- See [conflicts documentation](https://github.com/cloudant/CDTDatastore/blob/master/doc/conflicts.md).


## Requirements

All requirements are included in the source code or pulled in as dependencies
via `pod install`.

## Contributors

See [CONTRIBUTORS](CONTRIBUTORS).

## Contributing to the project

See [CONTRIBUTING](CONTRIBUTING.md).

## License

See [LICENSE](LICENSE)

### CDTDatastore classes and TouchDB classes

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

### Used libraries under different licences

* MYUtilities is licensed under the BSD licence (portions copied into vendor
  directory).
* FMDB, by Gus Mueller, is under the MIT License.
* Google Toolbox For Mac is under the Apache License 2.0.
