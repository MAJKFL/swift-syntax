//
//  File.swift
//  
//
//  Created by Jakub Florek on 03/07/2024.
//

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
