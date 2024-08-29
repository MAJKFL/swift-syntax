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

/// Represents result from a specific scope.
@_spi(Experimental) public enum LookupResult {
  /// Scope and the names that matched lookup.
  case fromScope(ScopeSyntax, withNames: [LookupName])
  /// File scope and names that matched lookup.
  case fromFileScope(SourceFileSyntax, withNames: [LookupName])
  /// Client should perform qualified lookup at this result.
  indirect case shouldPerformQualifiedLookup(LookupResult)

  /// Associated scope.
  @_spi(Experimental) public var scope: ScopeSyntax? {
    switch self {
    case .fromScope(let scopeSyntax, _):
      return scopeSyntax
    case .fromFileScope(let fileScopeSyntax, _):
      return fileScopeSyntax
    case .shouldPerformQualifiedLookup(let result):
      return result.scope
    }
  }

  /// Names that matched lookup.
  @_spi(Experimental) public var names: [LookupName] {
    switch self {
    case .fromScope(_, let names), .fromFileScope(_, let names):
      return names
    case .shouldPerformQualifiedLookup(let result):
      return result.names
    }
  }

  /// Returns result specific for the particular `scope` kind with provided `names`.
  static func getResult(for scope: ScopeSyntax, withNames names: [LookupName]) -> LookupResult {
    switch Syntax(scope).as(SyntaxEnum.self) {
    case .sourceFile(let sourceFileSyntax):
      return .fromFileScope(sourceFileSyntax, withNames: names)
    default:
      return .fromScope(scope, withNames: names)
    }
  }
}
