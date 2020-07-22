import Foundation

extension DispatchQueue {
    public struct ExponentialBackoff<Event> where Event: ExponentialBackoffCompatibleType {
        
        static public func execute(
            maxRetryCount: Int = 10,
            maxRetryDelay: Int = 30,
            scheduler: DispatchQoS.QoSClass = .background,
            handler: @escaping () -> Event,
            onSuccess: @escaping (Event.Success) -> () = { _ in },
            onError: @escaping (Event.HandlerError) -> () = { _ in },
            onMaxAttemptReached: @escaping () -> () = { }
        ) {
            
            retry(
                handler: handler,
                maxRetryCount: maxRetryCount,
                maxRetryDelay: maxRetryDelay,
                currentAttempt: 0,
                scheduler: scheduler,
                onSuccess: onSuccess,
                onError: onError,
                onMaxAttemptReached: onMaxAttemptReached)
        }
        
        private static func retry(
            handler: @escaping () -> Event,
            maxRetryCount: Int,
            maxRetryDelay: Int,
            currentAttempt: Int,
            scheduler: DispatchQoS.QoSClass,
            onSuccess: @escaping (Event.Success) -> (),
            onError: @escaping (Event.HandlerError) -> (),
            onMaxAttemptReached: @escaping () -> ()
        ) {
            
            guard currentAttempt < maxRetryCount else {
                onMaxAttemptReached()
                return
            }
            
            DispatchQueue.global(qos: scheduler).async {
                
                handler().handle { future in
                    switch future {
                    case let .success(success):
                        onSuccess(success)
                        
                    case let .unsolvable(error):
                        onError(error)
                        
                    case .solvable:
                        Thread.sleep(
                            forTimeInterval: TimeInterval(
                                getInterval(
                                    at: currentAttempt,
                                    withMaxValue: maxRetryCount,
                                    maxRetryDelay: maxRetryDelay)
                        ))
                        
                        retry(
                            handler: handler,
                            maxRetryCount: maxRetryCount,
                            maxRetryDelay: maxRetryDelay,
                            currentAttempt: currentAttempt + 1,
                            scheduler: scheduler,
                            onSuccess: onSuccess,
                            onError: onError,
                            onMaxAttemptReached: onMaxAttemptReached
                        )
                        
                    }
                }
            }
        }
        
        private static func getInterval(
            at index: Int,
            withMaxValue maxValue: Int,
            maxRetryDelay: Int
        ) -> Int {
            
            guard maxValue > 1 else { return 0 }
            
            var array = [0, 1]
            while array.count < maxValue {
                array.append(array[array.count - 1] + array[array.count - 2])
            }
            guard array[index] < maxRetryDelay else { return maxRetryDelay }
            return array[index]
        }
        
    }
}
