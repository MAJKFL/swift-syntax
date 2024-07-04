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
@_spi(Testing) import SwiftLexicalLookup
import SwiftSyntax
import XCTest

final class testNameLookup: XCTestCase {
  func testCodeBlockSimpleCase() {
    assertLexicalNameLookup(
      source: """
        for i in 1..<4 {
          let 1️⃣a = i
          let 2️⃣b = 3️⃣a

          for j in 1..<4 {
            let 4️⃣c = 5️⃣a
            let 6️⃣a = j

            let d = 7️⃣a + 8️⃣b + 9️⃣c
          }
        }
        """,
      references: ["3️⃣": ["1️⃣"], "5️⃣": ["1️⃣"], "7️⃣": ["6️⃣", "1️⃣"], "8️⃣": ["2️⃣"], "9️⃣": ["4️⃣"]],
      expectedResultTypes: .all(IdentifierPatternSyntax.self)
    )
  }

  func testLookupForComplexDeclarationsInCodeBlock() {
    assertLexicalNameLookup(
      source: """
        for i in 1..<4 {
          let (1️⃣a, 2️⃣b) = (1, 2)
          let 3️⃣c = 3, 4️⃣d = 4

          5️⃣a
          6️⃣b
          7️⃣c
          8️⃣d
        }
        """,
      references: ["5️⃣": ["1️⃣"], "6️⃣": ["2️⃣"], "7️⃣": ["3️⃣"], "8️⃣": ["4️⃣"]],
      expectedResultTypes: .all(IdentifierPatternSyntax.self)
    )
  }

  func testLookupForLoop() {
    assertLexicalNameLookup(
      source: """
        for 1️⃣i in 1..<4 {
          let (a, b) = (2️⃣i, 3️⃣j)
          for (4️⃣i, 5️⃣j) in foo {
            let (c, d) = (6️⃣i, 7️⃣j)
          }
        }
        """,
      references: ["2️⃣": ["1️⃣"], "3️⃣": [], "6️⃣": ["4️⃣", "1️⃣"], "7️⃣": ["5️⃣"]],
      expectedResultTypes: .all(IdentifierPatternSyntax.self)
    )
  }

  func testLookupForCaseLetLoop() {
    assertLexicalNameLookup(
      source: """
        for case let 1️⃣a as T in arr {
          2️⃣a.foo()
        }
        """,
      references: ["2️⃣": ["1️⃣"]],
      expectedResultTypes: .all(IdentifierPatternSyntax.self)
    )
  }

  func testShorthandParameterLookupClosure() {
    assertLexicalNameLookup(
      source: """
        func foo() {
          let 1️⃣a = 1
          let 2️⃣b = 2
          let 3️⃣x: (Int, Int, Int) = { 4️⃣a, _, 5️⃣c in
            print(6️⃣a, 7️⃣b, 8️⃣c, 0️⃣$0)
          }
          9️⃣x()
        }
        """,
      references: ["6️⃣": ["4️⃣", "1️⃣"], "7️⃣": ["2️⃣"], "8️⃣": ["5️⃣"], "9️⃣": ["3️⃣"], "0️⃣": []],
      expectedResultTypes: .all(
        IdentifierPatternSyntax.self,
        except: [
          "4️⃣": ClosureShorthandParameterSyntax.self,
          "5️⃣": ClosureShorthandParameterSyntax.self,
        ]
      )
    )
  }

  func testParameterLookupClosure() {
    assertLexicalNameLookup(
      source: """
        func foo() {
          let 1️⃣a = 1
          let 2️⃣b = 2
          let 3️⃣x = { (a 4️⃣b: Int, 5️⃣c: Int) in
              print(6️⃣a, 7️⃣b, 8️⃣c, 0️⃣$0)
          }
          9️⃣x()
        }
        """,
      references: ["6️⃣": ["1️⃣"], "7️⃣": ["4️⃣", "2️⃣"], "8️⃣": ["5️⃣"], "9️⃣": ["3️⃣"], "0️⃣": []],
      expectedResultTypes: .all(
        IdentifierPatternSyntax.self,
        except: [
          "4️⃣": ClosureParameterSyntax.self,
          "5️⃣": ClosureParameterSyntax.self,
        ]
      )
    )
  }
  
  func testWhileOptionalBindingLookup() {
    assertLexicalNameLookup(
      source: """
        func foo() {
          let 1️⃣b = x
          while let 2️⃣a = 3️⃣b {
            let 4️⃣b = x
            print(5️⃣a, 6️⃣b)
          }
        }
        """,
      references: ["3️⃣": ["1️⃣"], "5️⃣":["2️⃣"], "6️⃣":["4️⃣", "1️⃣"]],
      expectedResultTypes: .all(
        IdentifierPatternSyntax.self
      )
    )
  }
  
  func testIfLetOptionalBindingSimpleCaseWithPrecedence() {
    assertLexicalNameLookup(
      source: """
        if let 1️⃣a = 2️⃣b, let 3️⃣b = 4️⃣a {
          print(5️⃣a, 6️⃣b)
        } else {
          print(7️⃣a, 8️⃣b)
        }
        """,
      references: ["2️⃣": [], "4️⃣":["1️⃣"], "5️⃣":["1️⃣"], "6️⃣":["3️⃣"], "7️⃣":[], "8️⃣":[]],
      expectedResultTypes: .all(
        IdentifierPatternSyntax.self
      )
    )
  }
  
  func testIfLetWithElseIfAndNesting() {
    assertLexicalNameLookup(
      source: """
        if let 1️⃣a = x {
          if let 2️⃣a = x {
            print(3️⃣a)
          } else if let 4️⃣a = x {
            print(5️⃣a)
          } else {
            print(6️⃣a)
          }
          print(7️⃣a)
        } else if let 8️⃣a = x {
          print(9️⃣a)
        } else {
          print(0️⃣a)
        }
        """,
      references: ["3️⃣": ["2️⃣", "1️⃣"], "5️⃣":["4️⃣", "1️⃣"], "6️⃣":["1️⃣"], "7️⃣":["1️⃣"], "9️⃣":["8️⃣"], "0️⃣":[]],
      expectedResultTypes: .all(
        IdentifierPatternSyntax.self
      )
    )
  }
}
