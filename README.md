![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)

# Health
The Health package provides a basic infrastructure that Swift applications can use for reporting their overall health status.

As an application developer, you would create an instance of the `Health` class and then register one or more health checks. A health check can be either a closure that conforms to the `HealthCheckClosure` typealias or a class that conforms to the `HealthCheck` protocol. Once you have your health checks in place, you can ask your `Health` instance for its status.

## Swift version
The latest version of Health works with the `3.1.1` version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/#snapshots).

## Usage:
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

...

let health = Health()

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

The contents of the dictionary contains a key-value pair that lets you know whether the application is UP or DOWN plus additional details about the health checks that failed (if available):

```
["details": ["Cloudant health check.", "A health check closure reported status as DOWN."], "status": "DOWN"]
```

Swift applications can then use either dictionary, depending on the use case, to report the overall status of the application. For instance, an endpoint on the application could be defined that queries the `Health` object to get the overall status and then send it back to a client as a JSON payload.
