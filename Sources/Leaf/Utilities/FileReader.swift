import Core
import Foundation

public protocol FileReader {
    func read(at path: String) -> Future<Data>
}

extension String: Error { }

extension DispatchData {
    static var empty: DispatchData {
        let buffer = UnsafeRawBufferPointer(start: nil, count: 0)
        return DispatchData(bytes: buffer)
    }
}

extension Data {
    var dispatchData: DispatchData {
        let pointer = BytesPointer(withUnsafeBytes { $0 })
        let buffer = UnsafeRawBufferPointer(start: UnsafeRawPointer(pointer), count: count)
        return DispatchData(bytes: buffer)
    }
}

// FIXME: does this work?
extension Array where Element: FutureType {
    public var resolved: Future<[Element.Expectation]> {
        let promise = Promise<[Element.Expectation]>()

        var elements: [Element.Expectation] = []

        var iterator = makeIterator()
        func doit(_ future: Element) {
            future.onComplete(asynchronously: nil) { element in
                do {
                    let res = try element.assertSuccess()
                    elements.append(res)
                    if let next = iterator.next() {
                        doit(next)
                    } else {
                        promise.complete(elements)
                    }
                } catch {
                    promise.complete(error)
                }
            }
        }

        if let first = iterator.next() {
            doit(first)
        } else {
            promise.complete(elements)
        }

        return promise.future
    }
}
