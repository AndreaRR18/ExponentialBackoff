public enum ExponentialBackoffResultType<Success, Error> {
    case success(Success)
    case unsolvable(Error)
    case solvable
}
