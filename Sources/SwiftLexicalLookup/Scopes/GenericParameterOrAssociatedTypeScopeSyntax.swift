//
//  File.swift
//  
//
//  Created by Jakub Florek on 05/08/2024.
//

import SwiftSyntax

@_spi(Experimental) public protocol GenericParameterOrAssociatedTypeScopeSyntax: ScopeSyntax {}

@_spi(Experimental) extension GenericParameterOrAssociatedTypeScopeSyntax {
  @_spi(Experimental) public func lookup(
    for identifier: Identifier?,
    at origin: AbsolutePosition,
    with config: LookupConfig
  ) -> [LookupResult] {
    return defaultLookupImplementation(
      for: identifier,
      at: origin,
      with: config,
      propagateToParent: false
    )
      + lookupBypassingParentResults(
        for: identifier,
        at: origin,
        with: config
      )
  }

  private func lookupBypassingParentResults(
    for identifier: Identifier?,
    at origin: AbsolutePosition,
    with config: LookupConfig
  ) -> [LookupResult] {
    guard let parentScope else { return [] }

    if let parentScope = Syntax(parentScope).asProtocol(SyntaxProtocol.self) as? WithGenericParametersOrAssociatedTypesScopeSyntax {
      return parentScope.lookupInParent(for: identifier, at: origin, with: config)
    } else {
      return []
    }
  }
}
