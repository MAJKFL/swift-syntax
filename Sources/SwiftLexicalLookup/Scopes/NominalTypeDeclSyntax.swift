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

protocol NominalTypeDeclSyntax: LookInMembersScopeSyntax, DeclSyntaxProtocol, WithGenericParametersScopeSyntax {
  var inheritanceClause: InheritanceClauseSyntax? { get }
}

extension NominalTypeDeclSyntax {
  @_spi(Experimental) public var introducedNames: [LookupName] {
    []
  }
  
  func returningLookupFromGenericParameterScope(
    _ identifier: Identifier?,
    at lookUpPosition: AbsolutePosition,
    with config: LookupConfig
  ) -> [LookupResult] {
    if let inheritanceClause, inheritanceClause.range.contains(lookUpPosition) {
      return lookupInParent(identifier, at: lookUpPosition, with: config)
    } else {
      return [.lookInMembers(self)] + lookupInParent(identifier, at: lookUpPosition, with: config)
    }
  }
}
