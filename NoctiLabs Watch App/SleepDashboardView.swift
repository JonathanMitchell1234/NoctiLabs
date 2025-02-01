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
    
    // Create an array of StatViewData
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
                             // Add the scrollTransition modifier here
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
            
            // Check if we should try yesterday's data
            let tryYesterday = {
                if Calendar.current.isDateInToday(date) {
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                    self.fetchSleepData(for: yesterday)
                }
            }
            
            // Handle errors or empty data
            guard let samples = samples as? [HKCategorySample], error == nil else {
                tryYesterday()
                return
            }
            
            // If no data found for today, try yesterday
            if samples.isEmpty && Calendar.current.isDateInToday(date) {
                tryYesterday()
                return
            }
            
            // Process the samples we found
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
                // Update selectedDate to match the data we found
                self.selectedDate = date
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
    
    // Create statViewsData after updating sleepData
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}

//// MARK: - Preview
//struct SleepDashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        SleepDashboardView()
//            .previewDevice("Apple Watch Series 9 (45mm)")
//    }
//}
