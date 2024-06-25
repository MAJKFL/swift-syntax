//
//  File.swift
//
//
//  Created by Jakub Florek on 23/06/2024.
//

import Foundation
import XCTest

final class NameLookupTests: XCTestCase {
  func testFunctionParameterLookup() {
    assertLexicalNameLookup(
      source: """
        func foo(1️⃣a: Int, b 2️⃣c: Int) {
          let x1 = 3️⃣a
          let x2 = 4️⃣c
          let x = 5️⃣b
        }
        """,
      references: ["3️⃣": "1️⃣", "4️⃣": "2️⃣", "5️⃣": nil]
    )
  }

  func testFunctionParameterShadowingLookup() {
    assertLexicalNameLookup(
      source: """
        func foo(a: Int, 1️⃣b: Int) {
            func 6️⃣bar(2️⃣a: Int) {
              let x1 = 3️⃣a
              let x2 = 4️⃣b
              5️⃣bar()
            }
        }
        """,
      references: ["3️⃣": "2️⃣", "4️⃣": "1️⃣", "5️⃣": "6️⃣"]
    )
  }

  func testFunctionGenericParameterLookup() {
    assertLexicalNameLookup(
      source: """
        func foo<1️⃣T1: 8️⃣T3, 7️⃣T2: 5️⃣T1, T3>(a: 2️⃣T1) {
          let x1: 3️⃣T1 = a
          let x2: 6️⃣T2 = a
          let x: 4️⃣T = a
        }
        """,
      references: ["2️⃣": "1️⃣", "3️⃣": "1️⃣", "4️⃣": nil, "5️⃣": "1️⃣", "6️⃣": "7️⃣", "8️⃣":nil]
    )
  }
}
