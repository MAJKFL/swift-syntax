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
}
