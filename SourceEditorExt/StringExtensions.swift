//
//  StringExtensions.swift
//  SourceEditorExt
//
//  Created by Thanh Vu on 20/08/2021.
//

import Foundation

extension String {
    func trimSourceLine() -> String {
        let result = NSMutableString.init(string: self)
        let regexReplaceMultiSpace = try! NSRegularExpression(pattern: "[\\ ]+", options: [])
        regexReplaceMultiSpace.replaceMatches(in: result, options: .reportCompletion, range: NSRange.init(location: 0, length: result.length), withTemplate: " ")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
