/// A byte.
typealias Byte = UInt8

/// Leaf specific byte helpers
extension Byte {
    /// Returns whether or not the given byte can be considered UTF8 whitespace
    public var isWhitespace: Bool {
        return self == .space || self == .newLine || self == .carriageReturn || self == .horizontalTab
    }

    /// Returns whether or not the given byte is an arabic letter
    public var isLetter: Bool {
        return (.a ... .z).contains(self) || (.A ... .Z).contains(self)
    }

    /// Returns whether or not a given byte represents a UTF8 digit 0 through 9
    public var isDigit: Bool {
        return (.zero ... .nine).contains(self)
    }

    /// Returns whether or not a given byte represents a UTF8 digit 0 through 9, or an arabic letter
    public var isAlphanumeric: Bool {
        return isLetter || isDigit
    }

    /// Returns whether a given byte can be interpreted as a hex value in UTF8, ie: 0-9, a-f, A-F.
    public var isHexDigit: Bool {
        return (.zero ... .nine).contains(self) || (.A ... .F).contains(self) || (.a ... .f).contains(self)
    }


    func makeString() -> String {
        // FIXME: more efficient?
        let utf8 = [CChar(bitPattern: self), 0]
        return String(validatingUTF8: utf8) ?? ""
    }

    var isAllowedInIdentifier: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .period
    }

    var isAllowedInTagName: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .forwardSlash || self == .asterisk
    }
    
    // FIXME: add to core
    static let pipe: UInt8 = 0x7C
}

func ~=(pattern: UInt8, value: UInt8?) -> Bool {
    return pattern == value
}

// MARK: Control

extension Byte {
    /// '\t'
    static let horizontalTab: Byte = 0x9

    /// '\n'
    static let newLine: Byte = 0xA

    /// '\r'
    static let carriageReturn: Byte = 0xD

    /// ' '
    static let space: Byte = 0x20

    /// !
    static let exclamation: Byte = 0x21

    /// "
    static let quote: Byte = 0x22

    /// #
    static let numberSign: Byte = 0x23

    /// $
    static let dollar: Byte = 0x24

    /// %
    static let percent: Byte = 0x25

    /// &
    static let ampersand: Byte = 0x26

    /// '
    static let apostrophe: Byte = 0x27

    /// (
    static let leftParenthesis: Byte = 0x28

    /// )
    static let rightParenthesis: Byte = 0x29

    /// *
    static let asterisk: Byte = 0x2A

    /// +
    static let plus: Byte = 0x2B

    /// ,
    static let comma: Byte = 0x2C

    /// -
    static let hyphen: Byte = 0x2D

    /// .
    static let period: Byte = 0x2E

    /// /
    static let forwardSlash: Byte = 0x2F

    /// \
    static let backSlash: Byte = 0x5C

    /// :
    static let colon: Byte = 0x3A

    /// ;
    static let semicolon: Byte = 0x3B

    /// =
    static let equals: Byte = 0x3D

    /// ?
    static let questionMark: Byte = 0x3F

    /// @
    static let at: Byte = 0x40

    /// [
    static let leftSquareBracket: Byte = 0x5B

    /// ]
    static let rightSquareBracket: Byte = 0x5D

    /// _
    static let underscore: Byte = 0x5F

    /// ~
    static let tilda: Byte = 0x7E

    /// {
    static let leftCurlyBracket: Byte = 0x7B

    /// }
    static let rightCurlyBracket: Byte = 0x7D

    /// <
    static let lessThan: Byte = 0x3C

    /// >
    static let greaterThan: Byte = 0x3E
}

extension Byte {
    /// Defines the `crlf` used to denote
    /// line breaks in HTTP and many other
    ///  formatters
    static let crlf: [Byte] = [
        .carriageReturn,
        .newLine
    ]
}

// MARK: Alphabet

extension Byte {
    /// A
    static let A: Byte = 0x41

    /// B
    static let B: Byte = 0x42

    /// C
    static let C: Byte = 0x43

    /// D
    static let D: Byte = 0x44

    /// E
    static let E: Byte = 0x45

    /// F
    static let F: Byte = 0x46

    /// F
    static let G: Byte = 0x47

    /// F
    static let H: Byte = 0x48

    /// F
    static let I: Byte = 0x49

    /// F
    static let J: Byte = 0x4A

    /// F
    static let K: Byte = 0x4B

    /// F
    static let L: Byte = 0x4C

    /// F
    static let M: Byte = 0x4D

    /// F
    static let N: Byte = 0x4E

    /// F
    static let O: Byte = 0x4F

    /// F
    static let P: Byte = 0x50

    /// F
    static let Q: Byte = 0x51

    /// F
    static let R: Byte = 0x52

    /// F
    static let S: Byte = 0x53

    /// F
    static let T: Byte = 0x54

    /// F
    static let U: Byte = 0x55

    /// F
    static let V: Byte = 0x56

    /// F
    static let W: Byte = 0x57

    /// F
    static let X: Byte = 0x58

    /// F
    static let Y: Byte = 0x59

    /// Z
    static let Z: Byte = 0x5A
}

extension Byte {
    /// a
    static let a: Byte = 0x61

    /// b
    static let b: Byte = 0x62

    /// c
    static let c: Byte = 0x63

    /// d
    static let d: Byte = 0x64

    /// e
    static let e: Byte = 0x65

    /// f
    static let f: Byte = 0x66

    /// g
    static let g: Byte = 0x67

    /// h
    static let h: Byte = 0x68

    /// i
    static let i: Byte = 0x69

    /// j
    static let j: Byte = 0x6A

    /// k
    static let k: Byte = 0x6B

    /// l
    static let l: Byte = 0x6C

    /// m
    static let m: Byte = 0x6D

    /// n
    static let n: Byte = 0x6E

    /// o
    static let o: Byte = 0x6F

    /// p
    static let p: Byte = 0x70

    /// q
    static let q: Byte = 0x71

    /// r
    static let r: Byte = 0x72

    /// s
    static let s: Byte = 0x73

    /// t
    static let t: Byte = 0x74

    /// u
    static let u: Byte = 0x75

    /// v
    static let v: Byte = 0x76

    /// w
    static let w: Byte = 0x77

    /// x
    static let x: Byte = 0x78

    /// y
    static let y: Byte = 0x79

    /// z
    static let z: Byte = 0x7A
}

// MARK: Digits

extension Byte {

    /// 0 in utf8
    static let zero: Byte = 0x30

    /// 1 in utf8
    static let one: Byte = 0x31

    /// 2 in utf8
    static let two: Byte = 0x32

    /// 3 in utf8
    static let three: Byte = 0x33

    /// 4 in utf8
    static let four: Byte = 0x34

    /// 5 in utf8
    static let five: Byte = 0x35

    /// 6 in utf8
    static let six: Byte = 0x36

    /// 7 in utf8
    static let seven: Byte = 0x37

    /// 8 in utf8
    static let eight: Byte = 0x38

    /// 9 in utf8
    static let nine: Byte = 0x39
}
