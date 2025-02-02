//
//  Recording.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 2/1/25.
//

import Foundation

struct Recording {
    let fileURL: URL
    let createdAt: Date
}

extension Recording {
    init(fileURL: URL) {
        self.fileURL = fileURL
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        self.createdAt = attributes?[.creationDate] as? Date ?? Date()
    }
}
