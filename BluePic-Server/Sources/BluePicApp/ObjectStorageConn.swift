/**
* Copyright IBM Corporation 2016, 2017
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import BluemixObjectStorage
import LoggerAPI
import Dispatch
import CloudEnvironment

public struct ObjectStorageConn {
  let connectQueue = DispatchQueue(label: "connectQueue")
  let objStorage: ObjectStorage
  let connProps: ObjectStorageCredentials
  private var authenticated: Bool = false
  // FIXME: Accessing Date object more than once will cause seg fault, related to https://bugs.swift.org/browse/SR-2462
  private var lastAuthenticatedTs: Date?

  init(credentials: ObjectStorageCredentials) {
    connProps = credentials
    objStorage = ObjectStorage(projectId: connProps.projectID)
  }

  mutating func getObjectStorage(completionHandler: @escaping (_ objStorage: ObjectStorage?) -> Void) {
    Log.verbose("Starting task in serialized block (getting ObjectStorage instance)...")
    connectQueue.sync {
        self.connect(completionHandler: completionHandler)
    }
    Log.verbose("Completed task in serialized block.")
    let param: ObjectStorage? = (authenticated) ? objStorage : nil
    completionHandler(param)
  }

  private mutating func connect(completionHandler: (_ objStorage: ObjectStorage?) -> Void) {
    Log.verbose("Determining if we have an ObjectStorage instance ready to use...")
    if authenticated, let lastAuthenticatedTs = lastAuthenticatedTs {
      // Check when was the last time we got an auth token
      // If it's been less than 50 mins, then reuse auth token.
      // This logic is just a stopgap solution to avoid requesting a new
      // authToken for every ObjectStorage request.
      // The ObjectStorage SDK will contain logic for handling expired authToken
      let timeDiff = lastAuthenticatedTs.timeIntervalSinceNow
      let minsDiff = Int(fabs(timeDiff / 60))
      if minsDiff < 50 {
        Log.verbose("Reusing existing Object Storage auth token...")
        return
      }
    }

    // Network call should be synchronous since we need to know the result before proceeding.
    let semaphore = DispatchSemaphore(value: 0)
    var copy = self
    Log.verbose("Making network call synchronous...")
    objStorage.connect(userId: connProps.userID, password: connProps.password, region: ObjectStorage.REGION_DALLAS) { error in
      if let error = error {
        let errorMsg = "Could not connect to Object Storage."
        Log.error("\(errorMsg) Error was: '\(error)'.")
        copy.authenticated = false
      } else {
        Log.verbose("Successfully obtained authentication token for Object Storage.")
        copy.authenticated = true
        copy.lastAuthenticatedTs = Date()
      }
      Log.verbose("Signaling semaphore...")
      semaphore.signal()

    }

    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    self = copy
    Log.verbose("Continuing execution after synchronous network call...")
  }

}
