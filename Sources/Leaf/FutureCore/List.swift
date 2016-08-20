/**
 When routing requests, different branches will be established,
 in a linked list style stemming from their host and request method.
 It can be represented as:
 | host | request.method | branch -> branch -> branch
 */
public final class Link<Value> { // TODO: Rename Context
    /**
     The immediate parent of this branch. `nil` if current branch is a terminator
     */
    public fileprivate(set) var parent: Link?

    /**
     The child of this link
     */
    public fileprivate(set) var child: Link?

    /**
     There are two types of branches, those that support a handler,
     and those that are a linker between branches,
     for example /users/messages/:id will have 3 connected branches,
     only one of which supports a handler.
     Branch('users') -> Branch('messages') -> *Branches('id')
     *indicates a supported branch.
     */
    public let value: Value

    /**
     Used to create a new branch
     - parameter name: The name associated with the branch, or the key when dealing with a slug
     - parameter handler: The handler to be called if its a valid endpoint, or `nil` if this is a bridging branch
     - returns: an initialized request Branch
     */
    public required init(_ output: Value) {
        self.value = output
    }

    public subscript(idx: Int) -> Value? {
        guard idx > 0 else { return value }
        guard let child = child else { return nil }
        return child[idx - 1]
    }

    public func extend(_ output: Value) {
        if let child = child {
            child.extend(output)
        } else {
            child = Link(output)
        }
    }

    public func tail() -> Link {
        guard let child = child else { return self }
        return child.tail()
    }
}

/**
    This class represents a linked list structure for situations
    where performance lists are required.
*/
public final class List<Value> {
    private var tip: Link<Value>?

    public init() {}

    public subscript(idx: Int) -> Value? {
        return tip?[idx]
    }

    public func insertAtTip(_ value: Value) {
        let link = Link(value)
        link.child = tip
        tip?.parent = link

        // replace tip
        tip = link
    }

    public func insertAtTail(_ value: Value) {
        if let tip = tip {
            tip.extend(value)
        } else {
            tip = Link(value)
        }
    }

    @discardableResult
    public func removeTip() -> Value? {
        let tip = self.tip
        self.tip = tip?.child
        return tip?.value
    }

    @discardableResult
    public func removeTail() -> Value? {
        let tail = tip?.tail()
        tail?.parent?.child = nil
        return tail?.value
    }
}

// MARK: Sequence

extension List: Sequence {
    public typealias Iterator = AnyIterator<Value>

    public func makeIterator() -> AnyIterator<Value> {
        var tip = self.tip
        return AnyIterator {
            let next = tip
            tip = next?.child
            return next?.value
        }
    }
}

extension List {
    public convenience init<S: Sequence where S.Iterator.Element == Value>(_ s: S) {
        self.init()
        s.forEach(insertAtTail)
    }
}
