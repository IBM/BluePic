/*
*     Copyright 2015 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/

import Foundation
import BMSCore

public protocol AuthenticationDelegate{
   
    /**
        Called when authentication challenge was received. The implementor should handle the challenge and call AuthenticationContext:submitAuthenticationChallengeAnswer(answer:[String:AnyObject]?)}
             with authentication challenge answer.
     
        - Parameter authContext  - Authentication context the answer should be sent to.
        - Parameter challenge - Information about authentication challenge.
     */
    
    func onAuthenticationChallengeReceived(authContext : AuthenticationContext, challenge : AnyObject)
    
    /**
        Called when authentication succeeded.
        - Parameter info - Extended data describing the authentication success.
    */
    
    func onAuthenticationSuccess(info : AnyObject?)
    
    /**
        Called when authentication fails.
        - Parameter info - Extended data describing authentication failure.
    */
    
    func onAuthenticationFailure(info : AnyObject?)

}