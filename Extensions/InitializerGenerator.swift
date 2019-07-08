//
//  SourceEditorCommand.swift
//  Extensions
//
//  Created by 戚晓龙 on 2019/7/8.
//  Copyright © 2019 Aron. All rights reserved.
//

import Foundation
import XcodeKit

class InitializerGenerator: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        guard ["public.swift-source", "com.apple.dt.playground"].contains(invocation.buffer.contentUTI) else {
            completionHandler(ExtensionErrors.unsupportLanguage)
            return
        }
        guard let _ = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            completionHandler(ExtensionErrors.invalidSelection)
            return
        }
        
        let selections = invocation.buffer.selections
        let lines = invocation.buffer.lines
        let selectedLines = self.selectedLines(of: selections, in: lines as! [String])
        let variablePairs = self.variables(in: selectedLines)
        let combinedPairs = variablePairs.map { (name, type) -> String in
            return "\(name): \(type)"
        }
        let assignStatements = variablePairs.map { (name, _) -> String in
            return "\t\tself.\(name) = \(name)"
        }
        
        let indent = invocation.buffer.usesTabsForIndentation ? "\t" : String(repeating: " ", count: invocation.buffer.indentationWidth)
        var insertLines: [String] = []
        insertLines.append("\(indent)init(\(combinedPairs.joined(separator: ", "))) {")
        insertLines.append(contentsOf: assignStatements)
        insertLines.append("\(indent)}\n")
        
        if let lastSelectedRange = invocation.buffer.selections.lastObject as? XCSourceTextRange {
            let lineNumber = lastSelectedRange.end.line
            for (idx, line) in insertLines.enumerated() {
                invocation.buffer.lines.insert(line, at: idx + lineNumber + 1)
            }
        }
        completionHandler(nil)
    }
    
    private func selectedLines(of selections: NSArray, in lines: [String]) -> [String] {
        if let selectionRanges = selections as? [XCSourceTextRange] {
            var selectedLines: [String] = []
            for range in selectionRanges {
                let selectedRange = lines[range.start.line...range.end.line]
                selectedRange.forEach{selectedLines.append($0)}
            }
            return selectedLines
        }
        return []
    }
    
    private func variables(in lines: [String]) -> [(String, String)] {
        let fullString = lines.joined()
        let re = try! NSRegularExpression(pattern: "(\\s*((private|public|fileprivate|interval)\\s+)?(let|var))\\s+(?<name>\\w+)\\s?:\\s?(?<type>\\w+\\??)", options: [.caseInsensitive])
        var matched: [(String, String)] = []
       let matchingResults = re.matches(in: fullString, options: [.reportCompletion, .reportProgress], range: NSMakeRange(0, fullString.count))
        for match in matchingResults {
            let propertyNameRange = match.range(withName: "name")
            let propertyTypeRange = match.range(withName: "type")
            let propertyNameStartIndex = fullString.index(fullString.startIndex, offsetBy: propertyNameRange.lowerBound)
            let propertyNameEndIndex = fullString.index(fullString.startIndex, offsetBy: propertyNameRange.upperBound)
            let propertyTypeStartIndex = fullString.index(fullString.startIndex, offsetBy: propertyTypeRange.lowerBound)
            let propertyTypeEndIndex = fullString.index(fullString.startIndex, offsetBy: propertyTypeRange.upperBound)
            matched.append((String(fullString[propertyNameStartIndex..<propertyNameEndIndex]), String(fullString[propertyTypeStartIndex..<propertyTypeEndIndex])))
        }
        return matched
    }
}
