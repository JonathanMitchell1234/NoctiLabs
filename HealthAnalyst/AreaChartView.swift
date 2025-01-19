//
//  AreaChartView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//
import SwiftUI
import Charts

struct AreaChartView: View {
    let sleepData: [SleepData]
    
    private var startOfDay: Date {
        guard let firstDataPoint = sleepData.first else {
            return Calendar.current.startOfDay(for: Date())
        }
        return Calendar.current.startOfDay(for: firstDataPoint.date)
    }
    
    private var endOfDay: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }
    
    private var next12Hours: [Date] {
        guard let firstDataPoint = sleepData.first else {
            return []
        }
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: firstDataPoint.date)
        let start = calendar.date(
            bySettingHour: startHour, minute: 0, second: 0, of: firstDataPoint.date)!
        var dates: [Date] = []
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .hour, value: 2 * i, to: start) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var body: some View {
        Chart {
            ForEach(sleepData, id: \.id) { dataPoint in
                AreaMark(
                    x: .value("Time", dataPoint.date, unit: .hour),
                    yStart: .value(
                        "Min Duration",
                        dataPoint.sleepStage == 1 ? 0 : minDuration(for: dataPoint)),
                    yEnd: .value("Max Duration", maxDuration(for: dataPoint))
                )
                .foregroundStyle(by: .value("Sleep Stage", dataPoint.sleepStageName))
            }
            .interpolationMethod(.catmullRom)
        }
        .chartForegroundStyleScale([
            "Awake": .yellow,
            "Light": .green.opacity(0.4),
            "Deep": .blue.opacity(0.7),
            "REM": .purple.opacity(0.8),
            "In Bed": .gray.opacity(0.2),
        ])
        .chartXAxis {
            AxisMarks(values: next12Hours) { value in
                AxisGridLine()
                AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel(formatTime(from: date))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { mark in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYScale(domain: 0...maxDuration())
        .padding(.top, 8)
        .chartLegend(position: .bottom)
    }
    
    private func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.timeZone = .current
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }
    
    private func minDuration(for dataPoint: SleepData) -> Double {
        return 0
    }
    
    private func maxDuration(for dataPoint: SleepData) -> Double {
        return dataPoint.duration / 60
    }
    
    private func maxDuration() -> Double {
        guard let maxDataPoint = sleepData.max(by: { $0.duration < $1.duration }) else {
            return 1.0
        }
        return maxDataPoint.duration / 60
    }
}
