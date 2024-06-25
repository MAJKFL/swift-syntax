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

final class FileScope: Scope {
  var parent: (any Scope)? = nil

  var sourceSyntax: SourceFileSyntax

  required init(sourceSyntax: SourceFileSyntax) {
    self.sourceSyntax = sourceSyntax
  }

  func getDeclarationFor(name: String, at syntax: SyntaxProtocol) -> TokenSyntax? {
    // TODO: Implement the method
    return nil
  }
}

final class FunctionDeclScope: Scope {
  var sourceSyntax: FunctionDeclSyntax

  required init(sourceSyntax: FunctionDeclSyntax) {
    self.sourceSyntax = sourceSyntax
  }

  var introducesToParent: [TokenSyntax] {
    [sourceSyntax.name]
  }

  func getDeclarationFor(name: String, at syntax: SyntaxProtocol) -> TokenSyntax? {
    if name == sourceSyntax.name.text {
      sourceSyntax.name
    } else {
      parent?.getDeclarationFor(name: name, at: sourceSyntax)
    }
  }
}

final class GenericParameterScope: Scope {
  var parent: (any Scope)? {
    guard let genericParameterList = sourceSyntax.parent?.as(GenericParameterListSyntax.self) else { return nil }

    var leftSibling: GenericParameterSyntax?
    for child in genericParameterList.children(viewMode: .sourceAccurate) {
      guard let parameter = child.as(GenericParameterSyntax.self) else { continue }
      if parameter.id == sourceSyntax.id {
        break
      }
      leftSibling = parameter
    }

    if let leftSibling {
      return leftSibling.scope
    } else {
      return genericParameterList.parent?.parent?.outermostScope
    }
  }

  var sourceSyntax: GenericParameterSyntax

  required init(sourceSyntax: GenericParameterSyntax) {
    self.sourceSyntax = sourceSyntax
  }

  var introducedGenericName: TokenSyntax {
    sourceSyntax.name
  }

  func getDeclarationFor(name: String, at syntax: SyntaxProtocol) -> TokenSyntax? {
    if introducedGenericName.text == name {
      introducedGenericName
    } else {
      parent?.getDeclarationFor(name: name, at: syntax)
    }
  }
}

final class ParameterListScope: Scope {
  var sourceSyntax: FunctionParameterListSyntax

  required init(sourceSyntax: FunctionParameterListSyntax) {
    self.sourceSyntax = sourceSyntax
  }

  var parameters: [TokenSyntax] {
    sourceSyntax
      .children(viewMode: .sourceAccurate)
      .compactMap { syntax in
        guard let parameter = syntax.as(FunctionParameterSyntax.self) else { return nil }
        return parameter.secondName ?? parameter.firstName
      }
  }

  var introducesToParent: [TokenSyntax] {
    parameters
  }

  func getDeclarationFor(name: String, at syntax: SyntaxProtocol) -> TokenSyntax? {
    if let token = parameters.first(where: { $0.text == name }) {
      return token
    } else {
      return parent?.getDeclarationFor(name: name, at: syntax)
    }
  }
}

final class FunctionBodyScope: Scope {
  var parent: (any Scope)? {
    sourceSyntax.genericParameterClause?.parameters.last?.scope ?? sourceSyntax.outermostScope
  }

  var sourceSyntax: FunctionDeclSyntax

  required init(sourceSyntax: FunctionDeclSyntax) {
    self.sourceSyntax = sourceSyntax
  }

  func getDeclarationFor(name: String, at syntax: SyntaxProtocol) -> TokenSyntax? {
    if let token = sourceSyntax.signature.parameterClause.parameters.scope?.introducesToParent.first(where: {
      $0.text == name
    }) {
      token
    } else {
      parent?.getDeclarationFor(name: name, at: syntax)
    }
  }
}
