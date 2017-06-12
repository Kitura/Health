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

public class Health: HealthProtocol {
  private let statusExpirationWindow: Int // seconds
  private var checks: [HealthCheck]
  private var closureChecks: [HealthCheckClosure]
  private var lastStatus: Status
  //private var 

  public var status: Status {
    get {
      let checksDetails = checks.map { $0.evaluate() == State.DOWN ? $0.description : nil }
      let closureChecksDetails = closureChecks.map { $0() == State.DOWN ? "A health check closure reported status as DOWN." : nil }
      let details = (checksDetails + closureChecksDetails).flatMap { $0 }
      let state = (details.isEmpty) ? State.UP : State.DOWN
      let status = Status(state: state, details: details)
      return status
    }
  }

  public var numberOfChecks: Int {
    get {
      return (checks.count + closureChecks.count)
    }
  }

  public init(statusExpirationWindow: Int = 300) {
    self.statusExpirationWindow = statusExpirationWindow
    self.lastStatus = Status(state: .UP)
    checks = [HealthCheck]()
    closureChecks = [HealthCheckClosure]()
  }

  public func addCheck(check: HealthCheck) {
    checks.append(check)
  }

  public func addCheck(check: @escaping HealthCheckClosure) {
    closureChecks.append(check)
  }
}
