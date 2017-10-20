/**
* Copyright IBM Corporation 2017
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
import LoggerAPI

public class Stats {
  internal(set) public var timeouts: Int = 0
  internal(set) public var successfulResponses: Int = 0
  internal(set) public var failedResponses: Int = 0
  internal(set) public var totalRequests: Int = 0
  internal(set) public var rejectedRequests: Int = 0
  internal(set) public var latencies: [Int] = []

  func trackTimeouts() {
    timeouts += 1
  }

  func trackSuccessfulResponse() {
    successfulResponses += 1
  }

  func trackFailedResponse() {
    failedResponses += 1
  }

  func trackRejected() {
    rejectedRequests += 1
  }

  func trackRequest() {
    totalRequests += 1
  }

  func trackLatency(latency: Int) {
    latencies.append(latency)
  }

  func reset() {
    self.timeouts = 0
    self.successfulResponses = 0
    self.failedResponses = 0
    self.totalRequests = 0
    self.rejectedRequests = 0
    self.latencies = []
  }

  public func totalLatency() -> Int {
    return latencies.reduce(0, +)
  }

  public func averageResponseTime() -> Int {
    if latencies.count == 0 {
      return 0
    }
    return totalLatency() / latencies.count
  }

  public func concurrentRequests() -> Int {
    let totalResponses = successfulResponses + failedResponses + rejectedRequests
    return totalRequests - totalResponses
  }

  // Log current snapshot of CircuitBreaker
  public func snapshot () {
    Log.verbose("Total Requests: \(totalRequests)")
    Log.verbose("Concurrent Requests: \(concurrentRequests())")
    Log.verbose("Rejected Requests: \(rejectedRequests)")
    Log.verbose("Successful Responses: \(successfulResponses)")
    Log.verbose("Average Response Time: \(averageResponseTime())")
    Log.verbose("Failed Responses: \(failedResponses)")
    Log.verbose("Total Timeouts: \(timeouts)")
    Log.verbose("Total Latency: \(totalLatency())")
  }

}
