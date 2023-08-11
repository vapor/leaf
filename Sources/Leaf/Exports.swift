#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import protocol LeafKit.LeafTag
@_documentation(visibility: internal) @_exported import protocol LeafKit.UnsafeUnescapedLeafTag
@_documentation(visibility: internal) @_exported import struct LeafKit.LeafData
@_documentation(visibility: internal) @_exported import struct LeafKit.LeafContext
@_documentation(visibility: internal) @_exported import enum LeafKit.Syntax

#else

@_exported import protocol LeafKit.LeafTag
@_exported import protocol LeafKit.UnsafeUnescapedLeafTag
@_exported import struct LeafKit.LeafData
@_exported import struct LeafKit.LeafContext
@_exported import enum LeafKit.Syntax

#endif
