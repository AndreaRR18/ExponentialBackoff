import XCTest
@testable import ExponentialBackoff

final class ExponentialBackoffTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ExponentialBackoff().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
