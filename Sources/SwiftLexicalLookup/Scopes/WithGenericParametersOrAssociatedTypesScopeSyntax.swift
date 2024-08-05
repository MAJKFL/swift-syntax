//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

@_spi(Experimental) public protocol WithGenericParametersOrAssociatedTypesScopeSyntax: ScopeSyntax {
  var genericParameterClause: GenericParameterClauseSyntax? { get }
  var primaryAssociatedTypeClause: PrimaryAssociatedTypeClauseSyntax? { get }
}

@_spi(Experimental) extension WithGenericParametersOrAssociatedTypesScopeSyntax {
  @_spi(Experimental) public var genericParameterClause: GenericParameterClauseSyntax? { nil }
  @_spi(Experimental) public var primaryAssociatedTypeClause: PrimaryAssociatedTypeClauseSyntax? { nil }
  
  @_spi(Experimental) public func lookup(
    for identifier: Identifier?,
    at origin: AbsolutePosition,
    with config: LookupConfig
  ) -> [LookupResult] {
    return defaultLookupImplementation(
      for: identifier,
      at: position,
      with: config,
      propagateToParent: false
    )
      + lookupThroughGenericParameterScope(
        for: identifier,
        at: origin,
        with: config
      )
  }

  private func lookupThroughGenericParameterScope(
    for identifier: Identifier?,
    at origin: AbsolutePosition,
    with config: LookupConfig
  ) -> [LookupResult] {
    if let genericParameterClause {
      return genericParameterClause.lookup(for: identifier, at: origin, with: config)
    } else if let primaryAssociatedTypeClause {
      return primaryAssociatedTypeClause.lookup(for: identifier, at: origin, with: config)
    } else {
      return lookupInParent(for: identifier, at: origin, with: config)
    }
  }
}
