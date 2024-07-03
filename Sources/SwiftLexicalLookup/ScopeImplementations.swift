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
  public var scope: ScopeSyntax? {
    switch Syntax(self).as(SyntaxEnum.self) {
    case .sourceFile(let sourceFile):
      sourceFile
    case .codeBlock(let codeBlock):
      codeBlock
    case .forStmt(let forStmt):
      forStmt
    case .closureExpr(let closureExpr):
      closureExpr
    default:
      self.parent?.scope
    }
  }
}

extension SourceFileSyntax: ScopeSyntax {
  public var parentScope: ScopeSyntax? {
    nil
  }

  public var introducedNames: [LookupName] {
    []
  }

  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    []
  }
}

extension CodeBlockSyntax: ScopeSyntax {
  public var introducedNames: [LookupName] {
    statements.flatMap { codeBlockItem in
      LookupName.getNames(from: codeBlockItem.item)
    }
  }

  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    defaultLookupImplementation(for: name, at: syntax, positionSensitive: true)
  }
}

extension ForStmtSyntax: ScopeSyntax {
  public var introducedNames: [LookupName] {
    LookupName.getNames(from: pattern)
  }

  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    defaultLookupImplementation(for: name, at: syntax, positionSensitive: false)
  }
}

extension ClosureExprSyntax: ScopeSyntax {
  public var introducedNames: [LookupName] {
    signature?.parameterClause?.children(viewMode: .sourceAccurate).flatMap { parameter in
      if let parameterList = parameter.as(ClosureParameterListSyntax.self) {
        parameterList.children(viewMode: .sourceAccurate).flatMap { parameter in
          LookupName.getNames(from: parameter)
        }
      } else {
        LookupName.getNames(from: parameter)
      }
    } ?? []
  }

  public func lookup(for name: String, at syntax: SwiftSyntax.SyntaxProtocol) -> [LookupName] {
    defaultLookupImplementation(for: name, at: syntax, positionSensitive: false)
  }
}
