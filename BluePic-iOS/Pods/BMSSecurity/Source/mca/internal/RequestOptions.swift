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

//  Created by Ilan Klein on 12/21/2015.

import Foundation
import BMSCore

internal class RequestOptions {
    
    internal var requestMethod : HttpMethod
    internal var timeout : Double = 0
    internal var headers = [String : String]()
    internal var parameters = [String : String]()
    
    internal init(requestMethod : HttpMethod = HttpMethod.GET) {
        self.requestMethod = requestMethod
    }
}