@testable import ExponentialBackoff

extension String: Error {}

enum ExponentialBackoffCompatible: ExponentialBackoffCompatibleType {
    
    case success(Int)
    case error
    case fatalError
    
    typealias Success = Int
    typealias HandlerError = String
    
    func handle(_ f: @escaping (ExponentialBackoffResultType<Int, String>) -> ()) {

        switch self {
        case .success(let value):
            f(.success(value))
        case .error:
            f(.solvable)
        case .fatalError:
            f(.unsolvable("FatalError"))
            
        }
    }
    
}

enum ResultBackoffCall<Value>: Equatable where Value: Equatable {
    case success(Value)
    case maxAttemptReached
    case error
}
