/*
*     Copyright 2015 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http:www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/

import Foundation

public protocol AuthenticationContext {
    
    /**
     Submits authentication challenge response.
     - Parameter answer - Dictionary with challenge responses
     */
    
    func submitAuthenticationChallengeAnswer(answer:[String:AnyObject]?)
    
    /**
     Informs client about successful authentication.
     */
    
    func submitAuthenticationSuccess ()
    
    /**
     Informs client about failed authentication.
     - Parameter info - Dictionary with extended information about failure
     */
    
    func submitAuthenticationFailure (info:[String:AnyObject]?)
}