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

/// InvalidDataError enum
///
/// Enumeration that represents data errors.
public enum InvalidDataError: Error {

/// A deserialization error occurred.
case deserialization(String)

/// A serialization error occurred.
case serialization(String)
}

/// State enum
///
/// Enumeration that encapsulates the two possible states for an application, UP or DOWN.
public enum State: String {

/// Application is running just fine.
case UP
/// Application health is not good.
case DOWN
}

/// Struct that encapsulates a DateFormatter implementation, specifically used by the Status struct.
public class StatusDateFormatter {
  private let dateFormatter: DateFormatter

  /// Constructor
  ///
  /// Wraps a DateFormatter instance, sets its timezone to UTC and its date format to 'yyyy-MM-dd'T'HH:mm:ssZ'.
  init() {
    self.dateFormatter = DateFormatter()
    self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    if let timeZone = TimeZone(identifier: "UTC") {
      self.dateFormatter.timeZone = timeZone
    } else {
      // This should never occur...
      Log.warning("UTC time zone not found.")
    }
  }

  /// Returns a timestamp string representation from the Date parameter.
  /// - Parameter from: A Date instance to obtain the date value from.
  public func string(from date: Date) -> String {
    return dateFormatter.string(from: date)
  }

  /// Returns a Date instance that corresponds to the string parameter.
  /// - Parameter from: A string in the "yyyy-MM-dd'T'HH:mm:ssZ" format.
  public func date(from string: String) -> Date? {
    return dateFormatter.date(from: string)
  }

  var dateFormat: String {
    get {
      return self.dateFormatter.dateFormat
    }
  }
}

/// Struct that encapsulates the status of an application.
public struct Status: Equatable {
  public static let dateFormatter = StatusDateFormatter()

  /// The date format used by the timestamp value in the dictionary.
  public static var dateFormat: String {
    get {
      return dateFormatter.dateFormat
    }
  }

  /// The state value contained within this struct.
  public let state: State
  /// List of details describing any failures.
  public let details: [String]
  /// The timestamp value in milliseconds for the status.
  public var tsInMillis: UInt64 {
    get {
      let date = Status.dateFormatter.date(from: timestamp)
      return date!.milliseconds
    }
  }
  /// The string timestamp value for the status.
  public let timestamp: String

  enum CodingKeys: String, CodingKey {
        case status
        case details
        case timestamp
  }

  public static func ==(lhs: Status, rhs: Status) -> Bool {
        return (lhs.state == rhs.state) && (lhs.details == rhs.details) && (lhs.timestamp == rhs.timestamp)
   }

  /// Constructor
  ///
  /// - Parameter state: Optional. The state value for this Status instance (default value is 'UP').
  /// - Parameter details: Optional. A list of strings that describes any issues that may have
  /// occurred while executing a health check.
  /// - Parameter timestamp: Optional. The string timestamp value for the status (default value is current time).
  public init(state: State = State.UP, details: [String] = [], timestamp: String = dateFormatter.string(from: Date())) {
    self.state = state
    self.details = details
    if let _ = Status.dateFormatter.date(from: timestamp) {
      self.timestamp = timestamp  
    } else {
      self.timestamp = Status.dateFormatter.string(from: Date())
      Log.warning("Provided timestamp value '\(timestamp)' is not valid; using current time value instead.")
    }
 }

  /// Returns a dictionary that contains the current status information. This dictionary
  /// contains three key-pair values, where the keys are 'status', 'timestamp', and 'details'.
  public func toDictionary() -> [String : Any] {
    // Transform time in milliseconds to readable format
    //let timestamp = Status.dateFormatter.string(from: Date(timeInMillis: self.tsInMillis))
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

/// Extension for the Status struct that conforms to the Encodable protocol.
extension Status: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.state.rawValue, forKey: .status)
    try container.encode(self.details, forKey: .details)
    try container.encode(self.timestamp, forKey: .timestamp)
  }
}

/// Extension for the Status struct that conforms to the Decodable protocol.
extension Status: Decodable {
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let status = try values.decode(String.self, forKey: .status)
    
    guard let state = State(rawValue: status) else {
      throw InvalidDataError.deserialization("'\(status)' is not a valid status value.")
    }
    
    let details = try values.decode([String].self, forKey: .details)
    let timestamp = try values.decode(String.self, forKey: .timestamp)
    
    guard let _ = Status.dateFormatter.date(from: timestamp) else {
       throw InvalidDataError.deserialization("'\(timestamp)' is not a valid timestamp value.")
    }

    self.init(state: state, details: details, timestamp: timestamp)
  }
}

/// HealthCheckClosure is a typealias for a closure that receives no arguments and
/// returns a State value.
public typealias HealthCheckClosure = () -> State

/// HealthCheck protocol
///
/// Healch check classes should extend this protocol to provide concrete implementations.
public protocol HealthCheck {
  /// Name for the health check.
  var name: String { get }
  /// Description for the health check.
  var description: String { get }
  /// Performs the health check test.
  func evaluate() -> State
}

/// HealthProtocol protocol
///
/// Specifies the blueprint that must be implemented to satisfy the needs of a Healch class.
/// A concrete implemetation of this protocol is already provided by this library (Health).
public protocol HealthProtocol {
  /// Status instance variable.
  var status: Status { get }
  /// Registers a healh check.
  ///
  /// - Parameter check: An object that extends the HealthCheck class.
  func addCheck(check: HealthCheck)
  /// Registers a healh check.
  ///
  /// - Parameter check: A closure that conforms to the HealthCheckClosure type alias.
  func addCheck(check: @escaping HealthCheckClosure)
}
