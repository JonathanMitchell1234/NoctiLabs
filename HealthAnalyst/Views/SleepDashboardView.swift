import Charts
import HealthKit
import SwiftUI

// MARK: - Extensions
extension Date {
    func toLocalTime() -> Date {
        let timeZone = TimeZone.current
        let seconds = TimeInterval(timeZone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}

// MARK: - HRVData Struct
struct HRVData {
    let date: Date
    let value: Double
}

// MARK: - SleepDashboardView Struct

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
    @State private var hrvData: [HRVData] = []
    @State private var averageSleepingHeartRate: String = "N/A"
    @State private var averageSleepingHRV: String = "N/A"
    @State private var averageSleepingBloodOxygen: String = "N/A"
    @State private var averageRespiratoryRate: String = "N/A"
    @State private var sleepQualityScore: Int?
    @State private var restingHeartRate: String = "N/A"
    @State private var sleepDebt: String = "N/A"
    @State private var sleepRegularity: String = "N/A"
    @State private var socialJetLag: String = "N/A"
    @State private var deepSleepPopover = false
    @State private var remSleepPopover = false
    @State private var lightSleepPopover = false
    @State private var sleepOnsetPopover = false
    @State private var sleepEfficiencyPopover = false
    @State private var timeInBedPopover = false
    @State private var sleepConsistencyPopover = false
    @State private var heartRateDipPopover = false
    @State private var interruptionsPopover = false
    @State private var transitionsPopover = false
    @State private var averageRespiratoryRatePopover = false
    @State private var averageSleepingHeartRatePopover = false
    @State private var averageSleepingHRVPopover = false
    @State private var averageSleepingBloodOxygenPopover = false
    @State private var averageRestingHeartRate: String = "N/A"
    private var notificationManager: SleepNotificationManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    init() {
        let healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
        _healthStore = State(initialValue: healthStore)
        notificationManager = SleepNotificationManager(healthStore: healthStore)
        notificationManager.requestNotificationPermissions()
        _selectedDate = State(initialValue: Date())
        _sleepData = State(initialValue: [])
    }
    
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
                        fetchHRVData(for: selectedDate)
                    }
                    
