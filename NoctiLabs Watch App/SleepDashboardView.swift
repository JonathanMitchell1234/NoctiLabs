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
    
    // CHANGED: Single column for full width items
    let columns = [GridItem(.flexible())]

    init() {
            let healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
            _healthStore = State(initialValue: healthStore)
        }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {

                    }
                    .padding(.bottom, 8)
                    
                    // CHANGED: Using single column layout
                    LazyVGrid(columns: columns, spacing: 8) {
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
                            title: "Efficiency",
                            value: sleepEfficiency,
                            percentage: nil,
                            description: "Time Asleep/In Bed",
                            icon: "chart.bar.fill"
                        )
                        
                        StatView(
                            title: "In Bed",
                            value: timeInBed,
                            percentage: nil,
                            description: "Total",
                            icon: "bed.double.fill"
                        )
                        
                        StatView(
                            title: "Consistency",
                            value: sleepConsistency,
                            percentage: nil,
                            description: "Between Days",
                            icon: "repeat.circle.fill"
                        )
                        
                        StatView(
                            title: "HR Dip",
                            value: heartRateDip,
                            percentage: nil,
                            description: "Average",
                            icon: "heart.fill"
                        )
                        
                        StatView(
                            title: "Interruptions",
                            value: "\(sleepInterruptions)",
                            percentage: nil,
                            description: "Awakenings",
                            icon: "exclamationmark.triangle.fill"
                        )
                        
                        StatView(
                            title: "Sleep HR",
                            value: averageSleepingHeartRate,
                            percentage: nil,
                            description: "Heart Rate",
                            icon: "heart.fill"
                        )
                        
                        StatView(
                            title: "HRV",
                            value: averageSleepingHRV,
                            percentage: nil,
                            description: "Variability",
                            icon: "heart.text.square.fill"
                        )
                    }
                    .padding(.horizontal, 4)
                }
                .padding(4)
            }
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
//                   self.fetchHRVData(for: self.selectedDate)
//                   self.fetchRestingHeartRate(for: self.selectedDate)
               }
           }
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
                
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    if Calendar.current.isDateInToday(date) {
                        self.fetchSleepData(for: Calendar.current.date(byAdding: .day, value: -1, to: date)!)
                    }
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
                }
            }
            healthStore.execute(query)
        }

        // MARK: - Data Processing
        private func updateSleepSummary() {
            let asleepData = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }
            let totalSeconds = asleepData.reduce(0) { $0 + $1.duration }
            totalSleep = formatTimeInterval(seconds: totalSeconds)
            
            // Calculate stage durations
            func durationForStage(_ stage: Int) -> TimeInterval {
                sleepData.filter { $0.sleepStage == stage }.reduce(0) { $0 + $1.duration }
            }
            
            deepSleep = formatTimeInterval(seconds: durationForStage(3))
            remSleep = formatTimeInterval(seconds: durationForStage(4))
            lightSleep = formatTimeInterval(seconds: durationForStage(2))
            
            // Calculate sleep efficiency
            if let first = sleepData.first, let last = sleepData.last {
                let totalInBed = last.date.addingTimeInterval(last.duration).timeIntervalSince(first.date)
                timeInBed = formatTimeInterval(seconds: totalInBed)
                sleepEfficiency = String(format: "%.1f%%", (totalSeconds / totalInBed) * 100)
            }
            
            // Calculate interruptions
            sleepInterruptions = sleepData.enumerated().reduce(0) { count, item in
                guard item.offset > 0 else { return count }
                let prev = sleepData[item.offset - 1]
                return ([2,3,4].contains(prev.sleepStage) && item.element.sleepStage == 1) ? count + 1 : count
            }
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

        private func calculateSleepStagePercentage(stage: Int) -> String {
            let total = sleepData.filter { [2,3,4].contains($0.sleepStage) }.reduce(0) { $0 + $1.duration }
            guard total > 0 else { return "0%" }
            let stageDuration = sleepData.filter { $0.sleepStage == stage }.reduce(0) { $0 + $1.duration }
            return String(format: "%.0f%%", (stageDuration / total) * 100)
        }

        private func calculateTotalSleepPercentage() -> CGFloat {
            let target: Double = 8 * 3600 // 8 hours
            let actual = sleepData.filter { [2,3,4].contains($0.sleepStage) }.reduce(0) { $0 + $1.duration }
            return min(CGFloat(actual / target), 1.0)
        }
    }

    // MARK: - UI Components
    extension SleepDashboardView {
        struct CircularProgressView: View {
            let percentage: CGFloat
            let title: String
            let value: String
            
            var body: some View {
                VStack {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 4)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                        
                        Circle()
                            .trim(from: 0, to: percentage)
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text(value)
                                .font(.system(size: 14, weight: .bold))
                            Text(title)
                                .font(.system(size: 10))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: 60, height: 60)
                }
            }
        }
        
        struct StatView: View {
            let title: String
            let value: String
            let percentage: String?
            let description: String?
            let icon: String
            
            var body: some View {
                VStack(alignment: .center, spacing: 4) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                    
                    if let percentage = percentage {
                        Text(percentage)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    if let desc = description {
                        Text(desc)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                // ADDED: Fixed height for vertical stacking
                .frame(height: 80)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Preview
    struct SleepDashboardView_Previews: PreviewProvider {
        static var previews: some View {
            SleepDashboardView()
        }
    }
