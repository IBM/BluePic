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
import Dispatch
import LoggerAPI

public enum State {
  case open
  case halfopen
  case closed
}

public enum BreakerError {
  case timeout
  case fastFail
}

/// CircuitBreaker class
///
/// A - Parameter types used in the arguments for the command closure.
/// B - Return type from the execution of the command closure.
/// C - Parameter type used as the second argument for the fallback closure.
public class CircuitBreaker<A, B, C> {
  // Closure aliases
  public typealias AnyFunction<A, B> = (A) -> (B)
  public typealias AnyContextFunction<A, B> = (Invocation<A, B, C>) -> B
  public typealias AnyFallback<C> = (BreakerError, C) -> Void

  private(set) var state: State = State.closed
  private let failures: FailureQueue
  private let command: AnyFunction<A, B>?
  private let fallback: AnyFallback<C>
  private let contextCommand: AnyContextFunction<A, B>?
  private let bulkhead: Bulkhead?

  public let timeout: Int
  public let resetTimeout: Int
  public let maxFailures: Int
  public let rollingWindow: Int
  public let breakerStats: Stats = Stats()

  private var resetTimer: DispatchSourceTimer?
  private let semaphoreCompleted = DispatchSemaphore(value: 1)
  private let semaphoreCircuit = DispatchSemaphore(value: 1)

  private let queue = DispatchQueue(label: "Circuit Breaker Queue", attributes: .concurrent)

  private init(timeout: Int, resetTimeout: Int, maxFailures: Int, rollingWindow: Int, bulkhead: Int, command: (AnyFunction<A, B>)?, contextCommand: (AnyContextFunction<A, B>)?, fallback: @escaping AnyFallback<C>) {
    self.timeout = timeout
    self.resetTimeout = resetTimeout
    self.maxFailures = maxFailures
    self.rollingWindow = rollingWindow
    self.fallback = fallback
    self.command = command
    self.contextCommand = contextCommand
    self.failures = FailureQueue(size: maxFailures)
    self.bulkhead = (bulkhead > 0) ? Bulkhead.init(limit: bulkhead) : nil
  }

  public convenience init(timeout: Int = 1000, resetTimeout: Int = 60000, maxFailures: Int = 5, rollingWindow: Int = 10000, bulkhead: Int = 0, command: @escaping AnyFunction<A, B>, fallback: @escaping AnyFallback<C>) {
    self.init(timeout: timeout, resetTimeout: resetTimeout, maxFailures: maxFailures, rollingWindow: rollingWindow, bulkhead: bulkhead, command: command, contextCommand: nil, fallback: fallback)
  }

  public convenience init(timeout: Int = 1000, resetTimeout: Int = 60000, maxFailures: Int = 5, rollingWindow: Int = 10000, bulkhead: Int = 0, contextCommand: @escaping AnyContextFunction<A, B>, fallback: @escaping AnyFallback<C>) {
    self.init(timeout: timeout, resetTimeout: resetTimeout, maxFailures: maxFailures, rollingWindow: rollingWindow, bulkhead: bulkhead, command: nil, contextCommand: contextCommand, fallback: fallback)
  }

  // Run
  public func run(commandArgs: A, fallbackArgs: C) {
    breakerStats.trackRequest()

    if breakerState == State.open {
      fastFail(fallbackArgs: fallbackArgs)

    } else if breakerState == State.halfopen {
      let startTime: Date = Date()

      if let bulkhead = self.bulkhead {
        bulkhead.enqueue(task: {
          self.callFunction(commandArgs: commandArgs, fallbackArgs: fallbackArgs)
        })
      } else {
        callFunction(commandArgs: commandArgs, fallbackArgs: fallbackArgs)
      }

      self.breakerStats.trackLatency(latency: Int(Date().timeIntervalSince(startTime)))

    } else {
      let startTime: Date = Date()

      if let bulkhead = self.bulkhead {
        bulkhead.enqueue(task: {
          self.callFunction(commandArgs: commandArgs, fallbackArgs: fallbackArgs)
        })
      } else {
        callFunction(commandArgs: commandArgs, fallbackArgs: fallbackArgs)
      }

      self.breakerStats.trackLatency(latency: Int(Date().timeIntervalSince(startTime)))
    }
  }

