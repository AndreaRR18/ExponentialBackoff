import Foundation

extension Operation {
    
    public class ExponentialBackoff<Event>: AsyncOperation where Event: ExponentialBackoffCompatibleType {
        
        let maxRetryCount: Int
        let maxRetryDelay: Int
        let scheduler: DispatchQoS.QoSClass
        let currentAttempt: Int
        let handler: () -> Event
        
        private(set) var onSuccessValue: Event.Success? = nil
        private(set) var onErrorValue: Event.HandlerError? = nil
        private(set) var onMaxAttemptreachedValue: Bool = false
        
        private lazy var operationQueue = OperationQueue()
        
        public init(
            maxRetryCount: Int = 10,
            maxRetryDelay: Int = 30,
            scheduler: DispatchQoS.QoSClass = .background,
            handler: @escaping () -> Event
        ) {
            self.handler = handler
            self.maxRetryCount = maxRetryCount
            self.maxRetryDelay = maxRetryDelay
            self.currentAttempt = 0
            self.scheduler = scheduler
        }
        
        private func retry(
            handler: @escaping () -> Event,
            maxRetryCount: Int,
            maxRetryDelay: Int,
            currentAttempt: Int
        ) {
            
            guard currentAttempt < maxRetryCount else {
                self.onMaxAttemptreachedValue = true
                self.state = .finished
                return
            }
            
            handler().handle { future in
                switch future {
                case let .success(success):
                    self.onSuccessValue = success
                    self.state = .finished
                    
                case let .unsolvable(error):
                    self.onErrorValue = error
                    self.state = .finished
                    
                case .solvable:
                    Thread.sleep(forTimeInterval: TimeInterval(
                        self.getInterval(
                            at: currentAttempt,
                            withMaxValue: maxRetryCount,
                            maxRetryDelay: maxRetryDelay)
                    ))
                    
                    self.retry(
                        handler: handler,
                        maxRetryCount: maxRetryCount,
                        maxRetryDelay: maxRetryDelay,
                        currentAttempt: currentAttempt + 1
                    )
                }
            }
        }
        
        public override func main() {
            DispatchQueue.global(qos: scheduler).async { [weak self] in
                guard let self = self else { return }
                
                self.retry(
                    handler: self.handler,
                    maxRetryCount: self.maxRetryCount,
                    maxRetryDelay: self.maxRetryDelay,
                    currentAttempt: self.currentAttempt
                )
            }
        }
        
        public func subscribe(
            onSuccess: @escaping (Event.Success) -> Void = { _ in },
            onError: @escaping (Event.HandlerError) -> Void = { _ in },
            onMaxAttemptReached: @escaping () -> Void = { }
        ) {
            
            operationQueue.addOperation(self)
            
            self.completionBlock = { [weak self] in
                guard let self = self else { return }
                
                if let success = self.onSuccessValue {
                    onSuccess(success)
                } else if let error = self.onErrorValue {
                    onError(error)
                }
                
                if self.onMaxAttemptreachedValue {
                    onMaxAttemptReached()
                }
                
            }
        }
        
        private func getInterval(
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
