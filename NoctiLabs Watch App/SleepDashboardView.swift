//
//  SleepDashboardView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/26/25.
//

import HealthKit
import SwiftUI

// MARK: - Data Structures
struct HRVData {
    let date: Date
    let value: Double
}

struct SleepData {
    let date: Date
    let hour: Int
    let sleepStage: Int
    let duration: TimeInterval
}

// MARK: - Main View
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
    @State private var sleepInterruptions: Int = 0
    @State private var sleepStageTransitions: Int = 0
    @State private var averageSleepingHeartRate: String = "N/A"
    @State private var averageSleepingHRV: String = "N/A"
    @State private var averageSleepingBloodOxygen: String = "N/A"
    @State private var averageRespiratoryRate: String = "N/A"
    @State private var sleepQualityScore: Int?
    @State private var restingHeartRate: String = "N/A"
    @State private var sleepDebt: String = "N/A"
    @State private var sleepRegularity: String = "N/A"
    @State private var socialJetLag: String = "N/A"
    
    struct StatViewData: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let percentage: String?
        let description: String?
        let icon: String
        let color: Color
    }
    
    init() {
        let healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
        _healthStore = State(initialValue: healthStore)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(statViewsData) { stat in
                        StatView(
                            title: stat.title,
                            value: stat.value,
                            percentage: stat.percentage,
                            description: stat.description,
                            icon: stat.icon,
                            color: stat.color
                        )
                        .id(stat.id)
                        .scrollTransition { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                                .opacity(phase.isIdentity ? 1.0 : 0.5)
                                .rotation3DEffect(
                                    .degrees(phase.isIdentity ? 0 : 30),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .navigationTitle("Sleep Stats")
            .onAppear {
                checkHealthKitAuthorization()
            }
        }
    }

    // MARK: - HealthKit Authorization
    func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        healthStore = HKHealthStore()
        let typesToRead: Set<HKObjectType> = [
            .categoryType(forIdentifier: .sleepAnalysis)!,
            .quantityType(forIdentifier: .heartRate)!,
            .quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            .quantityType(forIdentifier: .oxygenSaturation)!,
            .quantityType(forIdentifier: .respiratoryRate)!,
            .quantityType(forIdentifier: .restingHeartRate)!
        ]
        
        healthStore?.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchSleepData(for: self.selectedDate)
            }
        }
    }
    
    func fetchHeartRateDip(for date: Date) {
        guard let healthStore = healthStore else {
            heartRateDip = "N/A"
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) {
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
                let bpm = sample.quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                if hour >= 8 && hour < 20 {
                    dayValues.append(bpm)
                } else {
                    nightValues.append(bpm)
                }
            }
            let avgDayHR = dayValues.isEmpty ? 0 : dayValues.reduce(0, +) / Double(dayValues.count)
            let avgNightHR =
            nightValues.isEmpty ? 0 : nightValues.reduce(0, +) / Double(nightValues.count)
            
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
    
    func fetchAverageSleepingHeartRate(for date: Date) {
        guard let healthStore = healthStore else {
            averageSleepingHeartRate = "N/A - HealthKit Error"
            return
        }
        
        guard let sleepStart = sleepData.filter({ $0.sleepStage != 1 }).map({ $0.date }).min(),
              let sleepEnd = sleepData.filter({ $0.sleepStage != 1 }).map({
                  $0.date.addingTimeInterval($0.duration)
              }).max()
        else {
            averageSleepingHeartRate = "N/A - No Sleep Data"
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error = error {
                print("Error fetching heart rate samples: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.averageSleepingHeartRate = "N/A - Query Error"
                }
                return
            }
            
            guard let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty else {
                DispatchQueue.main.async {
                    self.averageSleepingHeartRate = "N/A - No HR Data"
                }
                return
            }
            
            let heartRates = hrSamples.map {
                $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
            let averageHeartRate = heartRates.reduce(0.0, +) / Double(heartRates.count)
            
            DispatchQueue.main.async {
                self.averageSleepingHeartRate = String(format: "%.0f bpm", averageHeartRate)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchAverageSleepingHRV(for date: Date) {
        guard let healthStore = healthStore else {
            averageSleepingHRV = "N/A - HealthKit Error"
            return
        }
        
        guard let sleepStart = sleepData.filter({ $0.sleepStage != 1 }).map({ $0.date }).min(),
              let sleepEnd = sleepData.filter({ $0.sleepStage != 1 }).map({
                  $0.date.addingTimeInterval($0.duration)
              }).max()
        else {
            averageSleepingHRV = "N/A - No Sleep Data"
            return
        }
        
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let predicate = HKQuery.predicateForSamples(
            withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error = error {
                print("Error fetching HRV samples: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.averageSleepingHRV = "N/A - Query Error"
                }
                return
            }
            
            guard let hrvSamples = samples as? [HKQuantitySample], !hrvSamples.isEmpty else {
                DispatchQueue.main.async {
                    self.averageSleepingHRV = "N/A - No HRV Data"
                }
                return
            }
            
            let hrvValues = hrvSamples.map {
                $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }
            let averageHRV = hrvValues.reduce(0.0, +) / Double(hrvValues.count)
            
            DispatchQueue.main.async {
                self.averageSleepingHRV = String(format: "%.0f ms", averageHRV)
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Data Fetching Methods
    func fetchSleepData(for date: Date) {
        guard let healthStore = healthStore else { return }
        isLoading = true
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: date),
            end: Calendar.current.date(byAdding: .day, value: 1, to: date),
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: .categoryType(forIdentifier: .sleepAnalysis)!,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            
            let tryYesterday = {
                if Calendar.current.isDateInToday(date) {
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                    self.fetchSleepData(for: yesterday)
                }
            }
            
            guard let samples = samples as? [HKCategorySample], error == nil else {
                tryYesterday()
                return
            }
            
            if samples.isEmpty && Calendar.current.isDateInToday(date) {
                tryYesterday()
                return
            }
            
            let newData = samples.compactMap { sample -> SleepData? in
                guard let stage = self.sleepStage(from: sample) else { return nil }
                return SleepData(
                    date: sample.startDate,
                    hour: Calendar.current.component(.hour, from: sample.startDate),
                    sleepStage: stage,
                    duration: sample.endDate.timeIntervalSince(sample.startDate)
                )
            }
            
            DispatchQueue.main.async {
                self.sleepData = newData
                self.updateSleepSummary()
                self.selectedDate = date
                // Fetch additional metrics after sleep data is loaded
                self.calculateSleepConsistency(for: date)
                self.fetchHeartRateDip(for: date)
                self.fetchAverageSleepingHeartRate(for: date)
                self.fetchAverageSleepingHRV(for: date)
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Data Processing
    private func updateSleepSummary() {
        let asleepData = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }
        let totalSeconds = asleepData.reduce(0) { $0 + $1.duration }
        totalSleep = formatTimeInterval(seconds: totalSeconds)
        
        func durationForStage(_ stage: Int) -> TimeInterval {
            sleepData.filter { $0.sleepStage == stage }.reduce(0) { $0 + $1.duration }
        }
        
        deepSleep = formatTimeInterval(seconds: durationForStage(3))
        remSleep = formatTimeInterval(seconds: durationForStage(4))
        lightSleep = formatTimeInterval(seconds: durationForStage(2))
        
        if let first = sleepData.first, let last = sleepData.last {
            let totalInBed = last.date.addingTimeInterval(last.duration).timeIntervalSince(first.date)
            timeInBed = formatTimeInterval(seconds: totalInBed)
            sleepEfficiency = String(format: "%.1f%%", (totalSeconds / totalInBed) * 100)
        }
        
        sleepInterruptions = sleepData.enumerated().reduce(0) { count, item in
            guard item.offset > 0 else { return count }
            let prev = sleepData[item.offset - 1]
            return ([2,3,4].contains(prev.sleepStage) && item.element.sleepStage == 1) ? count + 1 : count
        }
        
        // Placeholder calculation for sleep consistency
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
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
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
                    .first(where: { [2, 3, 4].contains(self.sleepStage(from: $0) ?? -1) })
                {
                    onsetTimes.append(firstSleep.startDate)
                }
            }
            
            guard onsetTimes.count >= 2 else {
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
    
    // MARK: - Helper Methods
    private func sleepStage(from sample: HKCategorySample) -> Int? {
        switch sample.value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue: return 0
        case HKCategoryValueSleepAnalysis.awake.rawValue: return 1
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: return 2
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return 3
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return 4
        default: return nil
        }
    }

    private func formatTimeInterval(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "N/A"
    }

    private func calculateSleepStagePercentage(stage: Int) -> String? {
        let total = sleepData.filter { [2,3,4].contains($0.sleepStage) }.reduce(0) { $0 + $1.duration }
        guard total > 0 else { return nil }
        let stageDuration = sleepData.filter { $0.sleepStage == stage }.reduce(0) { $0 + $1.duration }
        return String(format: "%.0f%%", (stageDuration / total) * 100)
    }
    
    private var statViewsData: [StatViewData] {
        [
            StatViewData(
                title: "Deep Sleep",
                value: deepSleep,
                percentage: calculateSleepStagePercentage(stage: 3),
                description: nil,
                icon: "moon.zzz.fill",
                color: .purple
            ),
            StatViewData(
                title: "REM Sleep",
                value: remSleep,
                percentage: calculateSleepStagePercentage(stage: 4),
                description: nil,
                icon: "moon.stars.fill",
                color: .blue
            ),
            StatViewData(
                title: "Light Sleep",
                value: lightSleep,
                percentage: calculateSleepStagePercentage(stage: 2),
                description: nil,
                icon: "moon.fill",
                color: .mint
            ),
            StatViewData(
                title: "Efficiency",
                value: sleepEfficiency,
                percentage: nil,
                description: "Time Asleep/In Bed",
                icon: "chart.bar.fill",
                color: .orange
            ),
            StatViewData(
                title: "In Bed",
                value: timeInBed,
                percentage: nil,
                description: "Total",
                icon: "bed.double.fill",
                color: .indigo
            ),
            StatViewData(
                title: "Consistency",
                value: sleepConsistency,
                percentage: nil,
                description: "Between Days",
                icon: "repeat.circle.fill",
                color: .green
            ),
            StatViewData(
                title: "HR Dip",
                value: heartRateDip,
                percentage: nil,
                description: "Average",
                icon: "heart.fill",
                color: .pink
            ),
            StatViewData(
                title: "Interruptions",
                value: "\(sleepInterruptions)",
                percentage: nil,
                description: "Awakenings",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ),
            StatViewData(
                title: "Sleep HR",
                value: averageSleepingHeartRate,
                percentage: nil,
                description: "Heart Rate",
                icon: "heart.fill",
                color: .pink
            ),
            StatViewData(
                title: "HRV",
                value: averageSleepingHRV,
                percentage: nil,
                description: "Variability",
                icon: "heart.text.square.fill",
                color: .teal
            )
        ]
    }
}

// MARK: - UI Components
extension SleepDashboardView {
    struct StatView: View {
        let title: String
        let value: String
        let percentage: String?
        let description: String?
        let icon: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(value == "N/A" ? .gray : .primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let percentage = percentage {
                        Text(percentage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    if let desc = description {
                        Text(desc)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
            )
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}
