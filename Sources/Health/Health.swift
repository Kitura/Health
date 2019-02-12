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

/// The `Health` class provides a concrete implementation of the `HealthProtocol` protocol that
/// applications can instantiate and then register one or more health checks against. Once you
/// have your health checks in place you can ask your `Health` instance for its status.
///
///### Usage Example: ###
/// One common use case for this Swift package is to integrate it into a Kitura-based application. In the code sample below, the health of the application is exposed through the /health endpoint. Cloud environments (e.g. Cloud Foundry, Kubernetes, etc.) can then use the status information returned from the /health endpoint to monitor and manage the Swift application instance.
///
/// For further information and example code see our [README](https://github.com/IBM-Swift/Health/blob/master/README.md) and the [Cloud Foundry documentation for using application health checks](https://docs.cloudfoundry.org/devguide/deploy-apps/healthchecks.html).
///```swift
/// import Health
///
/// let health = Health()
///
/// health.addCheck(check: MyCheck1())
/// health.addCheck(check: myClosureCheck1)
///
/// // Define /health endpoint that leverages Health
/// router.get("/health") { request, response, next in
///    let status = health.status
///    if health.status.state == .UP {
///        try response.status(.OK).send(status).end()
///    } else {
///        try response.status(.serviceUnavailable).send(status).end()
///    }
/// }
///```
public class Health: HealthProtocol {
  private var checks: [HealthCheck]
  private var closureChecks: [HealthCheckClosure]
  private var lastStatus: Status
  private let statusExpirationTime: Int // milliseconds
  private let statusSemaphore = DispatchSemaphore(value: 1)

  /// Status instance variable.
  public var status: Status {
    get {
      statusSemaphore.wait()
      let current = Date.currentTimeMillis()
      let last = self.lastStatus.tsInMillis

      // If elapsed time is bigger than the status expiration window, re-compute status
      // Check if current > last to avoid crashs because of negative UInt64 values
      // This is possible because of different rounding behaviour of DateFormatter.string() and
      // timeIntervalSince1970 > UInt64 convertion
      if current > last && (current - last) > UInt64(statusExpirationTime) {
        forceUpdateStatus()
      }
      statusSemaphore.signal()
      return lastStatus
    }
  }

  /// Number of health checks registered.
  ///
  ///### Usage Example: ###
  ///```swift
  /// let health = Health()
  ///
  /// let count = health.numberOfChecks
  ///```
  public var numberOfChecks: Int {
    get {
      return (checks.count + closureChecks.count)
    }
  }

  /// Creates an instance of the `Health` class.
  ///
  ///### Usage Example: ###
  /// In the example below the `statusExpirationTime` defaults to `30000` milliseconds, in this
  /// case 30 seconds must elapse before the `Health` instance computes its status again by
  /// querying each health check that has been registered.
  ///```swift
  ///let health = Health()
  ///```
  /// - Parameter statusExpirationTime: Optional. The time window in milliseconds that should
  /// elapse before the status cache for this `Health` instance is considered to be expired
  /// and should be recomputed. The default value is `30000`.
  public init(statusExpirationTime: Int = 30000) {
    self.statusExpirationTime = statusExpirationTime
    self.lastStatus = Status(state: .UP)
    checks = [HealthCheck]()
    closureChecks = [HealthCheckClosure]()
  }

  /// Registers a health check.
  ///
  ///### Usage Example: ###
  ///```swift
  /// let health = Health()
  ///
  /// // Add custom checks
  /// health.addCheck(check: MyCheck1())
  ///```
  /// - Parameter check: An object that extends the `HealthCheck` class.
  public func addCheck(check: HealthCheck) {
    checks.append(check)
  }

  /// Registers a health check.
  ///
  ///### Usage Example: ###
  ///```swift
  /// let health = Health()
  ///
  /// // Add custom checks
  /// health.addCheck(check: myClosureCheck1)
  ///```
  /// - Parameter check: A closure that conforms to the `HealthCheckClosure` type alias.
  public func addCheck(check: @escaping HealthCheckClosure) {
    closureChecks.append(check)
  }

  /// Forces an update to the status of this instance.
  public func forceUpdateStatus() {
    let checksDetails = checks.map { $0.evaluate() == State.DOWN ? $0.description : nil }
    let closureChecksDetails = closureChecks.map { $0() == State.DOWN ? "A health check closure reported status as DOWN." : nil }
    #if swift(>=4.1)
      let details = (checksDetails + closureChecksDetails).compactMap { $0 }
    #else
      let details = (checksDetails + closureChecksDetails).flatMap { $0 }
    #endif
    let state = (details.isEmpty) ? State.UP : State.DOWN
    lastStatus = Status(state: state, details: details)
  }
}
