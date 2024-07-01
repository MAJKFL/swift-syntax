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

extension SourceFileSyntax: ScopeSyntax {
  public var parentScope: ScopeSyntax? {
    nil
  }
  
  public func lookup(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    return nil
  }
}

extension FunctionDeclSyntax: ScopeSyntax {
  /// Parent of the function declaration.
  public var parentScope: ScopeSyntax? {
    getParent(for: self.parent)
  }
  
  var parameterScope: ScopeSyntax? {
    return signature.parameterClause.parameters
  }
  
  var lastGenericParameterScope: ScopeSyntax? {
    return genericParameterClause?.parameters.last
  }
  
  /// Checks type of the caller and proceeds with lookup accordingly.
  public func lookup(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    guard let caller else { return lookupAtParameterList(for: name, in: caller) }
    
    switch Syntax(caller).as(SyntaxEnum.self) {
    case .functionParameterList(let parameterList):
      return lookupAtLastGenericParameter(for: name, in: parameterList)
    case .genericParameter(let genericArgument):
      return lookupForGenericParameter(for: name, in: genericArgument)
    default:
      return lookupAtParameterList(for: name, in: caller)
    }
  }
  
  /// Starts lookup at the parameter list if it exists. Othwerise, tries to start lookup at the last generic parameter.
  private func lookupAtParameterList(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    if let parameterScope {
      return parameterScope.lookup(for: name, in: self)
    } else {
      return lookupAtLastGenericParameter(for: name, in: self)
    }
  }
  
  /// Starts lookup at the last generic parameter if it exists. Otherwise starts at the function name.
  private func lookupAtLastGenericParameter(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    if let lastGenericParameterScope {
      return lastGenericParameterScope.lookup(for: name, in: self)
    } else {
      return lookupAtFunctionName(for: name, in: self)
    }
  }
  
  /// Checks if caller is the first generic parameter and proceeds to lookup at function name accordingly. Otherwise, start lookup at the last generic parameter if it exists.
  private func lookupForGenericParameter(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    if let genericParamCaller = caller?.as(GenericParameterSyntax.self),
       let firstGenericParameterScope = genericParameterClause?.parameters.first,
       genericParamCaller.id == firstGenericParameterScope.id {
      return lookupAtFunctionName(for: name, in: self)
    } else {
      if let lastGenericParameterScope {
        return lastGenericParameterScope.lookup(for: name, in: self)
      } else {
        return lookupAtFunctionName(for: name, in: self)
      }
    }
  }
  
  /// Checks if function name matches the name in lookup. Otherwise, passes search to the parent.
  private func lookupAtFunctionName(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    if name == self.name.text { return self.name }
    return parentScope?.lookup(for: name, in: self)
  }
}

extension GenericParameterSyntax: ScopeSyntax {
  /// Generic parameter parent scope (GenericParameterSyntax or FunctionDeclSyntax)
  public var parentScope: ScopeSyntax? {
    guard let genericParameterList = self.parent?.as(GenericParameterListSyntax.self) else { return nil }

    var leftSibling: GenericParameterSyntax?
    for child in genericParameterList.children(viewMode: .sourceAccurate) {
      guard let parameter = child.as(GenericParameterSyntax.self) else { continue }
      if parameter.id == self.id {
        break
      }
      leftSibling = parameter
    }

    if let leftSibling {
      return leftSibling.scope
    } else {
      return genericParameterList.ancestorOrSelf(mapping: { $0 as? ScopeSyntax })
    }
  }
  
  /// Checks if generic parameter name matches the name in lookup. Otherwise, passes search to the parent.
  public func lookup(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    if self.name.text == name { return self.name }
    return parentScope?.lookup(for: name, in: self)
  }
}

extension FunctionParameterListSyntax: ScopeSyntax {
  /// Parameter list parent scope (FunctionDeclSyntax)
  public var parentScope: ScopeSyntax? {
    getParent(for: self.parent)
  }
  
  /// Parameters introduced by the parameter list.
  var parameters: [TokenSyntax] {
    self
      .children(viewMode: .sourceAccurate)
      .compactMap { syntax in
        guard let parameter = syntax.as(FunctionParameterSyntax.self) else { return nil }
        return parameter.secondName ?? parameter.firstName
      }
  }
  
  /// Checks if one of the parameters matches the name in lookup. Otherwise, passes search to the parent.
  public func lookup(for name: String, in caller: ScopeSyntax?) -> TokenSyntax? {
    if let token = parameters.first(where: { $0.text == name }) {
      return token
    } else {
      return parentScope?.lookup(for: name, in: self)
    }
  }
}
