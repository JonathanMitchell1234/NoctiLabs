import SwiftUI
import Charts

struct AreaChartView: View {
    let sleepData: [SleepData]
    
    private var sleepStageMapping: [Int: (name: String, value: Double)] {
        [
            0: ("In Bed", 0.0),
            1: ("Awake", 4.0),
            2: ("Core/Light", 2.0),
            3: ("Deep", 1.0),
            4: ("REM", 3.0)
        ]
    }
    
    private var dynamicTimeRange: [Date] {
        guard let firstDataPoint = sleepData.first,
              let lastDataPoint = sleepData.last else {
            return []
        }
        
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .hour, value: -1, to: firstDataPoint.date)!
        let end = calendar.date(byAdding: .hour, value: 1, to: lastDataPoint.date.addingTimeInterval(lastDataPoint.duration))!
        
        var dates: [Date] = []
        var current = calendar.date(bySetting: .minute, value: 0, of: start) ?? start
        
        while current <= end {
            dates.append(current)
            current = calendar.date(byAdding: .hour, value: 1, to: current)!
        }
        return dates
    }
    
    var body: some View {
        GeometryReader { geometry in
            Chart {
                ForEach(createHypnogramData(), id: \.id) { dataPoint in
                    // Draw horizontal bars for sleep stages
                    BarMark(
                        xStart: .value("Start Time", dataPoint.startDate),
                        xEnd: .value("End Time", dataPoint.endDate),
                        y: .value("Sleep Stage", dataPoint.stageValue)
                    )
                    .cornerRadius(0)
                    .foregroundStyle(by: .value("Sleep Stage", dataPoint.stage))
                    
                    // Draw vertical lines (transition points) connecting bars
                    LineMark(
                        x: .value("Time", dataPoint.startDate),
                        y: .value("Sleep Stage", dataPoint.stageValue)
                    )
                    .foregroundStyle(.gray)
                    .interpolationMethod(.stepCenter)
                }
            }
            .chartForegroundStyleScale([
                "Awake": .yellow,
                "Core/Light": .green.opacity(0.4),
                "Deep": .blue.opacity(0.7),
                "REM": .purple.opacity(0.8),
                "In Bed": .gray.opacity(0.2)
            ])
            .chartXAxis {
                AxisMarks(values: dynamicTimeRange) { value in
                    AxisGridLine()
                    AxisTick()
                    if let date = value.as(Date.self) {
                        AxisValueLabel(formatTime(from: date))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4]) { mark in
                    if let stageValue = mark.as(Double.self),
                       let stageName = sleepStageMapping.first(where: { $0.value.value == stageValue })?.value.name {
                        AxisValueLabel(stageName)
                    }
                    AxisGridLine()
                }
            }
            .chartYScale(domain: -0.5...4.5)
            .padding(.top, 8)
            .padding(.horizontal, 6)
            .padding(.bottom, 50)
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)
            .frame(height: 250) // Fill the container's height
        }
    }
        

    private func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.timeZone = .current
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }

    private func createHypnogramData() -> [HypnogramDataPoint] {
        let epochDuration: TimeInterval = 300
        var hypnogramData: [HypnogramDataPoint] = []
        
        guard let firstDataPoint = sleepData.first, let lastDataPoint = sleepData.last else {
            return []
        }
        
        let startDate = firstDataPoint.date
        let endDate = lastDataPoint.date.addingTimeInterval(lastDataPoint.duration)
        var epochStart = startDate
        var previousStageValue: Double? = nil
        
        while epochStart < endDate {
            let epochEnd = epochStart.addingTimeInterval(epochDuration)
            let stage = mostFrequentStage(in: epochStart..<epochEnd)
            
            if let stageName = sleepStageMapping[stage]?.name,
               let stageValue = sleepStageMapping[stage]?.value {
                if let prevValue = previousStageValue, prevValue != stageValue {
                    hypnogramData.append(HypnogramDataPoint(startDate: epochStart, endDate: epochStart, stage: stageName, stageValue: prevValue))
                }
                
                hypnogramData.append(HypnogramDataPoint(startDate: epochStart, endDate: epochEnd, stage: stageName, stageValue: stageValue))
                previousStageValue = stageValue
            }
            
            epochStart = epochEnd
        }
        
        return hypnogramData
    }
    
    private func mostFrequentStage(in timeRange: Range<Date>) -> Int {
        let relevantData = sleepData.filter { dataPoint in
            let dataPointEnd = dataPoint.date.addingTimeInterval(dataPoint.duration)
            return dataPoint.date < timeRange.upperBound && dataPointEnd > timeRange.lowerBound
        }
        
        var stageCounts: [Int: Int] = [:]
        for dataPoint in relevantData {
            let dataPointStart = max(dataPoint.date, timeRange.lowerBound)
            let dataPointEnd = min(dataPoint.date.addingTimeInterval(dataPoint.duration), timeRange.upperBound)
            let durationInEpoch = max(0, dataPointEnd.timeIntervalSince(dataPointStart))
            
            stageCounts[dataPoint.sleepStage, default: 0] += Int(durationInEpoch)
        }
        
        return stageCounts.max(by: { $0.value < $1.value })?.key ?? 1
    }
}

struct HypnogramDataPoint: Identifiable, Hashable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let stage: String
    let stageValue: Double
}

