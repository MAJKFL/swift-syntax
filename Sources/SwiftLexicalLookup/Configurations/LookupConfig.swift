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

@_spi(Experimental) public struct LookupConfig {
  /// Specifies behavior of file scope.
  @_spi(Experimental) public var fileScopeHandling: FileScopeHandlingConfig
  @_spi(Experimental) public var finishInBraceStatement: Bool
  @_spi(Experimental) public var includeMembers: Bool

  /// Creates a new lookup configuration.
  ///
  /// - `fileScopeHandling` - specifies behavior of file scope.
  ///   `memberBlockUpToLastDecl` by default.
  @_spi(Experimental) public init(
    fileScopeHandling: FileScopeHandlingConfig = .memberBlockUpToLastDecl,
    finishInBraceStatement: Bool = false,
    includeMembers: Bool = true
  ) {
    self.fileScopeHandling = fileScopeHandling
    self.finishInBraceStatement = finishInBraceStatement
    self.includeMembers = includeMembers
  }
}
