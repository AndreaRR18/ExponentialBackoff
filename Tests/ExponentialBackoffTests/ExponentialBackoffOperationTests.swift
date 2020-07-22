import XCTest
@testable import ExponentialBackoff

class ExponentialBackoffOperation: XCTestCase {
    
    
    func testSubscribe_OperationEndWithSuccess_EndWithSuccess() {
        
        /// EXPECTED----------------------------------------------------
        let expected = ResultBackoffCall.success(42)
        /// ------------------------------------------------------------
        
        /// GIVEN
        let exponentialBackoff =  Operation.ExponentialBackoff(
            maxRetryCount: 10,
            maxRetryDelay: 30,
            scheduler: .userInteractive,
            handler: { ExponentialBackoffCompatible.success(42) })
        
        var sut: ResultBackoffCall<Int>? = nil
        
        let expectation = self.expectation(description: #function)
        /// ------------------------------------------------------------
        
        /// WHEN
        exponentialBackoff.subscribe(
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
    
    func testSubscribe_OperationEndWithSuccessAfter5Seconds_SutIsStillNil() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// GIVEN
        let exponentialBackoff =  Operation.ExponentialBackoff(
            maxRetryCount: 10,
            maxRetryDelay: 30,
            scheduler: .default,
            handler: { ExponentialBackoffCompatible.success(42) })
        
        var sut: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// WHEN
        exponentialBackoff.subscribe(
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
    
    func testSubscribe_OperationEndWithMaxAttemptReached_EndWithFailure() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = .maxAttemptReached
        /// ------------------------------------------------------------
        
        /// GIVEN
        let exponentialBackoff =  Operation.ExponentialBackoff(
            maxRetryCount: 2,
            maxRetryDelay: 30,
            scheduler: .default,
            handler: { ExponentialBackoffCompatible.error })
        
        var sut: ResultBackoffCall<Int>? = nil
        let expectation = self.expectation(description: #function)
        /// ------------------------------------------------------------
        
        /// WHEN
        exponentialBackoff.subscribe(
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
    
    func testSubscribe_OperationEndWithError_EndWithFailure() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = .error
        /// ------------------------------------------------------------
        
        /// GIVEN
        let exponentialBackoff =  Operation.ExponentialBackoff(
            maxRetryCount: 2,
            maxRetryDelay: 30,
            scheduler: .default,
            handler: { ExponentialBackoffCompatible.fatalError })
        
        var sut: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// WHEN
        exponentialBackoff.subscribe(
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
    
    func testSubscribe_OperationEndWithSuccessAfterThreeError_EndWithSuccess() {
        
        /// EXPECTED----------------------------------------------------
        let expected: ResultBackoffCall<Int>? = .success(42)
        /// ------------------------------------------------------------
        
        /// GIVEN
        var attempt = 0
        let exponentialBackoff =  Operation.ExponentialBackoff(
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
        })
        
        var sut: ResultBackoffCall<Int>? = nil
        let expectation = self.expectation(description: #function)
        /// ------------------------------------------------------------
        
        /// WHEN
        exponentialBackoff.subscribe(
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
    
    func testOperationQueue_MultipleBackoffOperationWithSuccess_EndWithSuccess() {
        /// EXPECTED----------------------------------------------------
        let expected1: ResultBackoffCall<Int>? = .success(42)
        let expected2: ResultBackoffCall<Int>? = .success(24)
        /// ------------------------------------------------------------
        
        /// GIVEN
        var attempt = 0
        let exponentialBackoff1 =  Operation.ExponentialBackoff(
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
        })
        
        let exponentialBackoff2 =  Operation.ExponentialBackoff(
            maxRetryCount: 10,
            maxRetryDelay: 30,
            scheduler: .default,
            handler: { () -> ExponentialBackoffCompatible in
                if attempt < 3 {
                    attempt += 1
                    return ExponentialBackoffCompatible.error
                } else {
                    return ExponentialBackoffCompatible.success(24)
                }
        })
        
        var sut1: ResultBackoffCall<Int>? = nil
        var sut2: ResultBackoffCall<Int>? = nil
        /// ------------------------------------------------------------
        
        /// WHEN
       let queue = OperationQueue()
        /// ------------------------------------------------------------
        
        /// THEN
        exponentialBackoff1.completionBlock = {
            sut1 = .success(exponentialBackoff1.onSuccessValue!)
            XCTAssertEqual(sut1, expected1)
        }
        exponentialBackoff2.completionBlock = {
            sut2 = .success(exponentialBackoff2.onSuccessValue!)
            XCTAssertEqual(sut2, expected2)
        }
        queue.addOperation(exponentialBackoff1)
        queue.addOperation(exponentialBackoff2)
        /// ------------------------------------------------------------
    }
    
}
