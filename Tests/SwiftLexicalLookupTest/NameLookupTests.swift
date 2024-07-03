//
//  File.swift
//  
//
//  Created by Jakub Florek on 03/07/2024.
//

import Foundation
@_spi(Testing) import SwiftLexicalLookup
import XCTest

final class testNameLookup: XCTestCase {
  func testCodeBlockSimpleCase() {
    assertLexicalNameLookup(source: """
    for i in 1..<4 {
      let 1️⃣a = i
      let 2️⃣b = 3️⃣a
    
      for j in 1..<4 {
        let 4️⃣c = 5️⃣a
        let 6️⃣a = j
    
        let d = 7️⃣a + 8️⃣b + 9️⃣c
      }
    }
    """, references: ["3️⃣" : ["1️⃣"], "5️⃣": ["1️⃣"], "7️⃣": ["6️⃣", "1️⃣"], "8️⃣": ["2️⃣"], "9️⃣": ["4️⃣"]])
  }
  
  func testLookupForComplexDeclarationsInCodeBlock() {
    assertLexicalNameLookup(source: """
    for i in 1..<4 {
      let (1️⃣a, 2️⃣b) = (1, 2)
      let 3️⃣c = 3, 4️⃣d = 4
    
      5️⃣a
      6️⃣b
      7️⃣c
      8️⃣d
    }
    """, references: ["5️⃣" : ["1️⃣"], "6️⃣": ["2️⃣"], "7️⃣": ["3️⃣"], "8️⃣": ["4️⃣"]])
  }
  
  func testLookupForLoop() {
    assertLexicalNameLookup(source: """
    for 1️⃣i in 1..<4 {
      let (a, b) = (2️⃣i, 3️⃣j)
      for (4️⃣i, 5️⃣j) in foo {
        let (c, d) = (6️⃣i, 7️⃣j)
      }
    }
    """, references: ["2️⃣" : ["1️⃣"], "3️⃣": [], "6️⃣": ["4️⃣", "1️⃣"], "7️⃣": ["5️⃣"]])
  }
  
  func testLookupForCaseLetLoop() {
    assertLexicalNameLookup(source: """
    for case let 1️⃣a as T in arr {
      2️⃣a.foo()
    }
    """, references: ["2️⃣" : ["1️⃣"]])
  }
}
