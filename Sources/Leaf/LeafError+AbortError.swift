import Vapor
import LeafKit

extension LeafError {
    /// This logic from ``LeafKit/LeafError`` must be duplicated here so we don't end up in infinite
    /// recursion trying to access it via the ``localizedDescription`` property.
    fileprivate var reasonString: String {
        switch self.reason as Reason {
            case .illegalAccess(let message):
                return "\(message)"
            case .unknownError(let message):
                return "\(message)"
            case .unsupportedFeature(let feature):
                return "\(feature) is not implemented"
            case .cachingDisabled:
                return "Caching is globally disabled"
            case .keyExists(let key):
                return "Existing entry \(key); use insert with replace=true to overrride"
            case .noValueForKey(let key):
                return "No cache entry exists for \(key)"
            case .unresolvedAST(let key, let dependencies):
                return "Flat AST expected; \(key) has unresolved dependencies: \(dependencies)"
            case .noTemplateExists(let key):
                return "No template found for \(key)"
            case .cyclicalReference(let key, let chain):
                return "\(key) cyclically referenced in [\(chain.joined(separator: " -> "))]"
            case .lexerError(let e):
                return "Lexing error - \(e.localizedDescription)"
        }
    }
}

/// Conforming ``LeafKit/LeafError`` to ``Vapor/AbortError`` significantly improves the quality of the
/// output generated by the `ErrorMiddleware` should such an error be the outcome a request.
extension LeafError: AbortError {
    /// The use of `@_implements` here allows us to get away with the fact that ``Vapor/AbortError``
    /// requires a property named `reason` of type `String` while ``LeafKit/LeafError`` has an
    /// identically named property of an enum type.
    ///
    /// See ``Vapor/AbortError/reason``.
    @_implements(AbortError, reason)
    public var abortReason: String { self.reasonString }
    
    /// See ``Vapor/AbortError/status``.
    public var status: HTTPResponseStatus { .internalServerError }
}

/// Conforming ``LeafKit/LeafError`` to ``Vapor/DebuggableError`` allows more and more useful information
/// to be reported when the error is logged to a ``Logging/Logger``.
extension LeafError: DebuggableError {
    /// Again, the udnerscored attribute gets around the inconvenient naming collision.
    ///
    /// See ``Vapor/DebuggableError/reason``.
    @_implements(DebuggableError, reason)
    public var debuggableReason: String { self.reasonString }

    /// See ``Vapor/DebuggableError/source``.
    public var source: ErrorSource? {
        .init(file: self.file, function: self.function, line: self.line, column: self.column)
    }
}
