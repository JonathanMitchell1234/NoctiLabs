import SwiftUI
import Charts
import HealthKit

struct SleepDashboardView: View {
    @State private var selectedDate: Date = Date()
    @State private var sleepData: [SleepData] = []
    @State private var healthStore: HKHealthStore?
    @State private var isLoading = false

    @State private var totalSleep: String = ""
    @State private var deepSleep: String = ""
    @State private var remSleep: String = ""
    @State private var lightSleep: String = ""
    @State private var averageSleepOnset: String = ""
    @State private var sleepConsistency: String = ""
    @State private var sleepEfficiency: String = ""
    @State private var timeInBed: String = ""
    @State private var heartRateDip: String = "N/A"
    // (2) Number of awakenings or sleep interruptions
    @State private var sleepInterruptions: Int = 0
    // (5) Sleep stage transitions
    @State private var sleepStageTransitions: Int = 0

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                    .onChange(of: selectedDate) {
                        fetchSleepData(for: selectedDate)
                    }

                    HStack(spacing: 16) {
                        CircularProgressView(
                            percentage: calculateTotalSleepPercentage(),
                            title: "Total Sleep Time",
                            value: totalSleep
                        )
                        CircularProgressView(
                            percentage: 0.47,
                            title: "3-Day Sleep Target",
                            value: "Under Target"
                        )
                    }

