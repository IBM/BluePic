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

/// This class represents the base app identity class, with default methods and keys

public class MCAAppIdentity : BaseAppIdentity{
    
    public override init() {
        let appInfo = Utils.getApplicationDetails()
        let dict:[String : String] = [
            BaseAppIdentity.ID : appInfo.name,
            BaseAppIdentity.VERSION : appInfo.version
        ]
        super.init(map: dict)
    }
    
    public override init(map: [String : AnyObject]?) {
        super.init(map: map)
    }
    
}
