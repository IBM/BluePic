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

import Dispatch
import Foundation

class Collection<T> {

  internal let semaphoreQueue = DispatchSemaphore(value: 1)
  internal var list: [T]
  let size: Int

  var isEmpty: Bool {
    semaphoreQueue.wait()
    let empty = list.isEmpty
    semaphoreQueue.signal()
    return empty
  }

  var count: Int {
    semaphoreQueue.wait()
    let count = list.count
    semaphoreQueue.signal()
    return count
  }

  init(size: Int) {
    self.size = size
    self.list = [T]()
  }

  func add(_ element: T) {
    semaphoreQueue.wait()
    list.append(element)
    if list.count > size {
        _ = list.removeFirst()
    }
    semaphoreQueue.signal()
  }

  func removeFirst() -> T? {
    semaphoreQueue.wait()
    let element: T? = list.removeFirst()
    semaphoreQueue.signal()
    return element
  }

  func removeLast() -> T? {
    semaphoreQueue.wait()
    let element: T? = list.removeLast()
    semaphoreQueue.signal()
    return element
  }

  func peekFirst() -> T? {
    semaphoreQueue.wait()
    let element: T? = list.first
    semaphoreQueue.signal()
    return element
  }

  func peekLast() -> T? {
    semaphoreQueue.wait()
    let element: T? = list.last
    semaphoreQueue.signal()
    return element
  }

  func clear() {
    semaphoreQueue.wait()
    list.removeAll()
    semaphoreQueue.signal()
  }
}

class FailureQueue: Collection<UInt64> {
  var currentTimeWindow: UInt64? {
    semaphoreQueue.wait()
    // Get time difference
    let timeWindow: UInt64?
    if let firstFailureTs = list.first, let lastFailureTs = list.last {
      timeWindow = lastFailureTs - firstFailureTs
    } else {
      timeWindow = nil
    }
    semaphoreQueue.signal()
    return timeWindow
  }
}

extension Date {
  public static func currentTimeMillis() -> UInt64 {
    let timeInMillis = UInt64(NSDate().timeIntervalSince1970 * 1000.0)
    return timeInMillis
  }
}

class Bulkhead {
  private let serialQueue: DispatchQueue
  private let concurrentQueue: DispatchQueue
  private let semaphore: DispatchSemaphore

  init(limit: Int) {
    serialQueue = DispatchQueue(label: "bulkheadSerialQueue")
    concurrentQueue = DispatchQueue(label: "bulkheadConcurrentQueue", attributes: .concurrent)
    semaphore = DispatchSemaphore(value: limit)
  }

  func enqueue(task: @escaping () -> Void ) {
    serialQueue.async { [weak self] in
      self?.semaphore.wait()
      self?.concurrentQueue.async {
        task()
        self?.semaphore.signal()
      }
    }
  }
}

// Invocation entity
public class Invocation<A, B, C> {

  public let commandArgs: A
  private(set) var timedOut: Bool = false
  private(set) var completed: Bool = false
  weak private var breaker: CircuitBreaker<A, B, C>?
  public init(breaker: CircuitBreaker<A, B, C>, commandArgs: A) {
    self.commandArgs = commandArgs
    self.breaker = breaker
  }

  public func setTimedOut() {
    self.timedOut = true
  }

  public func setCompleted() {
    self.completed = true
  }

  public func notifySuccess() {
    if !self.timedOut {
      self.setCompleted()
      breaker?.notifySuccess()
    }
  }

  public func notifyFailure() {
    if !self.timedOut {
      self.setCompleted()
      breaker?.notifyFailure()
    }
  }
}