                    HStack(spacing: 16) {
                        CircularProgressView(
                            percentage: calculateTotalSleepPercentage(),
                            title: "Total Sleep Time",
                            value: totalSleep
                        )
                        
                        if let score = sleepQualityScore {
                            CircularProgressView(
                                percentage: CGFloat(score) / 100.0,
                                title: "Sleep Quality",
                                value: "\(score)"
                            )
                            .accentColor(.green)
                        } else {
                            CircularProgressView(
                                percentage: 0,
                                title: "Sleep Quality",
                                value: "N/A"
                            )
                            .accentColor(.gray)
                        }
                        
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
                            AreaChartView(sleepData: sleepData)
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading) {
                        Text("Heart Rate Variability (HRV) During Sleep")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        if isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else {
                            HRVLineChartView(hrvData: hrvData, sleepData: sleepData)
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
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
                        .popover(
                            isPresented: $deepSleepPopover
                        ) {
                            PopoverTextView(
                                title: "Deep Sleep",
                                content:
                                    "Deep sleep, also known as slow-wave sleep (SWS), is crucial for physical restoration, muscle repair, and growth hormone release. During this stage, brain waves are at their slowest, and it's difficult to awaken someone. Deep sleep also plays a role in consolidating declarative memories (facts and events)."
                            )
                        }
                        .onTapGesture {
                            deepSleepPopover.toggle()
                        }
                        
                        StatView(
                            title: "REM Sleep",
                            value: remSleep,
                            percentage: calculateSleepStagePercentage(stage: 4),
                            description: nil,
                            icon: "moon.stars.fill"
                        )
                        .popover(
                            isPresented: $remSleepPopover
                        ) {
                            PopoverTextView(
                                title: "REM Sleep",
                                content:
                                    "REM sleep is important for cognitive functions, memory consolidation, and emotional regulation. Characterized by rapid eye movements and brain activity similar to wakefulness, it's the stage where most vivid dreams occur. REM sleep helps process emotions, enhances creativity, and contributes to learning."
                            )
                        }
                        .onTapGesture {
                            remSleepPopover.toggle()
                        }
                        
                        StatView(
                            title: "Light Sleep",
                            value: lightSleep,
                            percentage: calculateSleepStagePercentage(stage: 2),
                            description: nil,
                            icon: "moon.fill"
                        )
                        .popover(
                            isPresented: $lightSleepPopover
                        ) {
                            PopoverTextView(
                                title: "Light Sleep",
                                content:
                                    "Light sleep serves as a transition between wakefulness and deeper sleep stages, contributing to overall sleep architecture. It is the most common sleep stage, making up about 50-60% of total sleep time. During light sleep, muscle activity decreases, and eye movements stop, preparing the body for deeper sleep stages."
                            )
                        }
                        .onTapGesture {
                            lightSleepPopover.toggle()
                        }
                        
                        StatView(
                            title: "Sleep Onset",
                            value: averageSleepOnset,
                            percentage: nil,
                            description: "Average",
                            icon: "clock.fill"
                        )
                        .popover(
                            isPresented: $sleepOnsetPopover
                        ) {
                            PopoverTextView(
                                title: "Sleep Onset",
                                content:
                                    "Sleep onset, also known as sleep latency, is the time it takes to fall asleep after going to bed. A shorter sleep onset latency generally indicates better sleep quality. Factors like stress, caffeine, and irregular sleep schedules can increase sleep onset time."
                            )
                        }
                        .onTapGesture {
                            sleepOnsetPopover.toggle()
                        }
                        
                        StatView(
                            title: "Sleep Efficiency",
                            value: sleepEfficiency,
                            percentage: nil,
                            description: "Time Asleep/In Bed",
                            icon: "chart.bar.fill"
                        )
                        .popover(
                            isPresented: $sleepEfficiencyPopover
                        ) {
                            PopoverTextView(
                                title: "Sleep Efficiency",
                                content:
                                    "Sleep efficiency is the percentage of time spent asleep relative to the total time spent in bed. Higher efficiency indicates better sleep quality, meaning you spend more time asleep than awake while in bed. An efficiency of 85% or higher is generally considered good."
                            )
                        }
                        .onTapGesture {
                            sleepEfficiencyPopover.toggle()
                        }
                        
                        StatView(
                            title: "Time in Bed",
                            value: timeInBed,
                            percentage: nil,
                            description: "Total",
                            icon: "bed.double.fill"
                        )
                        .popover(
                            isPresented: $timeInBedPopover
                        ) {
                            PopoverTextView(
                                title: "Time in Bed",
                                content:
                                    "This is the total time spent in bed, including both sleep and wake periods. It's measured from the moment you get into bed with the intention to sleep until the moment you get out of bed for the final time."
                            )
                        }
                        .onTapGesture {
                            timeInBedPopover.toggle()
                        }
                        
                        StatView(
                            title: "Sleep Consistency",
                            value: sleepConsistency,
                            percentage: nil,
                            description: "Between Days",
                            icon: "repeat.circle.fill"
                        )
                        .popover(
                            isPresented: $sleepConsistencyPopover
                        ) {
                            PopoverTextView(
                                title: "Sleep Consistency",
                                content:
                                    "Sleep consistency measures the regularity of your sleep schedule over multiple days. Maintaining a consistent sleep schedule (going to bed and waking up around the same time each day) can improve sleep quality by regulating your body's natural sleep-wake cycle (circadian rhythm)."
                            )
                        }
                        .onTapGesture {
                            sleepConsistencyPopover.toggle()
                        }
                        
                        StatView(
                            title: "Heart Rate Dip",
                            value: heartRateDip,
                            percentage: nil,
                            description: "Average",
                            icon: "heart.fill"
                        )
                        .popover(
                            isPresented: $heartRateDipPopover
                        ) {
                            PopoverTextView(
                                title: "Heart Rate Dip",
                                content:
                                    "Heart rate dip during sleep is a normal physiological response where your heart rate decreases compared to your waking heart rate. A significant dip (typically 10-20%) is generally associated with better cardiovascular health and restorative sleep."
                            )
                        }
                        .onTapGesture {
                            heartRateDipPopover.toggle()
                        }
                        
                        StatView(
                            title: "Interruptions",
                            value: "\(sleepInterruptions)",
                            percentage: nil,
                            description: "Awakenings",
                            icon: "exclamationmark.triangle.fill"
                        )
                        .popover(
                            isPresented: $interruptionsPopover
                        ) {
                            PopoverTextView(
                                title: "Interruptions",
                                content:
                                    "Sleep interruptions are brief awakenings during the night. Fewer interruptions typically indicate better sleep quality as they can disrupt the natural progression through sleep stages. Frequent interruptions may be a sign of a sleep disorder or other underlying health condition."
                            )
                        }
                        .onTapGesture {
                            interruptionsPopover.toggle()
                        }
                        
                        StatView(
                            title: "Transitions",
                            value: "\(sleepStageTransitions)",
                            percentage: nil,
                            description: "Stage Changes",
                            icon: "arrow.triangle.2.circlepath"
                        )
                        .popover(
                            isPresented: $transitionsPopover
                        ) {
                            PopoverTextView(
                                title: "Transitions",
                                content:
                                    "Sleep stage transitions are the shifts between different sleep stages (e.g., light, deep, REM). The number and pattern of transitions can affect sleep quality. A healthy sleep pattern involves smooth transitions between stages throughout the night."
                            )
                        }
                        .onTapGesture {
                            transitionsPopover.toggle()
                        }
                        
                        StatView(
                            title: "Avg. Sleeping HR", value: averageSleepingHeartRate,
                            percentage: nil, description: "Heart Rate", icon: "heart.fill"
                        )
                        .popover(
                            isPresented: $averageSleepingHeartRatePopover
                        ) {
                            PopoverTextView(
                                title: "Avg. Sleeping HR",
                                content:
                                    "Average Sleeping Heart Rate represents the average number of heartbeats per minute while you're asleep. It's typically lower than your waking heart rate and can be an indicator of cardiovascular health. A lower sleeping heart rate is often associated with better fitness and more efficient heart function."
                            )
                        }
                        .onTapGesture {
                            averageSleepingHeartRatePopover.toggle()
                        }
                        
                        StatView(
                            title: "Avg. Sleeping HRV", value: averageSleepingHRV, percentage: nil,
                            description: "HRV", icon: "heart.text.square.fill"
                        )
                        .popover(
                            isPresented: $averageSleepingHRVPopover
                        ) {
                            PopoverTextView(
                                title: "Avg. Sleeping HRV",
                                content:
                                    "Average Sleeping Heart Rate Variability (HRV) measures the variation in time intervals between heartbeats during sleep. It reflects the balance of your autonomic nervous system. Higher HRV during sleep is generally associated with better recovery, stress resilience, and overall health."
                            )
                        }
                        .onTapGesture {
                            averageSleepingHRVPopover.toggle()
                        }
                        
                        StatView(
                            title: "Avg. Sleeping Blood O2", value: averageSleepingBloodOxygen,
                            percentage: nil, description: "Blood Oxygen", icon: "lungs.fill"
                        )
                        .popover(
                            isPresented: $averageSleepingBloodOxygenPopover
                        ) {
                            PopoverTextView(
                                title: "Avg. Sleeping Blood O2",
                                content:
                                    "Average Sleeping Blood Oxygen Saturation (SpO2) indicates the percentage of oxygen in your blood during sleep. Normal levels are typically between 95-100%. Consistently low levels may indicate a sleep-related breathing disorder like sleep apnea and should be discussed with a doctor."
                            )
                        }
                        .onTapGesture {
                            averageSleepingBloodOxygenPopover.toggle()
                        }
                        
                        StatView(
                            title: "Avg. Respiratory Rate", value: averageRespiratoryRate,
                            percentage: nil, description: "Breaths/Min", icon: "wind"
                        )
                        .popover(
                            isPresented: $averageRespiratoryRatePopover
                        ) {
                            PopoverTextView(
                                title: "Avg. Respiratory Rate",
                                content:
                                    "Average Respiratory Rate during sleep is the average number of breaths you take per minute while asleep. A normal range is typically between 12-20 breaths per minute. Changes in respiratory rate during sleep can be influenced by factors such as sleep stage, age, and health conditions."
                            )
                        }
                        .onTapGesture {
                            averageRespiratoryRatePopover.toggle()
                        }
                        
                        StatView(
                            title: "Resting HR",
                            value: averageRestingHeartRate,
                            percentage: nil,
                            description: "During Sleep",
                            icon: "heart.fill"
                        )
                        
                        StatView(
                            title: "Sleep Debt",
                            value: sleepDebt,
                            percentage: nil,
                            description: "Last 7 Days",
                            icon: "exclamationmark.triangle.fill"
                        )
                        
                        StatView(
                            title: "Sleep Regularity",
                            value: sleepRegularity,
                            percentage: nil,
                            description: "Last 7 Days",
                            icon: "calendar.circle.fill"
                        )
                        
                        StatView(
                            title: "Social Jet Lag",
                            value: socialJetLag,
                            percentage: nil,
                            description: "Last 7 Days",
                            icon: "bed.double.fill"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                SleepJournalView()
                SleepSoundsMixerView()
                AudioPlayerView()
            }
            .navigationTitle("Sleep Dashboard")
            .preferredColorScheme(.dark)
            .onAppear {
                checkHealthKitAuthorization()
            }
            
            .onChange(of: sleepData) { _ in
                calculateSleepQualityScore()
            }
            .onChange(of: sleepConsistency) { _ in
                calculateSleepQualityScore()
            }
            .onChange(of: heartRateDip) { _ in
                calculateSleepQualityScore()
            }
            .onChange(of: averageSleepingHRV) { _ in
                calculateSleepQualityScore()
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
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!

        healthStore?.requestAuthorization(
            toShare: [],
            read: [
                sleepType, heartRateType, hrvType, bloodOxygenType, respiratoryRateType,
                restingHeartRateType,
            ]
        ) { success, error in
            if success {
                fetchSleepData(for: selectedDate)
                fetchHRVData(for: selectedDate)
                fetchAverageSleepingHeartRate(for: selectedDate)
                fetchAverageSleepingHRV(for: selectedDate)
                fetchAverageSleepingBloodOxygen(for: selectedDate)
                fetchAverageRespiratoryRate(for: selectedDate)
                fetchRestingHeartRate(for: selectedDate)
            } else {
                print(
                    "HealthKit Authorization Error: \(error?.localizedDescription ?? "Unknown Error")"
                )
            }
        }
    }
    
    func fetchSleepData(for date: Date) {
        isLoading = true
        print("Fetching sleep data for date: \(date)")
        
        guard let healthStore = healthStore else {
            isLoading = false
            print("HealthKit not initialized.")
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                print("No sleep data found for the specified date.")
                DispatchQueue.main.async {
                    self.isLoading = false
                    if Calendar.current.isDateInToday(date) {
                        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                        print("Fetching sleep data for yesterday: \(yesterday)")
                        self.fetchSleepData(for: yesterday)
                    } else {
                        self.sleepData = []
                        self.updateSleepSummary()
                    }
                }
                return
            }
            
            print("Found \(samples.count) sleep samples.")
            
            let fetchedSleepData = samples.compactMap { sample -> SleepData? in
                guard let sleepStage = self.sleepStage(from: sample) else {
                    print("Could not determine sleep stage for sample: \(sample)")
                    return nil
                }
                let localStartDate = sample.startDate.toLocalTime()
                let localEndDate = sample.endDate.toLocalTime()
                
                print(
                    "Sleep sample: \(sample), sleepStage: \(sleepStage), localStartDate: \(localStartDate), localEndDate: \(localEndDate)"
                )
                return SleepData(
                    date: sample.startDate,
                    hour: Calendar.current.component(.hour, from: sample.startDate),
                    sleepStage: sleepStage,
                    duration: localEndDate.timeIntervalSince(localStartDate)
                )
            }
            
            DispatchQueue.main.async {
                self.sleepData = fetchedSleepData
                print("Fetched sleep data: \(self.sleepData)")
                self.isLoading = false
                self.updateSleepSummary()
                self.fetchHeartRateDip(for: date)
                self.fetchAverageSleepingHeartRate(for: date)
                self.fetchAverageSleepingHRV(for: date)
                self.fetchAverageSleepingBloodOxygen(for: date)
                self.fetchAverageRespiratoryRate(for: date)
                self.calculateSleepDebt()
                self.calculateSleepRegularity()
                self.calculateSocialJetLag()
            }
        }
        healthStore.execute(query)
    }
    
    func fetchHRVData(for date: Date) {
        guard let healthStore = healthStore else { return }
        
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let hrvSamples = samples as? [HKQuantitySample], error == nil else {
                print("Error fetching HRV data: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            
            let fetchedHRVData = hrvSamples.map { sample in
                HRVData(
                    date: sample.startDate.toLocalTime(),
                    value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                )
            }
            
            DispatchQueue.main.async {
                self.hrvData = fetchedHRVData
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
        print("Fetching average sleeping heart rate...")
        guard let healthStore = healthStore else {
            print("HealthKit not initialized.")
            averageSleepingHeartRate = "N/A - HealthKit Error"
            return
        }
        
        guard let sleepStart = sleepData.filter({ $0.sleepStage != 1 }).map({ $0.date }).min(),
              let sleepEnd = sleepData.filter({ $0.sleepStage != 1 }).map({
                  $0.date.addingTimeInterval($0.duration)
              }).max()
        else {
            print("Could not determine sleep period from sleep data.")
            DispatchQueue.main.async {
                self.averageSleepingHeartRate = "N/A - No Sleep Data"
            }
            return
        }
        
        print("Sleep period determined: \(sleepStart) to \(sleepEnd)")
        
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
                print("No heart rate samples found for the sleep period.")
                DispatchQueue.main.async {
                    self.averageSleepingHeartRate = "N/A - No HR Data"
                }
                return
            }
            
            print("Found \(hrSamples.count) heart rate samples.")
            
            let heartRates = hrSamples.map {
                $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
            let averageHeartRate = heartRates.reduce(0.0, +) / Double(heartRates.count)
            
            DispatchQueue.main.async {
                self.averageSleepingHeartRate = String(format: "%.0f bpm", averageHeartRate)
                print("Average sleeping heart rate: \(self.averageSleepingHeartRate)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchAverageSleepingHRV(for date: Date) {
        print("Fetching average sleeping HRV...")
        guard let healthStore = healthStore else {
            print("HealthKit not initialized.")
            averageSleepingHRV = "N/A - HealthKit Error"
            return
        }
        
        guard let sleepStart = sleepData.filter({ $0.sleepStage != 1 }).map({ $0.date }).min(),
              let sleepEnd = sleepData.filter({ $0.sleepStage != 1 }).map({
                  $0.date.addingTimeInterval($0.duration)
              }).max()
        else {
            print("Could not determine sleep period from sleep data.")
            DispatchQueue.main.async {
                self.averageSleepingHRV = "N/A - No Sleep Data"
            }
            return
        }
        
        print("Sleep period determined: \(sleepStart) to \(sleepEnd)")
        
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
                print("No HRV samples found for the sleep period.")
                DispatchQueue.main.async {
                    self.averageSleepingHRV = "N/A - No HRV Data"
                }
                return
            }
            
            print("Found \(hrvSamples.count) HRV samples.")
            
            let hrvValues = hrvSamples.map {
                $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }
            let averageHRV = hrvValues.reduce(0.0, +) / Double(hrvValues.count)
            
            DispatchQueue.main.async {
                self.averageSleepingHRV = String(format: "%.0f ms", averageHRV)
                print("Average sleeping HRV: \(self.averageSleepingHRV)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchAverageSleepingBloodOxygen(for date: Date) {
        print("Fetching average sleeping blood oxygen...")
        guard let healthStore = healthStore else {
            print("HealthKit not initialized.")
            averageSleepingBloodOxygen = "N/A - HealthKit Error"
            return
        }
        
        guard let sleepStart = sleepData.filter({ $0.sleepStage != 1 }).map({ $0.date }).min(),
              let sleepEnd = sleepData.filter({ $0.sleepStage != 1 }).map({
                  $0.date.addingTimeInterval($0.duration)
              }).max()
        else {
            print("Could not determine sleep period from sleep data.")
            DispatchQueue.main.async {
                self.averageSleepingBloodOxygen = "N/A - No Sleep Data"
            }
            return
        }
        
        print("Sleep period determined: \(sleepStart) to \(sleepEnd)")
        
        let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let predicate = HKQuery.predicateForSamples(
            withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: oxygenSaturationType, predicate: predicate, limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error = error {
                print("Error fetching blood oxygen samples: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.averageSleepingBloodOxygen = "N/A - Query Error"
                }
                return
            }
            
            guard let oxygenSamples = samples as? [HKQuantitySample], !oxygenSamples.isEmpty else {
                print("No blood oxygen samples found for the sleep period.")
                DispatchQueue.main.async {
                    self.averageSleepingBloodOxygen = "N/A - No O2 Data"
                }
                return
            }
            
            print("Found \(oxygenSamples.count) blood oxygen samples.")
            
            let oxygenValues = oxygenSamples.map { $0.quantity.doubleValue(for: HKUnit.percent()) }
            let averageOxygen = oxygenValues.reduce(0.0, +) / Double(oxygenValues.count)
            
            DispatchQueue.main.async {
                self.averageSleepingBloodOxygen = String(format: "%.1f%%", averageOxygen * 100)
                print("Average sleeping blood oxygen: \(self.averageSleepingBloodOxygen)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchAverageRespiratoryRate(for date: Date) {
        print("Fetching average respiratory rate during sleep for \(date)")
        
        guard let healthStore = healthStore else {
            print("HealthKit not initialized.")
            DispatchQueue.main.async {
                self.averageRespiratoryRate = "N/A - HealthKit Error"
            }
            return
        }
        
        guard
            let sleepStart =
                sleepData
                .filter({ [0, 2, 3, 4].contains($0.sleepStage) })
                .map({ $0.date })
                .min(),
            let sleepEnd =
                sleepData
                .filter({ [0, 2, 3, 4].contains($0.sleepStage) })
                .map({ $0.date.addingTimeInterval($0.duration) })
                .max()
        else {
            print("Could not determine sleep period from sleep data.")
            DispatchQueue.main.async {
                self.averageRespiratoryRate = "N/A - No Sleep Data"
            }
            return
        }
        
        print("Sleep period determined: \(sleepStart) to \(sleepEnd)")
        
        let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: respiratoryRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                DispatchQueue.main.async {
                    self.averageRespiratoryRate = "N/A - Query Error"
                }
                return
            }
            
            guard let respiratorySamples = samples as? [HKQuantitySample],
                  !respiratorySamples.isEmpty
            else {
                print("No respiratory rate samples found for the sleep period.")
                DispatchQueue.main.async {
                    self.averageRespiratoryRate = "N/A - No Data"
                }
                return
            }
            
            let rates = respiratorySamples.map {
                $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
            let averageRate = rates.reduce(0.0, +) / Double(rates.count)
            
            DispatchQueue.main.async {
                self.averageRespiratoryRate = String(format: "%.1f b/min", averageRate)
                print("Average respiratory rate: \(self.averageRespiratoryRate)")
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
        
        let sortedSleepData = sleepData.sorted { $0.date < $1.date }
        var interruptionsCount = 0
        
        if sortedSleepData.count >= 2 {
            for i in 1..<sortedSleepData.count {
                let prev = sortedSleepData[i - 1]
                let current = sortedSleepData[i]
                if [2, 3, 4].contains(prev.sleepStage) && current.sleepStage == 1 {
                    interruptionsCount += 1
                }
            }
        }
        
        sleepInterruptions = interruptionsCount
        
        var transitionsCount = 0
        if sortedSleepData.count >= 2 {
            for i in 1..<sortedSleepData.count {
                if sortedSleepData[i].sleepStage != sortedSleepData[i - 1].sleepStage {
                    transitionsCount += 1
                }
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
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate, end: endDate, options: .strictStartDate)
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
                if let firstSleep =
                    dailySamples
                    .sorted(by: { $0.startDate < $1.startDate })
                    .first(where: { [2, 3, 4].contains(self.sleepStage(from: $0) ?? -1) })
                {
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
                let diff = abs(
                    calendar.dateComponents([.minute], from: referenceTime, to: onsetTime).minute
                    ?? 0)
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
        let totalSleepSeconds = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }.reduce(0) {
            $0 + $1.duration
        }
        let stageSeconds = sleepData.filter { $0.sleepStage == stage }.reduce(0) {
            $0 + $1.duration
        }
        guard totalSleepSeconds > 0 else { return "0%" }
        let percentage = (stageSeconds / totalSleepSeconds) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    func calculateTotalSleepPercentage() -> CGFloat {
        let totalSleepSeconds = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }.reduce(0) {
            $0 + $1.duration
        }
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
    
    func calculateSleepQualityScore() {
        guard !sleepData.isEmpty else {
            sleepQualityScore = nil
            return
        }
        
        var score = 0
        let maxPossibleScore = 100
        
        let totalSleepSeconds = sleepData.filter { [2, 3, 4].contains($0.sleepStage) }.reduce(0) {
            $0 + $1.duration
        }
        let totalSleepHours = totalSleepSeconds / 3600
        
        if totalSleepHours >= 7 && totalSleepHours <= 9 {
            score += 30
        } else if totalSleepHours >= 6 && totalSleepHours < 7 {
            score += 20
        } else if totalSleepHours > 9 && totalSleepHours <= 10 {
            score += 20
        } else if totalSleepHours > 5 && totalSleepHours < 6 {
            score += 10
        } else {
            score += 5
        }
        
        if let sleepEfficiencyValue = Double(
            sleepEfficiency.replacingOccurrences(of: "%", with: ""))
        {
            if sleepEfficiencyValue >= 85 {
                score += 20
            } else if sleepEfficiencyValue >= 75 {
                score += 15
            } else if sleepEfficiencyValue >= 65 {
                score += 10
            } else {
                score += 5
            }
        }
        
        if let deepSleepPercentage = Double(
            calculateSleepStagePercentage(stage: 3).replacingOccurrences(of: "%", with: ""))
        {
            if deepSleepPercentage >= 13 && deepSleepPercentage <= 23 {
                score += 15
            } else if deepSleepPercentage > 23 {
                score += 10
            } else if deepSleepPercentage >= 10 && deepSleepPercentage < 13 {
                score += 5
            } else {
                score += 2
            }
        }
        
        if let remSleepPercentage = Double(
            calculateSleepStagePercentage(stage: 4).replacingOccurrences(of: "%", with: ""))
        {
            if remSleepPercentage >= 20 && remSleepPercentage <= 25 {
                score += 15
            } else if remSleepPercentage > 25 {
                score += 10
            } else if remSleepPercentage >= 15 && remSleepPercentage < 20 {
                score += 5
            } else {
                score += 2
            }
        }
        
        if let sleepConsistencyValue = Double(
            sleepConsistency.replacingOccurrences(of: "%", with: ""))
        {
            if sleepConsistencyValue >= 80 {
                score += 10
            } else if sleepConsistencyValue >= 60 {
                score += 5
            } else {
                score += 2
            }
        }
        
        if let heartRateDipValue = Double(heartRateDip.replacingOccurrences(of: "%", with: "")) {
            if heartRateDipValue >= 10 {
                score += 5
            } else {
                score += 2
            }
        }
        
        if let averageSleepingHRVValue = Double(
            averageSleepingHRV.replacingOccurrences(of: " ms", with: ""))
        {
            if averageSleepingHRVValue > 50 {
                score += 5
            } else if averageSleepingHRVValue > 30 {
                score += 2
            } else {
                score += 1
            }
        }
        score = max(0, score - sleepInterruptions)
        sleepQualityScore = min(maxPossibleScore, score)
        notificationManager.calculateAndSendSleepQualityNotification(for: sleepData, score: sleepQualityScore ?? 0)
    }
        
    struct SleepTrend: Identifiable {
        let id = UUID()
        let day: String
        let totalSleepHours: Double
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date, completion: @escaping ([SleepData]) -> Void) {
        guard let healthStore = healthStore else {
            completion([])
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                completion([])
                return
            }
            
            let sleepData = samples.compactMap { sample -> SleepData? in
                guard let sleepStage = self.sleepStage(from: sample) else { return nil }
                return SleepData(
                    date: sample.startDate.toLocalTime(),
                    hour: Calendar.current.component(.hour, from: sample.startDate),
                    sleepStage: sleepStage,
                    duration: sample.endDate.toLocalTime().timeIntervalSince(sample.startDate.toLocalTime())
                )
            }
            completion(sleepData)
        }
        healthStore.execute(query)
    }
    
    func calculateSleepDebt() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        fetchSleepData(from: sevenDaysAgo, to: today) { sleepData in
            let recommendedDailySleepSeconds: Double = 8 * 3600
            var totalSleepDebt: Double = 0
            
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: day, to: sevenDaysAgo) {
                    let sleepOnDate = sleepData.filter {
                        calendar.isDate($0.date, inSameDayAs: date)
                    }
                    let totalSleepSeconds = sleepOnDate.filter { [2, 3, 4].contains($0.sleepStage) }
                        .reduce(0) { $0 + $1.duration }
                    totalSleepDebt += recommendedDailySleepSeconds - totalSleepSeconds
                }
            }
            
            DispatchQueue.main.async {
                self.sleepDebt = String(format: "%.1f hrs", totalSleepDebt / 3600)
            }
        }
    }
    
    func calculateSleepRegularity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        fetchSleepData(from: sevenDaysAgo, to: today) { sleepData in
            var sleepMinutes = Array(repeating: 0, count: 1440 * 7)
            
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: day, to: sevenDaysAgo) {
                    let sleepOnDate = sleepData.filter {
                        calendar.isDate($0.date, inSameDayAs: date)
                    }
                    
                    for data in sleepOnDate where [2, 3, 4].contains(data.sleepStage) {
                        let startMinute =
                        calendar.component(.hour, from: data.date) * 60
                        + calendar.component(.minute, from: data.date)
                        let durationMinutes = Int(data.duration / 60)
                        
                        for i in 0..<durationMinutes {
                            let index = day * 1440 + startMinute + i
                            if index < sleepMinutes.count {
                                sleepMinutes[index] = 1
                            }
                        }
                    }
                }
            }
            
            var agreementCount = 0
            var totalComparisons = 0
            
            for day1 in 0..<6 {
                for day2 in (day1 + 1)..<7 {
                    for minute in 0..<1440 {
                        let index1 = day1 * 1440 + minute
                        let index2 = day2 * 1440 + minute
                        
                        if sleepMinutes[index1] == sleepMinutes[index2] {
                            agreementCount += 1
                        }
                        totalComparisons += 1
                    }
                }
            }
            
            let sri = totalComparisons > 0 ? Double(agreementCount) / Double(totalComparisons) * 100 : 0
            DispatchQueue.main.async {
                self.sleepRegularity = String(format: "%.1f%%", sri)
            }
        }
    }
    
    func calculateSocialJetLag() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        fetchSleepData(from: sevenDaysAgo, to: today) { sleepData in
            var weekdayMidpoints: [Double] = []
            var weekendMidpoints: [Double] = []
            
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: day, to: sevenDaysAgo) {
                    let sleepOnDate = sleepData.filter {
                        calendar.isDate($0.date, inSameDayAs: date)
                    }
                    
                    if let sleepStart = sleepOnDate.filter({ $0.sleepStage != 1 }).map({ $0.date }).min(),
                       let sleepEnd = sleepOnDate.filter({ $0.sleepStage != 1 }).map({ $0.date.addingTimeInterval($0.duration) }).max() {
                        let midpoint =
                        sleepStart.timeIntervalSince1970
                        + (sleepEnd.timeIntervalSince1970 - sleepStart.timeIntervalSince1970) / 2
                        let dayOfWeek = calendar.component(.weekday, from: date)
                        
                        if dayOfWeek >= 2 && dayOfWeek <= 6 {
                            weekdayMidpoints.append(midpoint)
                        } else {
                            weekendMidpoints.append(midpoint)
                        }
                    }
                }
            }
            let weekdayAvg =
            weekdayMidpoints.isEmpty
            ? 0 : weekdayMidpoints.reduce(0, +) / Double(weekdayMidpoints.count)
            let weekendAvg =
            weekendMidpoints.isEmpty
            ? 0 : weekendMidpoints.reduce(0, +) / Double(weekendMidpoints.count)
            let jetLag = abs(weekdayAvg - weekendAvg) / 3600
            
            DispatchQueue.main.async {
                self.socialJetLag = String(format: "%.1f hrs", jetLag)
            }
        }
    }
    
    func fetchRestingHeartRate(for date: Date) {
        guard let healthStore = healthStore else {
            DispatchQueue.main.async {
                self.averageRestingHeartRate = "N/A"
            }
            return
        }

        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: restingHeartRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching resting heart rate: \(error.localizedDescription)")
                    self.averageRestingHeartRate = "N/A - Query Error"
                    return
                }

                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    print("No resting heart rate samples found for \(date).")
                    self.averageRestingHeartRate = "N/A - No Data"
                    return
                }

                print("Found \(samples.count) resting heart rate samples.")

                // Get the most recent sample
                if let recentSample = samples.first {
                    let restingHeartRateValue = recentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    self.averageRestingHeartRate = String(format: "%.0f bpm", restingHeartRateValue)
                    print("Resting heart rate: \(restingHeartRateValue) bpm, Date: \(recentSample.startDate)")
                } else {
                    self.averageRestingHeartRate = "N/A"
                }
            }
        }

        healthStore.execute(query)
    }
    }

    private func calculateAverage(values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }
