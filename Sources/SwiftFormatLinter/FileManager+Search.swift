//
//  File.swift
//  
//
//  Created by Ratnesh Jain on 18/03/24.
//

import Foundation

enum SearchFile {
    static func search(at path: String, predicate: (String) -> Bool) -> [String] {
        let enumarator = FileManager.default.enumerator(atPath: path)
        let filePaths = (enumarator?.allObjects as? [String]) ?? []
        let scanItems = filePaths.filter {
            predicate($0)
        }
        return scanItems
    }
    
    static func search(name: String, at path: String) -> [String] {
        self.search(at: path) { fileName in
            fileName.lowercased().contains(name)
        }
    }
}
