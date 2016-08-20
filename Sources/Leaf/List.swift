/**
    This class represents a linked list structure for situations
    where performance lists are required.
*/
public final class List<Value> {
    private var tip: Link<Value>?

    public init() {}

    public func insertAtTip(_ value: Value) {
        let newTip = Link(value)
        newTip.addChild(tip)
        tip = newTip
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
        tail?.dropParent()
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
