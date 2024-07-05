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
    case .optionalBindingCondition(let optionalBinding):
      getNames(from: optionalBinding.pattern)
    case .identifierPattern(let identifierPattern):
      handle(identifierPattern: identifierPattern)
    case .closureShorthandParameter(let closureShorthandParameter):
      handle(closureShorthandParameter: closureShorthandParameter)
    case .closureParameter(let closureParameter):
      handle(closureParameter: closureParameter)
    case .functionDecl(let functionDecl):
      handle(functionDecl: functionDecl)
    case .classDecl(let classDecl):
      handle(classDecl: classDecl)
    case .structDecl(let structDecl):
      handle(structDecl: structDecl)
    case .actorDecl(let actorDecl):
      handle(actorDecl: actorDecl)
    case .protocolDecl(let protocolDecl):
      handle(protocolDecl: protocolDecl)
    default:
      []
    }
  }

  private static func handle(identifierPattern: IdentifierPatternSyntax) -> [LookupName] {
    [.identifier(identifierPattern.identifier.text, identifierPattern)]
  }

  private static func handle(closureParameter: ClosureParameterSyntax) -> [LookupName] {
    [.identifier(closureParameter.secondName?.text ?? closureParameter.firstName.text, closureParameter)]
  }

  private static func handle(closureShorthandParameter: ClosureShorthandParameterSyntax) -> [LookupName] {
    let name = closureShorthandParameter.name.text
    if name != "_" {
      return [.identifier(name, closureShorthandParameter)]
    } else {
      return []
    }
  }
  
  private static func handle(functionDecl: FunctionDeclSyntax) -> [LookupName] {
    [.constructName(functionDecl.name.text, functionDecl)]
  }
  
  private static func handle(classDecl: ClassDeclSyntax) -> [LookupName] {
    [.constructName(classDecl.name.text, classDecl)]
  }
  
  private static func handle(structDecl: StructDeclSyntax) -> [LookupName] {
    [.constructName(structDecl.name.text, structDecl)]
  }
  
  private static func handle(actorDecl: ActorDeclSyntax) -> [LookupName] {
    [.constructName(actorDecl.name.text, actorDecl)]
  }
  
  private static func handle(protocolDecl: ProtocolDeclSyntax) -> [LookupName] {
    [.constructName(protocolDecl.name.text, protocolDecl)]
  }
}
