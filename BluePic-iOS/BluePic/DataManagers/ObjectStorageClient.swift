/**
 * Copyright IBM Corporation 2015
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
 **/


import Foundation
import Alamofire

/**
 * Convenience class for querying the Object Storage service on Bluemix.
 */
class ObjectStorageClient {
    
    /**
     * Instance variables for this class.
     */
    var userId:String  // The userid associated with the Object Storage account.
    var password:String // The password for the userid.
    var projectId:String    // The project unique identifier.
    var authURL:String  // The authentication URL; this is the URL that returns the auth token
    var publicURL:String   // The endpoint that shall be used for all query and update operations.
    var token:String?   // The authentication token returned from the Object Storage service.
    
    /**
     * Constructor for the class.
     */
    init(userId: String, password: String, projectId: String, authURL: String, publicURL: String) {
        self.userId = userId
        self.password = password
        self.authURL = authURL
        self.publicURL = publicURL
        self.projectId = projectId
    }
    
    /**
     * Gets authentication token from Object Storage service and stores it as an instance variable. This method must
     * be called before executing any of the othe instance methods of this class.
     */
    func authenticate(onSuccess: () -> Void, onFailure: (error: String) -> Void) {
        // Define NSURL and HTTP request type
        let nsURL = NSURL(string: authURL)!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "POST"
        mutableURLRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        let jsonPayload = "{ \"auth\": { \"identity\": { \"methods\": [ \"password\" ], \"password\": { \"user\": { \"id\": \"\(userId)\", \"password\": \"\(password)\" } } }, \"scope\": { \"project\": { \"id\": \"\(projectId)\" } } } }"
        
        mutableURLRequest.HTTPBody = jsonPayload.dataUsingEncoding(NSUTF8StringEncoding)
        
        self.executeCall(mutableURLRequest, successCodes: [201],
            onSuccess: { (responseHeaders) in
                if let headers = responseHeaders {
                    if let authToken = headers["X-Subject-Token"] as? String {
                        self.token = authToken
                        print("Object Storage auth token: \(authToken)")
                        onSuccess()
                        return
                    }
                }
                onFailure(error: "Could not get authentication token from Object Storage service. In the response, there was no header with the auth token value!")
            },
            onFailure: { (errorMsg) in
                onFailure(error: "Could not get authentication token from Object Storage service: \(errorMsg)")
        })
    }
    
    func isAuthenticated() -> Bool {
        return (self.token != nil)
    }
    
    /**
     * Creates a container on the Object Storage service. The name of the container should be the facebook userID
     * of the logged on user.
     * 
     * @param name The name for the container. For BluePic, this should be the facebook userID.
     * @param onSuccess Closure that should be invoked upon succcessful completion.
     * @param onFailure Closure that should be invoked upon failure.
     */
    func createContainer(name: String, onSuccess: (name: String) -> Void, onFailure: (error: String) -> Void) {
        let nsURL = NSURL(string: "\(publicURL)/\(name)")!
        print("Container creation URL: \(nsURL)")
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "PUT"
        mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        mutableURLRequest.setValue("0", forHTTPHeaderField: "Content-Length")
        self.executeCall(mutableURLRequest, successCodes: [201, 202],
            onSuccess: { (headers) in
                self.configureContainerForWebHosting(name, onSuccess: onSuccess, onFailure: onFailure)
            },
            onFailure: { (errorMsg) in
                onFailure(error: "Could not create container '\(name)': \(errorMsg)")
        })
    }
    
    /**
     * Configures the specified container on the Object Storage service for web hosting. This step is needed
     * so we can serve images via URLs. In most cases, clients won't have to invoke this method since the
     * createContainer method invokes this method as part of the creation of the container.
     *
     * @param name The name for the container.
     * @param onSuccess Closure that should be invoked upon succcessful completion.
     * @param onFailure Closure that should be invoked upon failure.
     */
    func configureContainerForWebHosting(name: String, onSuccess: (name : String) -> Void, onFailure: (error: String) -> Void) {
        let nsURL = NSURL(string: "\(publicURL)/\(name)")!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "POST"
        mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        mutableURLRequest.setValue("true", forHTTPHeaderField: "X-Container-Meta-Web-Listings")
        self.executeCall(mutableURLRequest, successCodes: [204],
            onSuccess: { (headers) in
                self.configureContainerForPublicAccess(name, onSuccess: onSuccess, onFailure: onFailure)
            },
            onFailure: { (errorMsg) in
                onFailure(error: "Could not update configuration for container '\(name)': \(errorMsg)")
        })
    }
    
