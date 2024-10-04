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
  /// Indicates where to perform member lookup.
  case lookInMembers(LookInMembersScopeSyntax)
  /// Indicates to lookup generic parameters of extended type.
  case lookInGenericParametersOfExtendedType(ExtensionDeclSyntax)

  /// Associated scope.
  @_spi(Experimental) public var scope: ScopeSyntax {
    switch self {
    case .fromScope(let scopeSyntax, _):
      return scopeSyntax
    case .fromFileScope(let fileScopeSyntax, _):
      return fileScopeSyntax
    case .lookInMembers(let lookInMemb):
      return lookInMemb
    case .lookInGenericParametersOfExtendedType(let extensionDecl):
      return extensionDecl
    }
  }

  /// Names that matched lookup.
  @_spi(Experimental) public var names: [LookupName] {
    switch self {
    case .fromScope(_, let names), .fromFileScope(_, let names):
      return names
    case .lookInMembers(_):
      return []
    case .lookInGenericParametersOfExtendedType(_):
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

  /// Debug description of this lookup name.
  @_spi(Experimental) public var debugDescription: String {
    var description =
      resultKindDebugName + ": " + scope.scopeDebugDescription

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
        description += "`-" + name.debugDescription
      } else {
        description += "|-" + name.debugDescription + "\n"
      }
    }

    return description
  }

  /// Debug name of this result kind.
  private var resultKindDebugName: String {
    switch self {
    case .fromScope:
      return "fromScope"
    case .fromFileScope:
      return "fromFileScope"
    case .lookInMembers:
      return "lookInMembers"
    case .lookInGenericParametersOfExtendedType(_):
      return "lookInGenericParametersOfExtendedType"
    }
  }
}

@_spi(Experimental) extension [LookupResult] {
  /// Debug description this array of lookup results.
  @_spi(Experimental) public var debugDescription: String {
    return self.map(\.debugDescription).joined(separator: "\n")
  }
}
