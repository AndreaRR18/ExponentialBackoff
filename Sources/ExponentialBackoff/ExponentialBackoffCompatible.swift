public protocol ExponentialBackoffCompatibleType {
    associatedtype Success
    associatedtype HandlerError: Error
    func handle(_ f: @escaping (ExponentialBackoffResultType<Self.Success, HandlerError>) -> ())
}
