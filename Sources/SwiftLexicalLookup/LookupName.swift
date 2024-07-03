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
    syntax.position < lookedUpSyntax.position
  }
  
  func refersTo(_ lookedUpName: String) -> Bool {
    name == lookedUpName
  }
  
  static func getNames(from syntax: SyntaxProtocol) -> [LookupName] {
    switch Syntax(syntax).as(SyntaxEnum.self) {
    case .variableDecl(let variableDecl):
      variableDecl.bindings.flatMap { binding in
        getNames(from: binding.pattern)
      }
    case .tuplePattern(let tuplePattern):
      tuplePattern.elements.flatMap { tupleElement in
        getNames(from: tupleElement.pattern)
      }
    case .valueBindingPattern(let valueBindingPattern):
      getNames(from: valueBindingPattern.pattern)
    case .expressionPattern(let expressionPattern):
      getNames(from: expressionPattern.expression)
    case .sequenceExpr(let sequenceExpr):
      sequenceExpr.elements.flatMap { expression in
        getNames(from: expression)
      }
    case .patternExpr(let patternExpr):
      getNames(from: patternExpr.pattern)
    case .identifierPattern(let identifierPattern):
      handle(identifierPattern: identifierPattern)
    default:
      []
    }
  }
  
  private static func handle(identifierPattern: IdentifierPatternSyntax) -> [LookupName] {
    [.identifier(identifierPattern.identifier.text, identifierPattern)]
  }
}
