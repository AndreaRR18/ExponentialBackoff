import Foundation

public class AsyncOperation: Operation {
  // Create state management
  var state = State.ready {
    willSet {
      willChangeValue(forKey: newValue.keyPath)
      willChangeValue(forKey: state.keyPath)
    }
    didSet {
      didChangeValue(forKey: oldValue.keyPath)
      didChangeValue(forKey: state.keyPath)
    }
  }

  // Override properties
  public override var isReady: Bool {
     super.isReady && state == .ready
  }

  public override var isExecuting: Bool {
    state == .executing
  }

  public override var isFinished: Bool {
    state == .finished
  }

  public override var isAsynchronous: Bool {
    true
  }

  // Override start
  public override func start() {
    main()
    state = .executing
  }
}

extension AsyncOperation {
  enum State: String {
    case ready, executing, finished

    fileprivate var keyPath: String {
      "is\(rawValue.capitalized)"
    }
  }
}
