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
    The associated context used in rendering
*/
public final class Context {
    public internal(set) var queue = List<Node>()

    public init(_ node: Node) {
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
    }

    @discardableResult
    public func pop() -> Node? {
        return queue.removeTip()
    }
}


extension Context {
    internal func renderedSelf() throws -> Bytes? {
        return try get(path: "self")?.rendered()
    }
}
