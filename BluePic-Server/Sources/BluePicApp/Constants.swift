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


/** Enum error used to inform of an invalid reading/processing error
   Used when image data isn't what was expected
   Used when User data isn't what was expected
*/
enum ProcessingError: Error {
  case image(String)
  case user(String)
}

/// Enum expressing blue pic I/O errors
enum BluePicError: Error {
  case IO(String)
}

/// Enum identifying Cloudant Views
enum View: String {
  case images           = "images"
  case images_by_id     = "images_by_id"
  case images_by_tag    = "images_by_tags"
  case images_per_user  = "images_per_user"
  case tags             = "tags"
  case users            = "users"
}