                    VStack(alignment: .leading) {
                        Text("Sleep Pattern")
                            .font(.headline)
                            .padding(.bottom, 4)

                        if isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else {
                            ChartView(sleepData: sleepData)
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
                    // Additional Line Graph: Sleep Trend Over Time
                    VStack(alignment: .leading) {
                        Text("Sleep Trend Over Time")
                            .font(.headline)
                            .padding(.bottom, 4)

                        if isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else {
                            SleepTrendLineView(sleepData: sleepData)
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
                    // Additional Bar Graph: Sleep Stage Distribution
                    VStack(alignment: .leading) {
                        Text("Sleep Stage Distribution")
                            .font(.headline)
                            .padding(.bottom, 4)

                        if isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else {
                            SleepStageDistributionView(sleepData: sleepData)
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)

                    LazyVGrid(columns: columns, spacing: 16) {
                        StatView(
                            title: "Deep Sleep",
                            value: deepSleep,
                            percentage: calculateSleepStagePercentage(stage: 3),
                            description: nil,
                            icon: "moon.zzz.fill"
                        )
                        StatView(
                            title: "REM Sleep",
                            value: remSleep,
                            percentage: calculateSleepStagePercentage(stage: 4),
                            description: nil,
                            icon: "moon.stars.fill"
                        )
                        StatView(
                            title: "Light Sleep",
                            value: lightSleep,
                            percentage: calculateSleepStagePercentage(stage: 2),
                            description: nil,
                            icon: "moon.fill"
                        )
                        StatView(
                            title: "Sleep Onset",
                            value: averageSleepOnset,
                            percentage: nil,
                            description: "Average",
                            icon: "clock.fill"
                        )
                        StatView(
                            title: "Sleep Efficiency",
                            value: sleepEfficiency,
                            percentage: nil,
                            description: "Time Asleep/In Bed",
                            icon: "chart.bar.fill"
                        )
                        StatView(
                            title: "Time in Bed",
                            value: timeInBed,
                            percentage: nil,
                            description: "Total",
                            icon: "bed.double.fill"
                        )
                        StatView(
                            title: "Sleep Consistency",
                            value: sleepConsistency,
                            percentage: nil,
                            description: "Between Days",
                            icon: "repeat.circle.fill"
                        )
                        StatView(
                            title: "Heart Rate Dip",
                            value: heartRateDip,
                            percentage: nil,
                            description: "Average",
                            icon: "heart.fill"
                        )
                        // (2) Interruptions
                        StatView(
                            title: "Interruptions",
                            value: "\(sleepInterruptions)",
                            percentage: nil,
                            description: "Awakenings",
                            icon: "exclamationmark.triangle.fill"
                        )
                        // (5) Stage Transitions
                        StatView(
                            title: "Transitions",
                            value: "\(sleepStageTransitions)",
                            percentage: nil,
                            description: "Stage Changes",
                            icon: "arrow.triangle.2.circlepath"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Sleep Dashboard")
            .preferredColorScheme(.dark)
            .onAppear {
                checkHealthKitAuthorization()
            }
        }
    }

    func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        healthStore = HKHealthStore()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

        healthStore?.requestAuthorization(
            toShare: [],
            read: [sleepType, heartRateType]
        ) { success, error in
            if success {
                fetchSleepData(for: selectedDate)
            } else {
                print("HealthKit Authorization Error: \(error?.localizedDescription ?? "Unknown Error")")
            }
        }
    }

    func fetchSleepData(for date: Date) {
        isLoading = true
        guard let healthStore = healthStore else {
            isLoading = false
            return
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                print("Error fetching sleep data: \(error?.localizedDescription ?? "Unknown Error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            let fetchedSleepData = samples.compactMap { sample -> SleepData? in
                guard let sleepStage = self.sleepStage(from: sample) else { return nil }
                return SleepData(
                    date: sample.startDate,
                    hour: Calendar.current.component(.hour, from: sample.startDate),
                    sleepStage: sleepStage,
                    duration: sample.endDate.timeIntervalSince(sample.startDate)
                )
            }

            DispatchQueue.main.async {
                self.sleepData = fetchedSleepData
                self.isLoading = false
                self.updateSleepSummary()
                self.fetchHeartRateDip(for: date)
            }
        }
        healthStore.execute(query)
    }

    func fetchHeartRateDip(for date: Date) {
        guard let healthStore = healthStore else {
            heartRateDip = "N/A"
            return
        }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
            _, samples, _ in
            guard let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty else {
                DispatchQueue.main.async {
                    self.heartRateDip = "N/A"
                }
                return
            }

            var dayValues: [Double] = []
            var nightValues: [Double] = []
            let calendar = Calendar.current

            for sample in hrSamples {
                let hour = calendar.component(.hour, from: sample.startDate)
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                if hour >= 8 && hour < 20 {
                    dayValues.append(bpm)
                } else {
                    nightValues.append(bpm)
                }
            }

            let avgDayHR = dayValues.isEmpty ? 0 : dayValues.reduce(0, +) / Double(dayValues.count)
            let avgNightHR = nightValues.isEmpty ? 0 : nightValues.reduce(0, +) / Double(nightValues.count)

            if avgDayHR == 0 || avgNightHR == 0 {
                DispatchQueue.main.async {
                    self.heartRateDip = "N/A"
                }
                return
            }

            let dip = max(0, (avgDayHR - avgNightHR) / avgDayHR * 100)
            DispatchQueue.main.async {
                self.heartRateDip = String(format: "%.0f%%", dip)
            }
        }
        healthStore.execute(query)
    }

    func sleepStage(from sample: HKCategorySample) -> Int? {
        switch sample.value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return 0
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return 1
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
             HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return 2
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return 3
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return 4
        default:
            return nil
        }
    }

    func updateSleepSummary() {
        let asleepData = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }
        let totalSleepSeconds = asleepData.reduce(0) { $0 + $1.duration }
        totalSleep = formatTimeInterval(seconds: totalSleepSeconds)

        deepSleep = formatTimeInterval(
            seconds: sleepData.filter { $0.sleepStage == 3 }.reduce(0) { $0 + $1.duration }
        )
        remSleep = formatTimeInterval(
            seconds: sleepData.filter { $0.sleepStage == 4 }.reduce(0) { $0 + $1.duration }
        )
        lightSleep = formatTimeInterval(
            seconds: sleepData.filter { $0.sleepStage == 2 }.reduce(0) { $0 + $1.duration }
        )

        let inBedOrAsleep = sleepData.filter { [0, 2, 3, 4].contains($0.sleepStage) }
        if inBedOrAsleep.isEmpty {
            timeInBed = "N/A"
            sleepEfficiency = "N/A"
            averageSleepOnset = "N/A"
        } else {
            let earliestStart = inBedOrAsleep.map { $0.date }.min()!
            let latestEnd = inBedOrAsleep.map { $0.date.addingTimeInterval($0.duration) }.max()!
            let totalInBedSeconds = latestEnd.timeIntervalSince(earliestStart)
            timeInBed = formatTimeInterval(seconds: totalInBedSeconds)

            if totalInBedSeconds > 0 {
                let efficiencyPercentage = (totalSleepSeconds / totalInBedSeconds) * 100
                sleepEfficiency = String(format: "%.1f%%", efficiencyPercentage)
            } else {
                sleepEfficiency = "N/A"
            }

            if let firstSleepEntry = asleepData.min(by: { $0.date < $1.date }) {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: firstSleepEntry.date)
                let minute = calendar.component(.minute, from: firstSleepEntry.date)
                averageSleepOnset = String(format: "%02d:%02d", hour, minute)
            } else {
                averageSleepOnset = "N/A"
            }
        }

        // (2) Calculate number of awakenings or interruptions
        let sortedSleepData = sleepData.sorted { $0.date < $1.date }
        var interruptionsCount = 0
        for i in 1..<sortedSleepData.count {
            let prev = sortedSleepData[i-1]
            let current = sortedSleepData[i]
            if [2, 3, 4].contains(prev.sleepStage) && current.sleepStage == 1 {
                interruptionsCount += 1
            }
        }
        sleepInterruptions = interruptionsCount

        // (5) Calculate sleep stage transitions
        var transitionsCount = 0
        for i in 1..<sortedSleepData.count {
            if sortedSleepData[i].sleepStage != sortedSleepData[i-1].sleepStage {
                transitionsCount += 1
            }
        }
        sleepStageTransitions = transitionsCount

        calculateSleepConsistency(for: selectedDate)
    }

    func calculateSleepConsistency(for currentDate: Date) {
        guard let healthStore = healthStore else {
            sleepConsistency = "N/A"
            return
        }
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let startDate = calendar.date(byAdding: .day, value: -7, to: currentDate)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                DispatchQueue.main.async {
                    self.sleepConsistency = "N/A"
                }
                return
            }
            let sleepByDay = Dictionary(grouping: samples) {
                calendar.startOfDay(for: $0.startDate)
            }
            var onsetTimes: [Date] = []
            for (_, dailySamples) in sleepByDay {
                if let firstSleep = dailySamples
                    .sorted(by: { $0.startDate < $1.startDate })
                    .first(where: { [2, 3, 4].contains(self.sleepStage(from: $0) ?? -1) }) {
                    onsetTimes.append(firstSleep.startDate)
                }
            }
            if onsetTimes.count < 2 {
                DispatchQueue.main.async {
                    self.sleepConsistency = "N/A"
                }
                return
            }
            var totalVariance: TimeInterval = 0
            let referenceTime = onsetTimes.first!
            for onsetTime in onsetTimes.dropFirst() {
                let diff = abs(calendar.dateComponents([.minute], from: referenceTime, to: onsetTime).minute ?? 0)
                totalVariance += Double(min(diff, 1440 - diff))
            }
            let averageVariance = totalVariance / Double(onsetTimes.count - 1)
            let consistencyScore = max(0, 100 - (averageVariance / 30 * 100))
            DispatchQueue.main.async {
                self.sleepConsistency = String(format: "%.0f%%", min(100, consistencyScore))
            }
        }
        healthStore.execute(query)
    }

    func calculateSleepStagePercentage(stage: Int) -> String {
        let totalSleepSeconds = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }.reduce(0) { $0 + $1.duration }
        let stageSeconds = sleepData.filter { $0.sleepStage == stage }.reduce(0) { $0 + $1.duration }
        guard totalSleepSeconds > 0 else { return "0%" }
        let percentage = (stageSeconds / totalSleepSeconds) * 100
        return String(format: "%.0f%%", percentage)
    }

    func calculateTotalSleepPercentage() -> CGFloat {
        let totalSleepSeconds = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }.reduce(0) { $0 + $1.duration }
        let targetSleepSeconds: Double = 28800
        guard totalSleepSeconds > 0 else { return 0 }
        let percentage = min(CGFloat(totalSleepSeconds / targetSleepSeconds), 1.0)
        return percentage
    }

    func formatTimeInterval(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}

