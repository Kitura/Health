[![Build Status - Master](https://travis-ci.org/IBM-Swift/Health.svg?branch=master)](https://travis-ci.org/IBM-Swift/Health)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![codecov](https://codecov.io/gh/IBM-Swift/Health/branch/master/graph/badge.svg)](https://codecov.io/gh/IBM-Swift/Health)

# Health
The Health package provides a basic infrastructure that Swift applications can use for reporting their overall health status.

As an application developer, you create an instance of the `Health` class and then register one or more health checks. A health check can be either a closure that conforms to the `HealthCheckClosure` typealias or a class that conforms to the `HealthCheck` protocol. Once you have your health checks in place, you can ask your `Health` instance for its status.

## Swift version
The latest version of Health works with the `3.1.1` version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/#snapshots).

## Usage
To leverage the Health package in your Swift application, you should specify a dependency for it in your `Package.swift` file:

```swift
import PackageDescription

 let package = Package(
     name: "MyAwesomeSwiftProject",

     ...

     dependencies: [
         .Package(url: "https://github.com/IBM-Swift/Health.git", majorVersion: 0),

         ...

     ])
```

And this is how you create a `Health` instance and register your health checks:

```swift

import Health

...

  let health = Health()

...

  // Add custom checks
  health.addCheck(check: MyCheck1())
  health.addCheck(check: MyCheck2())
  health.addCheck(check: myClosureCheck1)
  health.addCheck(check: myClosureCheck1)

...

  // Get current health status
  let count = health.numberOfChecks
  let status: Status = health.status
  let state: State = status.state
  let dictionary = status.toDictionary()
  let simpleDictionary = status.toSimpleDictionary()

...

```

The contents of the simple dictionary simply contains a key-value pair that lets you know whether the application is UP or DOWN:

```
["status": "UP"]
```

The contents of the dictionary contains a key-value pair that lets you know whether the application is UP or DOWN, additional details about the health checks that failed (if any), and a Universal Time Coordinated (UTC) timestamp value:

```
["status": "DOWN", "timestamp": "2017-06-12T18:04:38+0000", "details": ["Cloudant health check.", "A health check closure reported status as DOWN."]]
```

Swift applications can then use either dictionary, depending on the use case, to report the overall status of the application. For instance, an endpoint on the application could be defined that queries the `Health` object to get the overall status and then send it back to a client as a JSON payload.

## Caching
When you create an instance of the `Health` class, you can pass an optional argument (named `statusExpirationTime`) to its initializer as shown next:

```swift
let health = Health(statusExpirationTime: 30000)
```

The `statusExpirationTime` parameter specifies the number of milliseconds that a given instance of `Health` should cache its status before recomputing it. For instance, if the value assigned to `statusExpirationTime` is `30000` (as shown above), then 30 seconds must elapse before the `Health` instance computes its status again by querying each health check that has been registered. Please note that the default value for the `statusExpirationTime` parameter is `30000`.

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
One common use case for this Swift package is to integrate it into a Kitura-based application, as shown next:

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

In addition to sending the dictionary response, a server needs to respond with a non-200 status code, if the health state is considered down. This can be accomplished with a status code such as 503 `.serviceUnavailable`. That way, the cloud environment can recognize the negative health response, destroy that instance of the application, and restart the application.

## Using Cloud Foundry Environment

If using a Cloud Foundry environment, make sure to update your `manifest.yml` to support health check. In the example above, you would set the `health-check-type` value to `http` and the `health-check-http-endpoint` to the correct health endpoint path, which is `/health` in this case. Review the [health check documentation](https://docs.cloudfoundry.org/devguide/deploy-apps/healthchecks.html) for more details.
