//
//  Item.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/11/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
