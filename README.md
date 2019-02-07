<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>

<p align="center">
    <a href="https://ibm-swift.github.io/Health/index.html">
    <img src="https://img.shields.io/badge/apidoc-Health-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Health">
    <img src="https://travis-ci.org/IBM-Swift/Health.svg?branch=master" alt="Build Status - Master">
    </a>
    <a href="https://codecov.io/gh/IBM-Swift/Health">
    <img src="https://codecov.io/gh/IBM-Swift/Health/branch/master/graph/badge.svg" alt="codecov">
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# Health
The Health package provides a basic infrastructure that Swift applications can use for reporting their overall health status.

As an application developer, you create an instance of the `Health` class and then register one or more health checks. A health check can be either a closure that conforms to the `HealthCheckClosure` typealias or a class that conforms to the `HealthCheck` protocol. Once you have your health checks in place, you can ask your `Health` instance for its status.

## Swift version
The latest version of Health works with the `4.1.2` version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/#snapshots).

## Usage

### Add dependencies

Add `Health` to the dependencies within your application's `Package.swift` file. Substitute `"x.x.x"` with the latest `Health` [release](https://github.com/IBM-Swift/Health/releases).

```swift
.package(url: "https://github.com/IBM-Swift/Health.git", from: "x.x.x")
```
Add `Health` to your target's dependencies:

```Swift
.target(name: "example", dependencies: ["Health"]),
```

### Initialize Health

The example code below shows how to create a `Health` instance and register your health checks:

```swift
import Health

let health = Health()

// Add custom checks
health.addCheck(check: MyCheck1())
health.addCheck(check: MyCheck2())
health.addCheck(check: myClosureCheck1)
health.addCheck(check: myClosureCheck1)

// Get current health status
let count = health.numberOfChecks
let status: Status = health.status
let state: State = status.state
let dictionary = status.toDictionary()
let simpleDictionary = status.toSimpleDictionary()
```

The simple dictionary contains a key-value pair that lets you know whether the application is UP or DOWN:

```
["status": "UP"]
```

The dictionary contains a key-value pair that lets you know whether the application is UP or DOWN, additional details about the health checks that failed (if any), and a Universal Time Coordinated (UTC) timestamp value:

```
["status": "DOWN", "timestamp": "2017-06-12T18:04:38+0000", "details": ["Cloudant health check.", "A health check closure reported status as DOWN."]]
```

Swift applications can use either dictionary, depending on the use case, to report the overall status of the application. For instance, an endpoint on the application could be defined that queries the `Health` object to get the overall status and then send it back to a client as a JSON payload.

The `Status` structure now conforms to the `Codable` protocol, which enables you to serialize an instance of this structure and send it as a response to a client. If you use this mechanism you don't need to invoke either the `toDictionary()` or the `toSimpleDictionary()` methods in order to obtain the status payload for a client:

```
let status: Status = health.status
let payload = try JSONEncoder().encode(status)
// Send payload to client
```

## Caching
When you create an instance of the `Health` class, you can pass an optional argument (named `statusExpirationTime`) to its initializer as shown next:

```swift
let health = Health(statusExpirationTime: 30000)
```

The `statusExpirationTime` parameter specifies the number of milliseconds that a given instance of `Health` should cache its status for before recomputing it. For instance, if the value assigned to `statusExpirationTime` is `30000` (as shown above), then 30 seconds must elapse before the `Health` instance computes its status again by querying each health check that has been registered. The default value for the `statusExpirationTime` parameter is `30000`.

## Implementing a health check
You can implement health checks by either extending the `HealthCheck` protocol or creating a closure that returns a `State` value.

The following snippet of code shows the implementation of a class named `MyCustomCheck`, which implements the `HealthCheck` protocol:

```swift
class MyCustomCheck: HealthCheck {
  public var name: String { get { return "MyCustomCheck for XYZ"} }

  public var description: String { get { return "Description for MyCustomCheck..."} }

  public func evaluate() -> State {
    let state: State = isConnected() ? State.UP : State.DOWN
    return state
  }

  private func isConnected() -> Bool {
    ...
  }
}
```

The following snippet of code shows the implementation for a similar health check but using a closure instead:

```swift
func myCustomCheck() -> State {
  let state: State = isConnected() ? State.UP : State.DOWN
  return state
}

func isConnected() -> Bool {
  ...
}
```

## Using Health in a Kitura application
One common use case for this Swift package is to integrate it into a Kitura-based application, as shown below:

```swift
import Kitura
import Foundation

...

// Create main objects...
router = Router()

health = Health()

// Register health checks...
health.addCheck(check: Microservice1Check())
health.addCheck(check: microservice2Check)

...

// Define /health endpoint that leverages Health
router.get("/health") { request, response, next in
  // let status = health.status.toDictionary()
  let status = health.status.toSimpleDictionary()
  if health.status.state == .UP {
    try response.send(json: status).end()
  } else {
    try response.status(.serviceUnavailable).send(json: status).end()
  }
}

```

In the code sample above, the health of the application is exposed through the `/health` endpoint. Cloud environments (e.g. Cloud Foundry, Kubernetes, etc.) can then use the status information returned from the `/health` endpoint to monitor and manage the Swift application instance.

As an alternative to the implementation shown above for the `/health` endpoint, you can take advantage of the `Codable` protocol available in Swift 4. Since the `Status` struct satisfies the `Codable` protocol, a simpler implementation for the `/health` endpoint can be implemented using the new codable capabilities in Kitura 2.0 as shown below:

```swift
...

// Define /health endpoint that leverages Health
router.get("/health") { request, response, next in
  let status = health.status
  if health.status.state == .UP {
    try response.status(.OK).send(status).end()
  } else {
    try response.status(.serviceUnavailable).send(status).end()
  }
}

...

```

In addition to sending the dictionary response, a server needs to respond with a non-200 status code, if the health state is considered down. This can be accomplished with a status code such as 503 `.serviceUnavailable`. That way, the cloud environment can recognize the negative health response, destroy that instance of the application, and restart the application.

## Using Cloud Foundry Environment
If using a Cloud Foundry environment, make sure to update your `manifest.yml` to support health check. In the example above, you would set the `health-check-type` value to `http` and the `health-check-http-endpoint` to the correct health endpoint path, which is `/health` in this case. Review the [health check documentation](https://docs.cloudfoundry.org/devguide/deploy-apps/healthchecks.html) for more details.

## API documentation

For more information visit our [API reference](http://ibm-swift.github.io/Health/).

## Community

We love to talk server-side Swift and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/Health/blob/master/LICENSE.txt).
