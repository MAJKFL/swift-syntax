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

extension SyntaxProtocol {
  public func lookup(for name: String) -> [LookupName] {
    scope?.lookup(for: name, at: self) ?? []
  }
}

public protocol ScopeSyntax: SyntaxProtocol {
  var parentScope: ScopeSyntax? { get }
  var introducedNames: [LookupName] { get }
  func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName]
}

extension ScopeSyntax {
  public var parentScope: ScopeSyntax? {
    getParent(for: self.parent)
  }

  func getParent(for syntax: Syntax?) -> ScopeSyntax? {
    guard let syntax else { return nil }

    if let lookedUpScope = syntax.scope, lookedUpScope.id != self.id {
      return lookedUpScope
    } else {
      return getParent(for: syntax.parent)
    }
  }

  func defaultLookupImplementation(
    for name: String,
    at syntax: SyntaxProtocol,
    positionSensitive: Bool = false
  ) -> [LookupName] {
    introducedNames
      .filter { introducedName in
        (!positionSensitive || introducedName.isBefore(syntax)) && introducedName.refersTo(name)
      } + (parentScope?.lookup(for: name, at: syntax) ?? [])
  }
}
