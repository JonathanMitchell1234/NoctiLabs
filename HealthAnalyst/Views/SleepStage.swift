//
//  SleepStage.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//
import SwiftUI
import Foundation

struct SleepStage: Identifiable {
    let id = UUID()
    let stage: Int
    let label: String
    let durationHours: Double
}
