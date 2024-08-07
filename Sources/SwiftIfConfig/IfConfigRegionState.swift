//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax

/// Describes the state of a particular region guarded by `#if` or similar.
public enum IfConfigRegionState {
  /// The region is not part of the compiled program and is not even parsed,
  /// and therefore many contain syntax that is invalid.
  case unparsed
  /// The region is parsed but is not part of the compiled program.
  case inactive
  /// The region is active and is part of the compiled program.
  case active

  /// Evaluate the given `#if` condition using the given build configuration
  /// to determine its state and identify any problems encountered along the
  /// way.
  public static func evaluating(
    _ condition: some ExprSyntaxProtocol,
    in configuration: some BuildConfiguration
  ) -> (state: IfConfigRegionState, diagnostics: [Diagnostic]) {
    // Apply operator folding for !/&&/||.
    var foldingDiagnostics: [Diagnostic] = []
    let foldedCondition = OperatorTable.logicalOperators.foldAll(condition) { error in
      foldingDiagnostics.append(contentsOf: error.asDiagnostics(at: condition))
    }.cast(ExprSyntax.self)

    let (active, versioned, evalDiagnostics) = evaluateIfConfig(
      condition: foldedCondition,
      configuration: configuration
    )

    let diagnostics = foldingDiagnostics + evalDiagnostics
    switch (active, versioned) {
    case (true, _): return (.active, diagnostics)
    case (false, false): return (.inactive, diagnostics)
    case (false, true): return (.unparsed, diagnostics)
    }
  }
}
