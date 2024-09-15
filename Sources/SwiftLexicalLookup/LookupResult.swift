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
  /// Declaration that members should be looked up.
  case lookInMembers(LookInMembersScopeSyntax)

  /// Associated scope.
  @_spi(Experimental) public var scope: ScopeSyntax {
    switch self {
    case .fromScope(let scopeSyntax, _):
      return scopeSyntax
    case .fromFileScope(let fileScopeSyntax, _):
      return fileScopeSyntax
    case .lookInMembers(let lookInMemb):
      return lookInMemb
    }
  }

  /// Names that matched lookup.
  @_spi(Experimental) public var names: [LookupName] {
    switch self {
    case .fromScope(_, let names), .fromFileScope(_, let names):
      return names
    case .lookInMembers(_):
      return []
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

  @_spi(Experimental) public func debugDescription(
    with sourceLocationConverter: SourceLocationConverter
  ) -> String {
    var description =
      resultKindName + ": " + scope.scopeDebugDescription(sourceLocationConverter: sourceLocationConverter)

    switch self {
    case .lookInMembers:
      break
    default:
      if !names.isEmpty {
        description += "\n"
      }
    }

    for (index, name) in names.enumerated() {
      if index + 1 == names.count {
        description += "`-" + name.debugDescription(with: sourceLocationConverter)
      } else {
        description += "|-" + name.debugDescription(with: sourceLocationConverter) + "\n"
      }
    }

    return description
  }

  private var resultKindName: String {
    switch self {
    case .fromScope:
      return "fromScope"
    case .fromFileScope:
      return "fromFileScope"
    case .lookInMembers:
      return "lookInMembers"
    }
  }
}

@_spi(Experimental) extension [LookupResult] {
  @_spi(Experimental) public func debugDescription(with sourceLocationConverter: SourceLocationConverter) -> String {
    var str: String = ""

    for (index, result) in self.enumerated() {
      str += result.debugDescription(with: sourceLocationConverter) + (index + 1 == self.count ? "" : "\n")
    }

    return str
  }
}
