import SwiftUI
import Charts

struct HRVLineChartView: View {
    let hrvData: [HRVData]
    let sleepData: [SleepData]
    
    var body: some View {
        // Use GeometryReader to adjust the height of the chart based on its parent container
        GeometryReader { geometry in
            Chart {
                ForEach(filteredHRVData, id: \.date) { data in
                    LineMark(
                        x: .value("Time", data.date, unit: .minute),
                        y: .value("HRV (ms)", data.value)
                    )
                    .foregroundStyle(Color.red)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                }
                
                RuleMark(
                    y: .value(
                        "Average",
                        filteredHRVData.isEmpty
                        ? 0
                        : filteredHRVData.reduce(0) { $0 + $1.value }
                        / Double(filteredHRVData.count))
                )
                .foregroundStyle(Color.gray)
                .lineStyle(StrokeStyle(dash: [5]))
                .annotation(position: .trailing, alignment: .center) {
                    Text("AVG")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: filteredHRVData.map { $0.date }) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(
                        format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                }
            }
            .chartXScale(domain: xDomain)
            .frame(height: geometry.size.height) // Adjust the height to fill the container
            .padding(.top, 8)
            .padding(.horizontal, 15)// Optional: padding for top if needed
        }
    }
    
    private var filteredHRVData: [HRVData] {
        guard let sleepStart = sleepStartTime, let sleepEnd = sleepEndTime else {
            return []
        }
        
        return hrvData.filter { data in
            data.date >= sleepStart && data.date <= sleepEnd
        }
    }
    
    private var xDomain: ClosedRange<Date> {
        guard let sleepStart = sleepStartTime, let sleepEnd = sleepEndTime else {
            return Date()...Date()
        }
        return sleepStart...sleepEnd
    }
    
    private var sleepStartTime: Date? {
        sleepData.filter { $0.sleepStage != 1 }
            .map { $0.date }
            .min()
    }
    
    private var sleepEndTime: Date? {
        guard let sleepStart = sleepStartTime else { return nil }
        
        guard
            let lastSleepSegment = sleepData.filter({ $0.sleepStage != 1 }).max(by: {
                $0.date < $1.date
            })
        else { return nil }
        
        let sleepEnd =
        sleepData
            .filter { $0.sleepStage != 1 && $0.date >= sleepStart }
            .map { $0.date.addingTimeInterval($0.duration) }
            .max()
        
        return sleepEnd ?? lastSleepSegment.date.addingTimeInterval(lastSleepSegment.duration)
    }
}

