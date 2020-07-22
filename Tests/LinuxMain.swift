import XCTest

import ExponentialBackoffTests

var tests = [XCTestCaseEntry]()
tests += ExponentialBackoffTests.allTests()
XCTMain(tests)
