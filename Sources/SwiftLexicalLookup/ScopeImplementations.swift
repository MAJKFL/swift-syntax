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
    case .whileStmt(let whileStmt):
      whileStmt
    case .ifExpr(let ifExpr):
      ifExpr
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
    defaultLookupImplementation(for: name, at: syntax)
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

  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    defaultLookupImplementation(for: name, at: syntax)
  }
}

extension WhileStmtSyntax: ScopeSyntax {
  public var introducedNames: [LookupName] {
    conditions.flatMap { element in
      LookupName.getNames(from: element.condition)
    }
  }
  
  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    defaultLookupImplementation(for: name, at: syntax)
  }
}

extension IfExprSyntax: ScopeSyntax {
  public var parentScope: ScopeSyntax? {
    getParent(for: self.parent, previousIfExpr: self)
  }
  
  private func getParent(for syntax: Syntax?, previousIfExpr: IfExprSyntax) -> ScopeSyntax? {
    guard let syntax else { return nil }

    if let lookedUpScope = syntax.scope, lookedUpScope.id != self.id {
      if let currentIfExpr = lookedUpScope.as(IfExprSyntax.self), previousIfExpr.elseKeyword != nil {
        return getParent(for: syntax.parent, previousIfExpr: currentIfExpr)
      } else {
        return lookedUpScope
      }
    } else {
      return getParent(for: syntax.parent, previousIfExpr: previousIfExpr)
    }
  }
  
  public var introducedNames: [LookupName] {
    conditions.flatMap { element in
      LookupName.getNames(from: element.condition)
    }
  }
  
  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    if let elseBody, elseBody.position <= syntax.position, elseBody.endPosition >= syntax.position {
      parentScope?.lookup(for: name, at: syntax) ?? []
    } else {
      defaultLookupImplementation(for: name, at: syntax, positionSensitive: true)
    }
  }
}
