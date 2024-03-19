// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation
import SwiftFormat

@main
struct SwiftFormatLinter: ParsableCommand  {
    enum Error: LocalizedError {
        case canNotGetFilesOfXcodeProject
        case swiftFormatConfigurationFileMissing
        case swiftFormatIgnoreFileMissing
        case hasLintingWarnings(String)
        
        var errorDescription: String? {
            switch self {
            case .canNotGetFilesOfXcodeProject:
                return "Can not find the xcode project"
            case .swiftFormatConfigurationFileMissing:
                return "Can not found the .swift-format configuration file"
            case .swiftFormatIgnoreFileMissing:
                return "Can not found the .swift-format-ignore file"
            case .hasLintingWarnings(let string):
                return "Xcode project has some warnings: \n\(string)"
            }
        }
    }
    
    @Argument(help: "xcode project directory path")
    var projectPath: String
    
    @Argument(help: "swift-format-ignore file")
    var ignoreFilePath: String?
    
    
    @Flag(help: "verbose")
    var verbose: Bool = false
    
    mutating func run() throws {
        if self.ignoreFilePath == nil {
            self.ignoreFilePath = SearchFile.search(name: "swift-format-ignore", at: projectPath).first
            self.ignoreFilePath = URL(fileURLWithPath: projectPath).appendingPathComponent(self.ignoreFilePath!).relativePath
        }
        guard let ignoreFilePath else {
            throw Error.swiftFormatIgnoreFileMissing
        }
        verbosePrint("Ignore file path: ", ignoreFilePath)
        verbosePrint("Xcode project path: ", projectPath)
        
        let ignoreFileContent = try String(contentsOfFile: ignoreFilePath)
        let ignorePaths = ignoreFileContent.split(separator: "\n").map { String($0).trimmingCharacters(in: CharacterSet(["/"])) }
        
        verbosePrint(ignorePaths)
        
        
        let swiftFiles = try validSwiftFilePaths(at: projectPath, ignorePaths: ignorePaths)
        print("-----------------------")
        var findings: [Finding] = []
        for file in swiftFiles.files {
            let lintFindings = try lint(path: file, configuration: swiftFiles.configuration)
            findings.append(contentsOf: lintFindings)
        }
        if !findings.isEmpty {
            print("Warnings: \(findings.count)")
            throw Error.hasLintingWarnings("\(findings.count)")
        } else {
            print("✅ All Good!")
        }
    }
    
    struct Files {
        var configuration: URL
        var files: [URL]
    }
    
    private func validSwiftFilePaths(at projectPath: String, ignorePaths: [String]) throws -> Files {
        let configuration = SearchFile.search(at: projectPath) { fileName in
            let url = URL(filePath: fileName)
            let isNotIgnored = url.pathComponents.allSatisfy { pathComponent in
                ignorePaths.contains(pathComponent) == false
            }
            if isNotIgnored {
                if fileName == ".swift-format" {
                    return true
                }
            }
            return false
        }.first.flatMap { URL(filePath: projectPath).appending(path: $0) }
        
        guard let configuration else {
            throw Error.swiftFormatConfigurationFileMissing
        }
        verbosePrint("Found configuration file at: \(configuration.relativePath)")
        
        let filePaths = SearchFile.search(at: projectPath) { fileName in
            let url = URL(fileURLWithPath: fileName)
            let isNotIgnored = url.pathComponents.allSatisfy { pathComponent in
                ignorePaths.contains(pathComponent) == false
            }
            if isNotIgnored {
                if url.pathExtension == "swift" {
                    return true
                }
            }
            return false
        }.map { URL(filePath: projectPath).appending(path: $0) }
        
        return .init(configuration: configuration, files: filePaths)
    }
    
    private func verbosePrint(_ items: Any...) {
        if verbose {
            print(items, separator: " ", terminator: "\n")
        }
    }
    
    private func lint(path: URL, configuration: URL) throws -> [Finding] {
        var findings: [Finding] = []
        let conf = try Configuration(contentsOf: configuration)
        let linter = SwiftLinter(configuration: conf) { finding in
            if let location = finding.location {
                print("""
                Category: \(finding.category.description)
                File: \(location.file)
                Line: \(location.line) Col: \(location.column)
                Message: \(finding.message.text)
                -----------------------
                """)
            }
            findings.append(finding)
        }
        try linter.lint(contentsOf: path)
        return findings
    }
}
