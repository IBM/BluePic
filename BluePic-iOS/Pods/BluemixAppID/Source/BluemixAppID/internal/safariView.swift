/* *     Copyright 2016, 2017 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import Foundation
import SafariServices
import BMSCore

internal class safariView : SFSafariViewController, SFSafariViewControllerDelegate {
    
    var authorizationDelegate:AuthorizationDelegate?

    public init(url URL: URL) {
        super.init(url: URL, entersReaderIfAvailable: false)
        self.delegate = self
    }
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        authorizationDelegate?.onAuthorizationCanceled()
    }

}
