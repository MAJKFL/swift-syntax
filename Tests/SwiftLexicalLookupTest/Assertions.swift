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
import SwiftParser
import SwiftSyntax
import XCTest
import _SwiftSyntaxTestSupport

enum MarkerExpectation {
  case custom([String: SyntaxProtocol.Type])
  case all(SyntaxProtocol.Type, except: [String: SyntaxProtocol.Type] = [:])
  case none

  fileprivate func assertMarkerType(marker: String, actual: SyntaxProtocol) {
    switch self {
    case .all(let expectedType, except: let dictionary):
      assertMarkerType(marker: marker, actual: actual, expectedType: dictionary[marker] ?? expectedType)
    case .custom(let dictionary):
      if let expectedType = dictionary[marker] {
        assertMarkerType(marker: marker, actual: actual, expectedType: expectedType)
      } else {
        XCTFail("For result \(marker), could not find type expectation")
      }
    case .none:
      break
    }
  }

  private func assertMarkerType(marker: String, actual: SyntaxProtocol, expectedType: SyntaxProtocol.Type) {
    XCTAssert(
      actual.is(expectedType),
      "For result \(marker), expected type \(expectedType) doesn't match the actual type \(actual.syntaxNodeType)"
    )
  }
}

/// Parse `source` and check if the method passed as `methodUnderTest` produces the same results as indicated in `expected`.
///
/// The `methodUnderTest` provides test inputs taken from the `expected` dictionary. The closure should return result produced by the tested method as an array with the same ordering.
///
/// - Parameters:
///   - methodUnderTest: Closure with the tested method. Provides test argument from `expected` to the tested function. Should return method result as an array.
///   - expected: A dictionary with parameter markers as keys and expected results as marker arrays ordered as returned by the test method.
func assertLexicalScopeQuery(
  source: String,
  methodUnderTest: (SyntaxProtocol) -> ([SyntaxProtocol?]),
  expected: [String: [String?]],
  expectedResultTypes: MarkerExpectation = .none
) {
  // Extract markers
  let (markerDict, textWithoutMarkers) = extractMarkers(source)

  // Parse the test source
  var parser = Parser(textWithoutMarkers)
  let sourceFileSyntax = SourceFileSyntax.parse(from: &parser)

  // Iterate through the expected results
  for (marker, expectedMarkers) in expected {
    // Extract a test argument
    guard let position = markerDict[marker],
      let testArgument = sourceFileSyntax.token(at: AbsolutePosition(utf8Offset: position))
    else {
      XCTFail("Could not find token at location \(marker)")
      continue
    }

    // Execute the tested method
    let result = methodUnderTest(testArgument)

    // Extract the expected results for the test argument
    let expectedValues: [SyntaxProtocol?] = expectedMarkers.map { expectedMarker in
      guard let expectedMarker else { return nil }

      guard let expectedPosition = markerDict[expectedMarker],
        let expectedToken = sourceFileSyntax.token(at: AbsolutePosition(utf8Offset: expectedPosition))
      else {
        XCTFail("Could not find token at location \(marker)")
        return nil
      }

      return expectedToken
    }

    // Compare number of actual results to the number of expected results
    if result.count != expectedValues.count {
      XCTFail(
        "For marker \(marker), actual number of elements: \(result.count) doesn't match the expected: \(expectedValues.count)"
      )
    }

    // Assert validity of the output
    for (actual, expected) in zip(result, zip(expectedMarkers, expectedValues)) {
      if actual == nil && expected.1 == nil { continue }

      guard let actual else {
        XCTFail("For marker \(marker), actual is nil while expected is \(expected.1!)")
        continue
      }

      guard let expectedValue = expected.1 else {
        XCTFail("For marker \(marker), actual is \(actual) while expected is nil")
        continue
      }

      XCTAssert(
        actual.tokens(viewMode: .sourceAccurate).contains { $0.id == expectedValue.id },
        "For marker \(marker), actual result: \(actual) doesn't match expected value: \(expected)"
      )

      if let expectedMarker = expected.0 {
        expectedResultTypes.assertMarkerType(marker: expectedMarker, actual: actual)
      }
    }
  }
}

/// Parse `source` and check if the lexical name lookup matches results passed as `expected`.
///
/// - Parameters:
///   - expected: A dictionary of markers with reference location as keys and expected declarations as values.
func assertLexicalNameLookup(
  source: String,
  references: [String: [String]],
  expectedResultTypes: MarkerExpectation = .none
) {
  assertLexicalScopeQuery(
    source: source,
    methodUnderTest: { argument in
      // Extract reference name and use it for lookup
      guard let name = argument.firstToken(viewMode: .sourceAccurate)?.text else {
        XCTFail("Couldn't find a token at \(argument)")
        return []
      }
      return argument.lookup(for: name).map { lookUpResult in
        lookUpResult.syntax
      }
    },
    expected: references,
    expectedResultTypes: expectedResultTypes
  )
}
