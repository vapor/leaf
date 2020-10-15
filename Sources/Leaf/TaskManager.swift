import NIO
import NIOConcurrencyHelpers

private class TaskDistributor<Value> {
  let lock: Lock = .init()
  var active: Int = 0
  var result: EventLoopPromise<[Value]>
  var loops: [EventLoop] = []
  var tasks: [(() -> Value)?]
  var results: [EventLoopFuture<Value>?]
   
  init(_ tasks: [() -> Value], _ on: EventLoopGroup, _ returnOn: EventLoop, _ loopCount: Int) {
    self.result = returnOn.makePromise(of: [Value].self)
    self.tasks = tasks
    self.results = .init(repeating: nil, count: tasks.count)
    for _ in (1...loopCount) { self.loops.append(on.next()) }
  }

  var nextToDo: (Int, () -> Value)? {
    lock.withLock {
      guard let toDo = tasks.firstIndex(where: {$0 != nil}) else { return nil }
      let task = tasks[toDo]!
      tasks[toDo] = nil
      return (toDo, task)
    }
  }

  func assign(_ task: (Int, () -> Value), _ lIndex: Int) {
    lock.withLockVoid {
      active += 1
      results[task.0] = loops[lIndex].submit { task.1() }
    }
  }
   
  func complete(task tIndex: Int, loop lIndex: Int) {
    lock.withLockVoid {
      active -= 1
      if let uncomplete = nextToDo { assign(uncomplete, lIndex) }
      else if active == 0 { fulfill() }
    }
  }

  func fulfill() {
    precondition(!results.contains(nil), "Should not fulfill until all tasks have ELFs")
    _ = EventLoopFuture.reduce(into: [],
                               results.compactMap {$0},
                               on: result.futureResult.eventLoop) { $0.append($1) }
                        .map { self.result.succeed($0) }
  }
    
  var process: EventLoopFuture<[Value]> {
    if tasks.isEmpty { result.succeed([]) }
    else { loops.indices.forEach { if let uncomplete = nextToDo {assign(uncomplete, $0)} } }
    return result.futureResult
  }
}

public extension EventLoopGroup {
  func processDistributedTasks<Value>(_ tasks: [() -> Value],
                                      returnOn: EventLoop,
                                      loopCount: Int = 1) -> EventLoopFuture<[Value]> {
    let distributor = TaskDistributor(tasks, self, returnOn, loopCount)
    return distributor.process
  }
}
