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

import Foundation
import SwiftSyntax

extension SyntaxProtocol {
  var outermostScope: (any Scope)? {
    outerScope ?? scope
  }

  private var outerScope: (any Scope)? {
    switch self.syntaxNodeType {
    case is FunctionDeclSyntax.Type:
      FunctionDeclScope(sourceSyntax: self.as(FunctionDeclSyntax.self)!)
    default:
      nil
    }
  }

  /// Scope at the syntax node. Could be inherited from parent or introduced at the node.
  var scope: (any Scope)? {
    switch self.syntaxNodeType {
    case is SourceFileSyntax.Type:
      FileScope(sourceSyntax: self.as(SourceFileSyntax.self)!)
    case is FunctionDeclSyntax.Type:
      FunctionBodyScope(sourceSyntax: self.as(FunctionDeclSyntax.self)!)
    case is FunctionParameterListSyntax.Type:
      ParameterListScope(sourceSyntax: self.as(FunctionParameterListSyntax.self)!)
    case is GenericParameterSyntax.Type:
      GenericParameterScope(sourceSyntax: self.as(GenericParameterSyntax.self)!)
    default:
      parent?.scope
    }
  }
}

/// Provide common functionality for specialized scope implementatations.
protocol Scope {
  associatedtype SourceSyntaxType: SyntaxProtocol
    
  var parent: (any Scope)? { get }

  var sourceSyntax: SourceSyntaxType { get }
    
  init(sourceSyntax: SourceSyntaxType)

  var introducesToParent: [TokenSyntax] { get }

  func getDeclarationFor(name: String, at syntax: SyntaxProtocol) -> TokenSyntax?
}

extension Scope {
  /// Recursively walks up syntax tree and finds the closest scope other than this scope.
  func getParentScope(forSyntax syntax: SyntaxProtocol?) -> Scope? {
    if let lookedUpScope = syntax?.scope, lookedUpScope.sourceSyntax.id == syntax?.id {
      return getParentScope(forSyntax: sourceSyntax.parent)
    } else {
      return syntax?.scope
    }
  }

  // MARK: - lookupLabeledStmts

  /// Given syntax node position, returns all available labeled statements.
  func lookupLabeledStmts(at syntax: SyntaxProtocol) -> [LabeledStmtSyntax] {
    return lookupLabeledStmtsHelper(at: syntax.parent)
  }

  /// Helper method to recursively collect labeled statements from the syntax node's parents.
  private func lookupLabeledStmtsHelper(at syntax: Syntax?) -> [LabeledStmtSyntax] {
    guard let syntax, !syntax.is(MemberBlockSyntax.self) else { return [] }
    if let labeledStmtSyntax = syntax.as(LabeledStmtSyntax.self) {
      return [labeledStmtSyntax] + lookupLabeledStmtsHelper(at: labeledStmtSyntax.parent)
    } else {
      return lookupLabeledStmtsHelper(at: syntax.parent)
    }
  }

  // MARK: - lookupFallthroughSourceAndDest

  /// Given syntax node position, returns the current switch case and it's fallthrough destination.
  func lookupFallthroughSourceAndDestination(at syntax: SyntaxProtocol) -> (SwitchCaseSyntax?, SwitchCaseSyntax?) {
    guard let originalSwitchCase = syntax.ancestorOrSelf(mapping: { $0.as(SwitchCaseSyntax.self) }) else {
      return (nil, nil)
    }

    let nextSwitchCase = lookupNextSwitchCase(at: originalSwitchCase)

    return (originalSwitchCase, nextSwitchCase)
  }

  /// Given a switch case, returns the case that follows according to the parent.
  private func lookupNextSwitchCase(at switchCaseSyntax: SwitchCaseSyntax) -> SwitchCaseSyntax? {
    guard let switchCaseListSyntax = switchCaseSyntax.parent?.as(SwitchCaseListSyntax.self) else { return nil }

    var visitedOriginalCase = false

    for child in switchCaseListSyntax.children(viewMode: .sourceAccurate) {
      if let thisCase = child.as(SwitchCaseSyntax.self) {
        if thisCase.id == switchCaseSyntax.id {
          visitedOriginalCase = true
        } else if visitedOriginalCase {
          return thisCase
        }
      }
    }

    return nil
  }

  // MARK: - lookupCatchNode

  /// Given syntax node position, returns the closest ancestor catch node.
  func lookupCatchNode(at syntax: Syntax) -> Syntax? {
    return lookupCatchNodeHelper(at: syntax, traversedCatchClause: false)
  }

  /// Given syntax node location, finds where an error could be caught. If set to `true`, `traverseCatchClause`lookup will skip the next do statement.
  private func lookupCatchNodeHelper(at syntax: Syntax?, traversedCatchClause: Bool) -> Syntax? {
    guard let syntax else { return nil }

    switch syntax.as(SyntaxEnum.self) {
    case .doStmt:
      if traversedCatchClause {
        return lookupCatchNodeHelper(at: syntax.parent, traversedCatchClause: false)
      } else {
        return syntax
      }
    case .catchClause:
      return lookupCatchNodeHelper(at: syntax.parent, traversedCatchClause: true)
    case .tryExpr(let tryExpr):
      if tryExpr.questionOrExclamationMark != nil {
        return syntax
      } else {
        return lookupCatchNodeHelper(at: syntax.parent, traversedCatchClause: traversedCatchClause)
      }
    case .functionDecl(let functionDecl):
      if functionDecl.signature.effectSpecifiers?.throwsClause != nil {
        return syntax
      } else {
        return lookupCatchNodeHelper(at: syntax.parent, traversedCatchClause: traversedCatchClause)
      }
    default:
      return lookupCatchNodeHelper(at: syntax.parent, traversedCatchClause: traversedCatchClause)
    }
  }
}
