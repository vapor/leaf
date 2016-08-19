/**
 Copyright (c) 2014, Kyle Fuller
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


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
     The child of this branch
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
    required public init(_ output: Value) {
        self.value = output
    }

    public subscript(idx: Int) -> Value? {
        get {
            guard idx > 0 else { return value }
            guard let child = child else { return nil }
            return child[idx - 1]
        }
    }

    func extend(_ output: Value) {
        if let child = child {
            child.extend(output)
        } else {
            child = Link(output)
        }
    }

    func tail() -> Link {
        guard let child = child else { return self }
        return child.tail()
    }
}

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

public final class List<Value> {
    private var tip: Link<Value>?

    public init() {}

    subscript(idx: Int) -> Value? {
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


/**
    The associated context used in rendering
*/
public final class Context {
    //public internal(set) var queue: [Node] = []
    public internal(set) var queue = List<Node>()

    public init(_ node: Node) {
        // self.queue.append(node)
        queue.insertAtTip(node)
    }

    // TODO: Subscripts

    public func get(key: String) -> Node? {
        return queue.lazy.flatMap { $0[key] } .first
    }

    public func get(path: String) -> Node? {
        let components = path.components(separatedBy: ".")
        return get(path: components)
    }

    public func get(path: [String]) -> Node? {
        for node in queue {
            guard let value = node[path] else { continue }
            return value
        }
        return nil
    }

    public func push(_ fuzzy: Node) {
        queue.insertAtTip(fuzzy)
        // queue.insert(fuzzy, at: 0)
    }

    @discardableResult
    public func pop() -> Node? {
        return queue.removeTip()
        /*
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
 */
    }
}


extension Context {
    internal func renderedSelf() throws -> Bytes? {
        return try get(path: "self")?.rendered()
    }
}
