/**
* Copyright IBM Corporation 2016
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

struct BluePic {
  static let Domain = "BluePic-Server"
  /**
   Enum error specifically for BluePic app
   
   - Internal: used to indicate internal error of some sort
   - Other:    any other type of error
   */
  enum Error: Int {
    case Internal = 1
    case Other
  }
}

/**
 Enum error used to inform of an invalid reading/processing error
 
 - Image: Used when image data isn't what was expected
 - User:  Used when User data isn't what was expected
 */
enum ProcessingError: ErrorProtocol {
  case Image(String)
  case User(String)
}