struct CircularProgressView: View {
    let percentage: CGFloat
    let title: String
    let value: String

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(Color.green, lineWidth: 10)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percentage * 100))%")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 100, height: 100)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text(value)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let percentage: String?
    let description: String?
    let icon: String?

    var body: some View {
        VStack {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.8))
                }
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            if let percentage = percentage {
                Text(percentage)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct ChartView: View {
    let sleepData: [SleepData]

    var body: some View {
        VStack {
            Chart {
                ForEach(sleepData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Time", formatHour(dataPoint.hour)),
                        y: .value("Sleep Stage", dataPoint.sleepStage)
                    )
                    .foregroundStyle(colorForSleepStage(dataPoint.sleepStage))
                }
            }
            HStack(spacing: 16) {
                ForEach(sleepStages, id: \.stage) { sleepStage in
                    LegendItem(
                        color: colorForSleepStage(sleepStage.stage),
                        label: sleepStage.label
                    )
                }
            }
            .padding(.top, 8)
        }
    }

    let sleepStages: [(stage: Int, label: String)] = [
        (0, "In Bed"),
        (1, "Awake"),
        (2, "Light"),
        (3, "Deep"),
        (4, "REM")
    ]

    func formatHour(_ hour: Int) -> String {
        let hourOfDay = hour % 24
        return "\(hourOfDay)\(hourOfDay < 12 ? "AM" : "PM")"
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

struct SleepTrendLineView: View {
    let sleepData: [SleepData]

    var body: some View {
        Chart {
            ForEach(trendData, id: \.id) { data in
                LineMark(
                    x: .value("Day", data.day),
                    y: .value("Total Sleep (hrs)", data.totalSleepHours)
                )
                .foregroundStyle(Color.blue)
                .symbol(Circle())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }

    var trendData: [SleepTrend] {
        let calendar = Calendar.current
        let weekDates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -6 + $0, to: Date())
        }
        return weekDates.map { date in
            let daySleep = sleepData.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            let totalSeconds = daySleep.reduce(0) { $0 + $1.duration }
            let totalHours = totalSeconds / 3600
            let dayLabel = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            return SleepTrend(day: dayLabel, totalSleepHours: totalHours)
        }
    }
}

struct SleepTrend: Identifiable {
    let id = UUID()
    let day: String
    let totalSleepHours: Double
}

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
        let stages = [0, 1, 2, 3, 4]
        return stages.map { stage in
            let stageData = sleepData.filter { $0.sleepStage == stage }
            let totalSeconds = stageData.reduce(0) { $0 + $1.duration }
            let hours = totalSeconds / 3600
            let label: String
            switch stage {
            case 0: label = "In Bed"
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

struct SleepStage: Identifiable {
    let id = UUID()
    let stage: Int
    let label: String
    let durationHours: Double
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct SleepData {
    let date: Date
    let hour: Int
    let sleepStage: Int
    let duration: TimeInterval
}

#Preview {
    SleepDashboardView()
}
