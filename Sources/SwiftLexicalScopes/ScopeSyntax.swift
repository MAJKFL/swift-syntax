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
  public var scope: ScopeSyntax? {
    switch Syntax(self).as(SyntaxEnum.self) {
    case .sourceFile(let sourceFile):
      sourceFile
    case .functionDecl(let functionDecl):
      functionDecl
    case .genericParameter(let genericParameter):
      genericParameter
    case .functionParameterList(let parameterList):
      parameterList
    default:
      self.parent?.scope
    }
  }
}

public protocol ScopeSyntax: SyntaxProtocol {
  var parentScope: (ScopeSyntax)? { get }
  func lookup(for name: String, in caller: ScopeSyntax?) -> TokenSyntax?
}

extension ScopeSyntax {
  func getParent(for syntax: Syntax?) -> ScopeSyntax? {
    guard let syntax else { return nil }
    
    if let lookedUpScope = syntax.scope, lookedUpScope.id != self.id {
      return lookedUpScope
    } else {
      return getParent(for: syntax.parent)
    }
  }
  
  public func lookup(_ name: String) -> TokenSyntax? {
    guard let scope else { return nil }
    return scope.lookup(for: name, in: self)
  }
}
