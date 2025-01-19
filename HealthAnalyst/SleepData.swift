//
//  SleepData.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//

import Foundation

// MARK: - SleepData Struct

struct SleepData: Identifiable {
    let id = UUID()
    let date: Date
    let hour: Int
    let sleepStage: Int
    let duration: TimeInterval

    var sleepStageName: String {
        switch sleepStage {
        case 0: return "In Bed"
        case 1: return "Awake"
        case 2: return "Light"
        case 3: return "Deep"
        case 4: return "REM"
        default: return "Unknown"
        }
    }
}

// MARK: - Extensions

extension SleepData: Equatable {
    static func == (lhs: SleepData, rhs: SleepData) -> Bool {
        return lhs.id == rhs.id
            && lhs.date == rhs.date && lhs.hour == rhs.hour && lhs.sleepStage == rhs.sleepStage
            && lhs.duration == rhs.duration
    }
}
