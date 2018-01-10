/// A reference type wrapper around TemplateData for passing
/// between multiple encoders.
internal final class PartialTemplateData {
    /// The in-progress leaf data.
    var data: TemplateData

    /// Creates a new partial leaf data.
    init() {
        self.data = .dictionary([:])
    }

    /// Sets the partial leaf data to a value at the given path.
    func set(to value: TemplateData, at path: [CodingKey]) {
        set(&data, to: value, at: path)
    }

    /// Sets mutable leaf input to a value at the given path.
    private func set(_ context: inout TemplateData, to value: TemplateData?, at path: [CodingKey]) {
        guard path.count >= 1 else {
            context = value ?? .null
            return
        }

        let end = path[0]

        var child: TemplateData?
        switch path.count {
        case 1:
            child = value
        case 2...:
            if let index = end.intValue {
                let array = context.array ?? []
                if array.count > index {
                    child = array[index]
                } else {
                    child = TemplateData.array([])
                }
                set(&child!, to: value, at: Array(path[1...]))
            } else {
                child = context.dictionary?[end.stringValue] ?? TemplateData.dictionary([:])
                set(&child!, to: value, at: Array(path[1...]))
            }
        default: break
        }

        if let index = end.intValue {
            if case .array(var arr) = context {
                if arr.count > index {
                    arr[index] = child ?? .null
                } else {
                    arr.append(child ?? .null)
                }
                context = .array(arr)
            } else if let child = child {
                context = .array([child])
            }
        } else {
            if case .dictionary(var dict) = context {
                dict[end.stringValue] = child
                context = .dictionary(dict)
            } else if let child = child {
                context = .dictionary([
                    end.stringValue: child
                ])
            }
        }
    }

    /// Returns the value, if one at from the given path.
    func get(at path: [CodingKey]) -> TemplateData? {
        var child = data

        for seg in path {
            guard let c = child.dictionary?[seg.stringValue] else {
                return nil
            }
            child = c
        }

        return child
    }
}
