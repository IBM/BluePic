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
 **/

import Foundation

enum BluePicLocalizedError: LocalizedError {
  
  case getTagsFailed
  case noImagesByTag(String)
  case getAllImagesFailed
  case noImageId
  case noJsonData(String)
  case getUsersFailed
  case noUserId(String)
  case missingUserId
  case readDocumentFailed
  case addImageRecordFailed
  case getImagesFailed(String)
  case addUserRecordFailed(String)
  case requestFailed
  case createDatabaseObjectFailed(String)
  
  var errorDescription: String? {
    switch self {
    case .getTagsFailed: return "Failed to obtain tags from database."
    case .noImagesByTag(let tag): return "Failed to find images with tag: \(tag)."
    case .getAllImagesFailed: return "Failed to retrieve all images."
    case .noImageId: return "Failed to obtain imageId."
    case .noJsonData(let imageId): return "Failed to obtain JSON data from database for imageId: \(imageId)."
    case .getUsersFailed: return "Failed to read users from database."
    case .noUserId(let userId): return "Failed to obtain userId: \(userId)."
    case .missingUserId: return "Failed to obtain userId."
    case .readDocumentFailed: return "Failed to read requested user document."
    case .addImageRecordFailed: return "Failed to create image record in Cloudant database."
    case .getImagesFailed(let userId): return "Failed to get images for \(userId)."
    case .addUserRecordFailed(let userId): return "Failed to add user: \(userId) to the system of records."
    case .requestFailed: return "Failed to process user request."
    case .createDatabaseObjectFailed(let type): return "Failed to add object of type \(type) to database"
    }
  }
}
