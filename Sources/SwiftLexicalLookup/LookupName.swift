//
//  File.swift
//  
//
//  Created by Jakub Florek on 03/07/2024.
//

import SwiftSyntax

public enum LookupName {
  case identifier(String, SyntaxProtocol)
  case constructName(String, SyntaxProtocol)
  
  public var syntax: SyntaxProtocol {
    switch self {
    case .identifier(_, let syntax):
      syntax
    case .constructName(_, let syntax):
      syntax
    }
  }
  
  public var name: String {
    switch self {
    case .identifier(let name, _):
      name
    case .constructName(let name, _):
      name
    }
  }
  
  func isBefore(_ lookedUpSyntax: SyntaxProtocol) -> Bool {
    return syntax.position < lookedUpSyntax.position
  }
  
  func refersTo(_ lookedUpName: String) -> Bool {
    return name == lookedUpName
  }
  
  static func getNames(from syntax: SyntaxProtocol) -> [LookupName] {
    switch Syntax(syntax).as(SyntaxEnum.self) {
    case .variableDecl(let variableDecl):
      variableDecl.bindings.flatMap { binding in
        if let identifierPattern = IdentifierPatternSyntax(binding.pattern) {
          return handle(identifierPattern: identifierPattern)
        } else if let tuplePattern = TuplePatternSyntax(binding.pattern) {
          return handle(tuplePattern: tuplePattern)
        } else {
          return []
        }
      }
    default:
      []
    }
  }
  
  private static func handle(identifierPattern: IdentifierPatternSyntax) -> [LookupName] {
    return [LookupName.identifier(identifierPattern.identifier.text, identifierPattern)]
  }
  
  private static func handle(tuplePattern: TuplePatternSyntax) -> [LookupName] {
    return tuplePattern.elements.compactMap { tupleElement in
      if let identifierPattern = IdentifierPatternSyntax(tupleElement.pattern) {
        return LookupName.identifier(identifierPattern.identifier.text, identifierPattern)
      } else {
        return nil
      }
    }
  }
}
