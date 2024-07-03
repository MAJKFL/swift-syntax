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
    default:
      self.parent?.scope
    }
  }
}

extension SourceFileSyntax: ScopeSyntax {
  public var parentScope: (ScopeSyntax)? {
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
  public var parentScope: (ScopeSyntax)? {
    getParent(for: self.parent)
  }
  
  public var introducedNames: [LookupName] {
    self.statements.flatMap { codeBlockItem in
      LookupName.getNames(from: codeBlockItem.item)
    }
  }
  
  public func lookup(for name: String, at syntax: SyntaxProtocol) -> [LookupName] {
    introducedNames
      .filter { introducedName in
        introducedName.isBefore(syntax) && introducedName.refersTo(name)
      } + (parentScope?.lookup(for: name, at: syntax) ?? [])
  }
}
