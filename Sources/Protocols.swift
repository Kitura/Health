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

/// State enum
///
/// Enumeration that encapsulates the two possible states for an application, UP or DOWN.
public enum State: String {
case UP
case DOWN
}

/// Status struct
///
/// Struct that encapsulates the status of an application.
public struct Status {
  public let dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
  public let state: State
  public let details: [String]
  public let tsInMillis: UInt64
  private let dateFormatter: DateFormatter

  /// Constructor
  ///
  /// - Parameter state: Optional. The state value for this Status instance (default value is 'UP').
  /// - Parameter details: Optional. A list of strings that describes any issues that may have
  /// occurred while executing a health check.
  public init(state: State = State.UP, details: [String] = []) {
    self.state = state
    self.details = details
    self.tsInMillis = Date.currentTimeMillis()
    self.dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    if let timeZone = TimeZone(identifier: "UTC") {
      dateFormatter.timeZone = timeZone
    } else {
      Log.warning("UTC time zone not found...")
    }
  }

  /// Returns a dictionary that contains the current status information. This dictionary
  /// contains three key-pair values, where the keys are 'status', 'timestamp', and 'details'.
  public func toDictionary() -> [String : Any] {
    // Transform time in milliseconds to readable format
    let timestamp = dateFormatter.string(from: Date(timeInMillis: self.tsInMillis))
    // Add state & details to dictionary
    let dict = ["status" : self.state.rawValue, "details" : details, "timestamp" : timestamp]  as [String : Any]
    return dict
  }

  /// Returns a simple dictionary that contains the current status information. This dictionary
  /// contains one key-pair value, where the key is 'status' and the value is either 'UP' or 'DOWN'.
  public func toSimpleDictionary() -> [String : Any] {
    // Add state & details to dictionary
    let dict = ["status" : self.state.rawValue]  as [String : Any]
    return dict
  }
}

/// HealthCheckClosure typealias (closure)
///
/// HealthCheckClosure is a typealias for a closure that receives no arguments and
/// returns a State value.
public typealias HealthCheckClosure = () -> State

/// HealthCheck protocol
///
/// Healch check classes should extend this protocol to provide concrete implementations.
public protocol HealthCheck {
  var name: String { get }
  var description: String { get }
  func evaluate() -> State
}

/// HealthProtocol protocol
///
/// Specifies the blueprint that must be implemented to satisfy the needs of a Healch class.
/// A concrete implemetation of this protocol is already provided by this library (Health).
public protocol HealthProtocol {
  var status: Status { get }
  func addCheck(check: HealthCheck)
  func addCheck(check: @escaping HealthCheckClosure)
}
