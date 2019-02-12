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

/// Extension to the `Date` type.
extension Date {

  /// Returns the current time in milliseconds.
  public static func currentTimeMillis() -> UInt64 {
    let timeInMillis = UInt64(NSDate().timeIntervalSince1970 * 1000.0)
    return timeInMillis
  }

  /// Returns the time value of the date in milliseconds (since 1970).
  var milliseconds: UInt64 { 
    get {
      return UInt64(self.timeIntervalSince1970 * 1000.0)
    }
  }

  /// Creates a `Date` instance from milliseconds.
  public init(timeInMillis: UInt64) {
    self = Date(timeIntervalSince1970: TimeInterval(timeInMillis / 1000))
  }
}