    /**
     * Configures the specified container on the Object Storage service for public access. This step is needed
     * so we can serve images via URLs. In most cases, clients won't have to invoke this method since the
     * createContainer method invokes this method as part of the creation of the container.
     *
     * @param name The name for the container.
     * @param onSuccess Closure that should be invoked upon succcessful completion.
     * @param onFailure Closure that should be invoked upon failure.
     */
    func configureContainerForPublicAccess(name: String, onSuccess: (name: String) -> Void, onFailure: (error: String) -> Void) {
        let nsURL = NSURL(string: "\(publicURL)/\(name)")!
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "POST"
        mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        mutableURLRequest.setValue(".r:*,.rlistings", forHTTPHeaderField: "X-Container-Read")
        self.executeCall(mutableURLRequest, successCodes: [204],
            onSuccess: { (headers) in
                onSuccess(name: name)
            },
            onFailure: { (errorMsg) in
                onFailure(error: "Could not update configuration for container '\(name)': \(errorMsg)")
        })
    }
    
    /**
     * Convenience method for executing REST calls against the Object Storage service on Bluemix. All methods in this class
     * levegare this method to avoid code duplication.
     *
     * @param mutableURLRequest An instance of the NSMutableURLRequest class that specifies the configuration to use for the HTTP REST call.
     * @param successCodes An integer array that specificies which HTTP return codes should be considered successful for the given invocation.
     * @param onSuccess Closure that should be invoked upon succcessful completion.
     * @param onFailure Closure that should be invoked upon failure.
     */
    private func executeCall(mutableURLRequest: NSMutableURLRequest, successCodes: [Int],
        onSuccess: (headers: [NSObject : AnyObject]?) -> Void, onFailure: (error: String) -> Void) {
            // Fire off HTTP request
            Alamofire.request(mutableURLRequest).responseJSON {response in
                // Get http response status code
                var statusCode:Int = 0
                if let httpResponse = response.response {
                    statusCode = httpResponse.statusCode
                }
                print("statusCode = \(statusCode)")
                // For a production app, we would need to verify if the auth token has expired;
                // if so, then the code should re-authenticate and retry the current operation
                // For this demo app, we did not get to implement this logic.
                
                let statusCodeIndex = successCodes.indexOf(statusCode)
                if (statusCodeIndex != nil) {
                    var headers:[NSObject : AnyObject]? = nil
                    if let httpResponse = response.response {
                        headers = httpResponse.allHeaderFields
                    }
                    onSuccess(headers: headers)
                    return
                }
                
                // If this code is getting executed, then an error occurred...
                var errorMsg = "[No error info available]"
                if let error = response.result.error {
                    errorMsg = error.localizedDescription
                }
                print("REST method invocation failure: \(errorMsg)")
                onFailure(error: errorMsg)
            }
    }
    
    /**
     * Uploads given UIImage object to the Object Storage service on Bluemix. Before doing so, this method creates a PNG
     * representation of the image.
     *
     * @param containerName The name of the container to which to upload the image.
     * @param imageName The name of the image that shall be used to persist it.
     * @param image An instance of the UIImage class. Contains the actual image to store.
     * @param onSuccess Closure that should be invoked upon succcessful completion.
     * @param onFailure Closure that should be invoked upon failure.
     */
    func uploadImage(containerName: String, imageName: String, image: UIImage,
        onSuccess: (imageURL: String) -> Void, onFailure: (error: String) -> Void) {
            let imageData = UIImagePNGRepresentation(image)
            let imageURL = "\(publicURL)/\(containerName)/\(imageName)"
            let nsURL = NSURL(string: imageURL)!
            let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
            mutableURLRequest.HTTPMethod = "PUT"
            mutableURLRequest.setValue(token, forHTTPHeaderField: "X-Auth-Token")
            mutableURLRequest.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            mutableURLRequest.HTTPBody = imageData
            self.executeCall(mutableURLRequest, successCodes: [201],
                onSuccess: { (headers) in
                    onSuccess(imageURL: imageURL)
                },
                onFailure: { (errorMsg) in
                    onFailure(error: "Could not upload image to container: \(errorMsg)")
            })
    }
}