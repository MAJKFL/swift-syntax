//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

public struct MacroExpansion {
  let position: AbsolutePosition
  let file: SourceFileSyntax?
}

public class LookupMacroExpansions {
  private let expansions: [MacroExpansion]
  private var currentIndex: Int
  
  public init(expansions: [MacroExpansion]) {
    self.expansions = expansions.sorted(by: { $0.position < $1.position })
    self.currentIndex = expansions.count - 1
  }
  
  func getMacro(between range: ClosedRange<AbsolutePosition>) -> MacroExpansion? {
    for i in currentIndex...0 {
      if expansions[i].position < range.lowerBound {
        currentIndex = i
        return nil
      } else if range.contains(expansions[i].position) {
        currentIndex = i
        return expansions[i]
      }
    }
    
    return nil
  }
  
  func resetIndex() {
    currentIndex = expansions.count - 1
  }
}
