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

import XCTest
import Foundation

@testable import Health

class HealthTests: XCTestCase {

  static var allTests: [(String, (HealthTests) -> () throws -> Void)] {
    return [
      ("testBasicConstruction", testBasicConstruction),
      ("testAddChecks", testAddChecks),
      ("testStatusSerialization", testStatusSerialization),
      ("testDateExtensions", testDateExtensions),
      ("testDateFormatter", testDateFormatter)
    ]
  }

  class MyPositiveCheck: HealthCheck {
    public var name: String { get { return "MyPositiveCheck"} }
    public var description: String { get { return "Description for MyPositiveCheck..."} }
    public func evaluate() -> State {
      return State.UP
    }
  }

  class MyNegativeCheck: HealthCheck {
    public var name: String { get { return "MyNegativeCheck"} }
    public var description: String { get { return "Description for MyNegativeCheck..."} }
    public func evaluate() -> State {
      return State.DOWN
    }
  }

  func myPositiveClosureCheck() -> State {
    return State.UP
  }

  func myNegativeClosureCheck() -> State {
    return State.DOWN
  }

  override func setUp() {
    super.setUp()
  }

  // Create Stats, and check that default values are set
  func testBasicConstruction() {

    // Create Health instance
    let health = Health()

    // Assert initial state
    XCTAssertEqual(health.numberOfChecks, 0)
    XCTAssertEqual(health.status.state, State.UP)
    XCTAssertEqual(health.status.details.count, 0)

    // Assert contents of simple dictionary
    let simpleDictionary = health.status.toSimpleDictionary()
    print("simpleDictionary: \(simpleDictionary)")
    XCTAssertEqual(simpleDictionary.count, 1)
    let simpleKeys = simpleDictionary.keys
    XCTAssertTrue(simpleKeys.contains("status"))
    if let status = simpleDictionary["status"] as? String {
      XCTAssertEqual(status, "UP")
    } else {
      XCTFail("Non-expected status in dictionary.")
    }

    // Assert contents of dictionary
    let dictionary = health.status.toDictionary()
    print("dictionary: \(dictionary)")
    // There should only be two keys
    XCTAssertEqual(dictionary.count, 3)
    let keys = dictionary.keys
    XCTAssertTrue(keys.contains("status"))
    XCTAssertTrue(keys.contains("details"))
    XCTAssertTrue(keys.contains("timestamp"))

    // Validate status
    if let status = dictionary["status"] as? String {
      XCTAssertEqual(status, "UP")
    } else {
      XCTFail("'status' field missing in dictionary.")
    }

    // Validate details
    if let details = dictionary["details"] as? [String] {
      XCTAssertEqual(details.count, 0)
    } else {
      XCTFail("'details' field missing in dictionary.")
    }

    // Validate timestamp
    if let timestamp = dictionary["timestamp"] as? String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
      let date = dateFormatter.date(from: timestamp)
      XCTAssertNotNil(date, "'timestamp' field in dictionary does not match expected format.")
    } else {
      XCTFail("'timestamp' field missing in dictionary.")
    }
  }

  func testAddChecks() {
    // Create Health instance
    let statusExpirationTime = 3000
    let health = Health(statusExpirationTime: statusExpirationTime)

    // Add checks
    health.addCheck(check: MyPositiveCheck())
    health.addCheck(check: MyNegativeCheck())
    health.addCheck(check: myPositiveClosureCheck)
    health.addCheck(check: myNegativeClosureCheck)

    // Perform assertions
    XCTAssertEqual(health.numberOfChecks, 4)
    // State should still be up (caching - 30 seconds)
    XCTAssertEqual(health.status.state, State.UP)
    // Wait for cache to expire
    sleep(UInt32((statusExpirationTime + 1000)/1000))
    // State should be down now...
    XCTAssertEqual(health.status.state, State.DOWN)

    // Assert contents of dictionary
    let dictionary = health.status.toDictionary()
    print("dictionary: \(dictionary)")
    if let status = dictionary["status"] as? String {
      XCTAssertEqual(status, "DOWN")
    } else {
      XCTFail("Non-expected status in dictionary.")
    }

    if let details = dictionary["details"] as? [String] {
      //print("details: \(details)")
      XCTAssertEqual(details.count, 2)
      XCTAssertTrue(details.contains("Description for MyNegativeCheck..."))
      XCTAssertTrue(details.contains("A health check closure reported status as DOWN."))
    } else {
      XCTFail("Non-expected details in dictionary.")
    }
  }

  func testDateFormatter() {
    // Validate conversion from string timestamp to date and back to string timestamp
    let dateStr1 = "2017-10-31T16:15:56+0000"
    let dateFormatter = StatusDateFormatter()
    guard let date1 = dateFormatter.date(from: dateStr1) else {
       XCTFail("Failed to compute date from valid string timestamp!")
       return
    }
    let computedDateStr1 = dateFormatter.string(from: date1)
    XCTAssertEqual(dateStr1, computedDateStr1, "Timestamp string values did not match!")

    // Validate conversion to string timestamp from milliseconds
    let milliseconds: UInt64 = 1509466556000
    let date2 = Date(timeInMillis: milliseconds)
    let dateStr2 = dateFormatter.string(from: date2)
    XCTAssertEqual(dateStr2, "2017-10-31T16:15:56+0000", "Timestamp string values did not match!")
  }

  func testDateExtensions() {
    // Compare millis
    let milliseconds: UInt64 = 1509466556000
    let date1 = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    let date2 = Date(timeInMillis: milliseconds)
    XCTAssertEqual(date1.timeIntervalSince1970, date2.timeIntervalSince1970, "timeIntervalSince1970 values did not match!")
    XCTAssertEqual(date1.milliseconds, milliseconds, "milliseconds values did not match!")
    XCTAssertEqual(date2.milliseconds, milliseconds, "milliseconds values did not match!")
  }

  func testStatusSerialization() {
    // Validate serialization and deserialization of status instance
    let status: Status = Status(state: .DOWN, details: ["details1", "details2", "details3"], timestamp: "2017-10-31T16:15:56+0000")
    
    guard let data = try? JSONEncoder().encode(status) else {
    XCTFail("Failed to encode Status instance!")
      return
    }

    guard let decodedStatus = try? JSONDecoder().decode(Status.self, from: data) else {
       XCTFail("Failed to decode JSON data into a Status instance!")
       return
    }

    XCTAssertEqual(status, decodedStatus, "Failed to encode and decode Status instance!")
  }

}
