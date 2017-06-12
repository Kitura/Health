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

/// A concrete implementation of the HealthProtocol protocol.
public class Health: HealthProtocol {
  private var checks: [HealthCheck]
  private var closureChecks: [HealthCheckClosure]
  private var lastStatus: Status
  private let statusExpirationTime: Int // milliseconds
  private let statusSemaphore = DispatchSemaphore(value: 1)

  public var status: Status {
    get {
      statusSemaphore.wait()
      // If elapsed time is bigger than the status expiration window, re-compute status
      if (Date.currentTimeMillis() - self.lastStatus.tsInMillis) > UInt64(statusExpirationTime) {
        forceUpdateStatus()
      }
      statusSemaphore.signal()
      return lastStatus
    }
  }

  public var numberOfChecks: Int {
    get {
      return (checks.count + closureChecks.count)
    }
  }

  public init(statusExpirationTime: Int = 30000) {
    self.statusExpirationTime = statusExpirationTime
    self.lastStatus = Status(state: .UP)
    checks = [HealthCheck]()
    closureChecks = [HealthCheckClosure]()
  }

  public func addCheck(check: HealthCheck) {
    checks.append(check)
  }

  /// addCheck: Adds the specified closure as a health check.
  /// - Parameter check: The health check closure
  public func addCheck(check: @escaping HealthCheckClosure) {
    closureChecks.append(check)
  }

  public func forceUpdateStatus() {
    let checksDetails = checks.map { $0.evaluate() == State.DOWN ? $0.description : nil }
    let closureChecksDetails = closureChecks.map { $0() == State.DOWN ? "A health check closure reported status as DOWN." : nil }
    let details = (checksDetails + closureChecksDetails).flatMap { $0 }
    let state = (details.isEmpty) ? State.UP : State.DOWN
    lastStatus = Status(state: state, details: details)
  }
}
