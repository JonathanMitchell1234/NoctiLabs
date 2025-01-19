//
//  SleepStageDistributionView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//

import SwiftUI
import Charts

struct SleepStageDistributionView: View {
    let sleepData: [SleepData]
    
    var body: some View {
        Chart {
            ForEach(sleepStageDistribution, id: \.stage) { stage in
                BarMark(
                    x: .value("Sleep Stage", stage.label),
                    y: .value("Duration (hrs)", stage.durationHours)
                )
                .foregroundStyle(colorForSleepStage(stage.stage))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
    }
    
    var sleepStageDistribution: [SleepStage] {
        let stages = [1, 2, 3, 4]
        return stages.map { stage in
            let stageData = sleepData.filter { $0.sleepStage == stage }
            let totalSeconds = stageData.reduce(0) { $0 + $1.duration }
            let hours = totalSeconds / 3600
            let label: String
            switch stage {
            case 1: label = "Awake"
            case 2: label = "Light"
            case 3: label = "Deep"
            case 4: label = "REM"
            default: label = "Unknown"
            }
            return SleepStage(stage: stage, label: label, durationHours: hours)
        }
    }
    
    func colorForSleepStage(_ stage: Int) -> Color {
        switch stage {
        case 0: return .gray
        case 1: return .yellow
        case 2: return .green.opacity(0.3)
        case 3: return .blue.opacity(0.6)
        case 4: return .purple.opacity(0.7)
        default: return .gray
        }
    }
}
