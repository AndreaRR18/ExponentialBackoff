import XCTest
@testable import ExponentialBackoff

class ExponentialBackoffDispatchQueue: XCTestCase {
    
    
    func testExecute_OperationEndWithSuccess_EndWithSuccess() {
        
        /// EXPECTED----------------------------------------------------
        let expected = ResultBackoffCall.success(42)
        /// ------------------------------------------------------------
        
        /// GIVEN
        var sut: ResultBackoffCall<Int>? = nil
        
        let expectation = self.expectation(description: #function)
        /// ------------------------------------------------------------
        
        /// WHEN
        DispatchQueue.ExponentialBackoff<ExponentialBackoffCompatible>
            .execute(
                maxRetryCount: 10,
                maxRetryDelay: 30,
                scheduler: .default,
                handler: { ExponentialBackoffCompatible.success(42) },
                onSuccess: { value in
                    sut = .success(value)
                    expectation.fulfill()
            },
                onError: { error in
                    XCTFail(error)
            },
                onMaxAttemptReached: {
                    XCTFail("MaxAttemptReached")
            })
        /// ------------------------------------------------------------
        
        /// THEN
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(sut, expected)
        /// ------------------------------------------------------------
    }
    
    func testExecute_OperationEndWithSuccessAfter5Seconds_SutIsStillNil() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// GIVEN
        var sut: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// WHEN
        DispatchQueue.ExponentialBackoff<ExponentialBackoffCompatible>
            .execute(
                maxRetryCount: 10,
                maxRetryDelay: 30,
                scheduler: .default,
                handler: { ExponentialBackoffCompatible.success(42) },
                onSuccess: { value in
                    sleep(5)
                    sut = .success(value)
            },
                onError: { error in
                    XCTFail(error)
            },
                onMaxAttemptReached: {
                    XCTFail("MaxAttemptReached")
            })
        /// ------------------------------------------------------------
        
        /// THEN
        XCTAssertEqual(sut, expected)
        /// ------------------------------------------------------------
    }
    
    func testExecute_OperationEndWithMaxAttemptReached_EndWithFailure() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = .maxAttemptReached
        /// ------------------------------------------------------------
        
        /// GIVEN
        var sut: ResultBackoffCall<Int>? = nil
        let expectation = self.expectation(description: #function)
        /// ------------------------------------------------------------
        
        /// WHEN
        DispatchQueue.ExponentialBackoff<ExponentialBackoffCompatible>
            .execute(
                maxRetryCount: 2,
                maxRetryDelay: 30,
                scheduler: .default,
                handler: { ExponentialBackoffCompatible.error },
                onSuccess: { value in
                    XCTFail("\(value)")
            },
                onError: { error in
                    XCTFail(error.description)
            },
                onMaxAttemptReached: {
                    sut = .maxAttemptReached
                    expectation.fulfill()
            })
        /// ------------------------------------------------------------
        
        /// THEN
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(sut, expected)
        /// ------------------------------------------------------------
    }
    
    func testExecute_OperationEndWithError_EndWithFailure() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = .error
        /// ------------------------------------------------------------
        
        /// GIVEN
        var sut: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// WHEN
        DispatchQueue.ExponentialBackoff<ExponentialBackoffCompatible>
            .execute(
                maxRetryCount: 10,
                maxRetryDelay: 30,
                scheduler: .default,
                handler: { ExponentialBackoffCompatible.fatalError },
                onSuccess: { value in
                    XCTFail("\(value)")
            },
                onError: { error in
                    sut = .error
                    XCTAssertEqual(sut, expected)
            },
                onMaxAttemptReached: {
                    XCTFail("Max attempt reached")
                    
            })
        /// ------------------------------------------------------------
    }
    
    func testExecute_OperationEndWithSuccessAfterThreeError_EndWithSuccess() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = .success(42)
        /// ------------------------------------------------------------
        
        /// GIVEN
        var attempt = 0
        var sut: ResultBackoffCall<Int>? = nil
        let expectation = self.expectation(description: #function)
        /// ------------------------------------------------------------
        
        /// WHEN
        DispatchQueue.ExponentialBackoff<ExponentialBackoffCompatible>
            .execute(
                maxRetryCount: 10,
                maxRetryDelay: 30,
                scheduler: .default,
                handler: { () -> ExponentialBackoffCompatible in
                    if attempt < 3 {
                        attempt += 1
                        return ExponentialBackoffCompatible.error
                    } else {
                        return ExponentialBackoffCompatible.success(42)
                    }
            },
                onSuccess: { value in
                    sut = .success(value)
                    expectation.fulfill()
            },
                onError: { error in
                    XCTFail(error.description)
            },
                onMaxAttemptReached: {
                    XCTFail("Max attempt reached")
                    
            })
        /// ------------------------------------------------------------
        
        /// THEN
        wait(for: [expectation], timeout: 30)
        XCTAssertEqual(sut, expected)
        /// ------------------------------------------------------------
    }
    
}
