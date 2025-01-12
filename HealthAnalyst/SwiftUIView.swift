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

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // Date Picker
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

                    // Top Row (Circular Progress Indicators)
                    HStack(spacing: 16) {
                        CircularProgressView(percentage: calculateTotalSleepPercentage(), title: "Total Sleep Time", value: totalSleep)
                        CircularProgressView(percentage: 0.47, title: "3-Day Sleep Target", value: "Under Target") // Placeholder values
                    }

                    // Sleep Pattern Chart
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

                    // Sleep Stats
                    LazyVGrid(columns: columns, spacing: 16) {
                        StatView(title: "Deep Sleep", value: deepSleep, percentage: calculateSleepStagePercentage(stage: 3), description: nil, icon: "moon.zzz.fill")
                        StatView(title: "REM Sleep", value: remSleep, percentage: calculateSleepStagePercentage(stage: 4), description: nil, icon: "moon.stars.fill")
                        StatView(title: "Light Sleep", value: lightSleep, percentage: calculateSleepStagePercentage(stage: 2), description: nil, icon: "moon.fill")
                        StatView(title: "Heart Rate Dip", value: "19%", percentage: nil, description: "Average", icon: "heart.fill") // Placeholder
                        StatView(title: "Sleep Rhythm", value: "79%", percentage: nil, description: "Regular", icon: "waveform.path.ecg") // Placeholder
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

    // MARK: - HealthKit Authorization
    func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return // HealthKit is not available on this device
        }

        healthStore = HKHealthStore()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        healthStore?.requestAuthorization(toShare: [], read: [sleepType]) { (success, error) in
            if success {
                fetchSleepData(for: selectedDate)
            } else {
                // Handle authorization error
                print("HealthKit Authorization Error: \(error?.localizedDescription ?? "Unknown Error")")
            }
        }
    }

    // MARK: - Data Fetching
    func fetchSleepData(for date: Date) {
        isLoading = true // Show loading indicator

        guard let healthStore = healthStore else {
            isLoading = false
            return
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in

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
            }
        }

        healthStore.execute(query)
    }

    // Helper function to map HKCategoryValueSleepAnalysis to your SleepStage enum
    func sleepStage(from sample: HKCategorySample) -> Int? {
        switch sample.value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue: return 0 // Or whatever value you use to represent "in bed"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: return 3 // Deep sleep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return 4 // REM sleep
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return 2 // Light sleep (unspecified)
        case HKCategoryValueSleepAnalysis.awake.rawValue: return 1
        default: return nil
        }
    }
    
    // MARK: - Sleep Summary Calculations

    func updateSleepSummary() {
        let totalSeconds = sleepData.reduce(0) { $0 + $1.duration }
        totalSleep = formatTimeInterval(seconds: totalSeconds)

        deepSleep = formatTimeInterval(seconds: sleepData.filter { $0.sleepStage == 3 }.reduce(0) { $0 + $1.duration })
        remSleep = formatTimeInterval(seconds: sleepData.filter { $0.sleepStage == 4 }.reduce(0) { $0 + $1.duration })
        lightSleep = formatTimeInterval(seconds: sleepData.filter { $0.sleepStage == 2 }.reduce(0) { $0 + $1.duration })
    }

    func calculateSleepStagePercentage(stage: Int) -> String {
        let totalSleepSeconds = sleepData.reduce(0) { $0 + $1.duration }
        let stageSeconds = sleepData.filter { $0.sleepStage == stage }.reduce(0) { $0 + $1.duration }

        guard totalSleepSeconds > 0 else { return "0%" } // Avoid division by zero

        let percentage = (stageSeconds / totalSleepSeconds) * 100
        return String(format: "%.0f%%", percentage)
    }

    func calculateTotalSleepPercentage() -> CGFloat {
        let totalSleepSeconds = sleepData.reduce(0) { $0 + $1.duration }
        // Assuming 8 hours (28800 seconds) as the target sleep time
        let targetSleepSeconds: Double = 28800
        
        guard totalSleepSeconds > 0 else { return 0.0 }

        let percentage = min(CGFloat(totalSleepSeconds / targetSleepSeconds), 1.0) // Cap at 100%
        return percentage
    }

    // Helper function to format seconds into HH:mm
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
            
            // Legend
            HStack(spacing: 16) {
                ForEach(sleepStages, id: \.stage) { sleepStage in
                    LegendItem(color: colorForSleepStage(sleepStage.stage),
                              label: sleepStage.label)
                }
            }
            .padding(.top, 8)
        }
    }

    // Sleep stages data
    let sleepStages: [(stage: Int, label: String)] = [
        (0, "In Bed"),
        (1, "Awake"),
        (2, "Light"),
        (3, "Deep"),
        (4, "REM")
    ]

    func formatHour(_ hour: Int) -> String {
        let hourOfDay = (hour % 24)
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

// Helper view for legend items
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