  private func callFunction(commandArgs: A, fallbackArgs: C) {

    var completed = false

    func complete(error: Bool) -> () {
      weak var _self = self
      semaphoreCompleted.wait()
      if completed {
        semaphoreCompleted.signal()
      } else {
        completed = true
        semaphoreCompleted.signal()
        if error {
          _self?.handleFailure()
          //Note: fallback function is only invoked when failing fast OR when timing out
          let _ = fallback(.timeout, fallbackArgs)
        } else {
          _self?.handleSuccess()
        }
        return
      }
    }

    if let command = self.command {
      setTimeout() {
        complete(error: true)
      }

      let _ = command(commandArgs)
      complete(error: false)
    } else if let contextCommand = self.contextCommand {
      let invocation = Invocation(breaker: self, commandArgs: commandArgs)

      setTimeout() { [weak invocation] in
        if invocation?.completed == false {
          invocation?.setTimedOut()
          complete(error: true)
        }
      }

      let _ = contextCommand(invocation)
    }
  }

  private func setTimeout(closure: @escaping () -> ()) {
    queue.asyncAfter(deadline: .now() + .milliseconds(self.timeout)) { [weak self] in
      self?.breakerStats.trackTimeouts()
      closure()
    }
  }

  // Print Current Stats Snapshot
  public func snapshot() {
    breakerStats.snapshot()
  }

  public func notifyFailure() {
    handleFailure()
  }

  public func notifySuccess() {
    handleSuccess()
  }

  // Get/Set functions
  public private(set) var breakerState: State {
    get {
      return state
    }

    set {
      state = newValue
    }
  }

  var numberOfFailures: Int {
    get {
      return failures.count
    }
  }

  private func handleFailure() {
    semaphoreCircuit.wait()
    Log.verbose("Handling failure...")
    // Add a new failure
    failures.add(Date.currentTimeMillis())

    // Get time difference between oldest and newest failure
    let timeWindow: UInt64? = failures.currentTimeWindow

    defer {
      breakerStats.trackFailedResponse()
      semaphoreCircuit.signal()
    }

    if (state == State.halfopen) {
      Log.verbose("Failed in halfopen state.")
      open()
      return
    }

    if let timeWindow = timeWindow {
      if failures.count >= maxFailures && timeWindow <= UInt64(rollingWindow) {
        Log.verbose("Reached maximum number of failures allowed before tripping circuit.")
        open()
        return
      }
    }
  }

  private func handleSuccess() {
    semaphoreCircuit.wait()
    Log.verbose("Handling success...")
    if state == State.halfopen {
      close()
    }
    breakerStats.trackSuccessfulResponse()
    semaphoreCircuit.signal()
  }

  /**
  * This function should be called within the boundaries of a semaphore.
  * Otherwise, resulting behavior may be unexpected.
  */
  private func close() {
    // Remove all failures (i.e. reset failure counter to 0)
    failures.clear()
    breakerState = State.closed
  }

  /**
  * This function should be called within the boundaries of a semaphore.
  * Otherwise, resulting behavior may be unexpected.
  */
  private func open() {
    breakerState = State.open
    startResetTimer(delay: .milliseconds(resetTimeout))
  }

  private func fastFail(fallbackArgs: C) {
    Log.verbose("Breaker open... failing fast.")
    breakerStats.trackRejected()
    let _ = fallback(.fastFail, fallbackArgs)
  }

  public func forceOpen() {
    semaphoreCircuit.wait()
    open()
    semaphoreCircuit.signal()
  }

  public func forceClosed() {
    semaphoreCircuit.wait()
    close()
    semaphoreCircuit.signal()
  }

  public func forceHalfOpen() {
    breakerState = State.halfopen
  }

  private func startResetTimer(delay: DispatchTimeInterval) {
    // Cancel previous timer if any
    resetTimer?.cancel()

    resetTimer = DispatchSource.makeTimerSource(queue: queue)

    resetTimer?.setEventHandler { [weak self] in
      self?.forceHalfOpen()
    }
    #if swift(>=3.2)
        resetTimer?.schedule(deadline: .now() + delay)
    #else
        resetTimer?.scheduleOneshot(deadline: .now() + delay)
    #endif

    resetTimer?.resume()
  }
}
