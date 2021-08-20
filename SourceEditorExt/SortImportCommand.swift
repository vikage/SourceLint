//
//  SortImportCommand.swift
//  SourceEditorExt
//
//  Created by Thanh Vu on 20/08/2021.
//

import Foundation
import XcodeKit

struct SortImportProcessResult {
    var systemFrameWorkImports: [String]
    var ribsInterfaceImports: [String]
    var normalFrameWorkImports: [String]
}

class SortImportCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        let sourceLines = invocation.buffer.lines
        sort(sourceLines: sourceLines)
        completionHandler(nil)
    }

    func getImportRange(lines: NSMutableArray) -> NSRange {
        var firstImportIndex: Int?
        var lastImportIndex: Int?
        for index in 0..<lines.count {
            let line = lines[index]

            if let lineStr = line as? String {
                if lineStr.trimSourceLine().hasPrefix("import ") {
                    if firstImportIndex == nil {
                        firstImportIndex = index
                    }

                    lastImportIndex = index
                    continue
                }

                if lineStr.trimSourceLine() == "" {
                    continue
                }

                if firstImportIndex != nil {
                    break
                }
            }
        }

        if firstImportIndex != nil {
            return NSRange.init(location: firstImportIndex!, length: lastImportIndex! - firstImportIndex! + 1)
        }

        return NSRange.init(location: 0, length: 0)
    }

    private func processImportLines(lines: [String]) -> SortImportProcessResult {
        let systemFrameworks = ["UIKit", "Foundation", "CoreGraphic", "MetalKit", "AVKit", "ARKit"]
        var systemFrameWorkImports = [String]()
        var ribsInterfaceImports = [String]()
        var normalFrameWorkImports = [String]()

        lines.forEach { importLine in
            var isImportFramework = false
            systemFrameworks.forEach { systemFrameworkName in
                if importLine.contains(systemFrameworkName) {
                    isImportFramework = true
                }
            }

            if isImportFramework {
                systemFrameWorkImports.append(importLine)
            } else if importLine.trimSourceLine().hasSuffix("Interfaces") {
                ribsInterfaceImports.append(importLine)
            } else {
                normalFrameWorkImports.append(importLine)
            }
        }

        systemFrameWorkImports.sort()
        ribsInterfaceImports.sort()
        normalFrameWorkImports.sort()

        return SortImportProcessResult(systemFrameWorkImports: systemFrameWorkImports, ribsInterfaceImports: ribsInterfaceImports, normalFrameWorkImports: normalFrameWorkImports)
    }

    private func getImportLineFrom(range: NSRange, sourceLines: NSMutableArray) -> [String] {
        let importLines = sourceLines.subarray(with: range)
        var importLinesString = [String]()

        importLines.forEach { line in
            if let lineString = line as? String, lineString.trimSourceLine() != "" {
                importLinesString.append(lineString.trimSourceLine())
            }
        }

        return importLinesString
    }

    func insertNewImportLines(processResult: SortImportProcessResult, sourceLines: NSMutableArray, firstImportIndex: Int) {
        var insertIndex: Int = firstImportIndex
        processResult.systemFrameWorkImports.forEach { importLine in
            sourceLines.insert(importLine, at: insertIndex)
            insertIndex += 1
        }

        if !processResult.systemFrameWorkImports.isEmpty && (!processResult.normalFrameWorkImports.isEmpty || !processResult.ribsInterfaceImports.isEmpty) {
            sourceLines.insert("", at: insertIndex)
            insertIndex += 1
        }

        processResult.normalFrameWorkImports.forEach { importLine in
            sourceLines.insert(importLine.trimSourceLine(), at: insertIndex)
            insertIndex += 1
        }

        if !processResult.ribsInterfaceImports.isEmpty {
            sourceLines.insert("", at: insertIndex)
            insertIndex += 1
        }

        processResult.ribsInterfaceImports.forEach { importLine in
            sourceLines.insert(importLine, at: insertIndex)
            insertIndex += 1
        }
    }

    func sort(sourceLines: NSMutableArray) {
        let importRange = self.getImportRange(lines: sourceLines)

        if importRange.length == 0 {
            return
        }

        let importLines = self.getImportLineFrom(range: importRange, sourceLines: sourceLines)
        sourceLines.removeObjects(in: importRange)

        let processResult = processImportLines(lines: importLines)
        insertNewImportLines(processResult: processResult, sourceLines: sourceLines, firstImportIndex: importRange.location)
    }
}
