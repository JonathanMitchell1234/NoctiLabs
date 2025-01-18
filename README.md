# SleepTrack



# Sleep Dashboard Documentation

This document provides an overview and explanation of the `SleepDashboardView` and its related components in a SwiftUI application designed to analyze and display sleep data from HealthKit.

## Table of Contents

1.  [Extensions](#extensions)
    *   [SleepData: Equatable](#sleepdata-equatable)
    *   [Date Extension](#date-extension)
2.  [SleepData Struct](#sleepdata-struct)
    *   [Properties](#sleepdata-properties)
    *   [Computed Properties](#sleepdata-computed-properties)
3.  [SleepDashboardView Struct](#sleepdashboardview-struct)
    *   [Properties](#sleepdashboardview-properties)
    *   [Computed Properties](#sleepdashboardview-computed-properties)
    *   [Body](#body)
    *   [Helper Functions](#helper-functions)
4.  [Helper Views](#helper-views)
    *   [CircularProgressView](#circularprogressview)
    *   [StatView](#statview)
    *   [AreaChartView](#areachartview)
    *   [HRVLineChartView](#hrvlinechartview)
    *   [SleepStageDistributionView](#sleepstagedistributionview)
    *   [PopoverTextView](#popovertextview)

## Extensions

### SleepData: Equatable

This extension makes `SleepData` conform to the `Equatable` protocol, allowing for comparisons between instances.

```swift
extension SleepData: Equatable {
    static func == (lhs: SleepData, rhs: SleepData) -> Bool {
        return lhs.id == rhs.id && 
               lhs.date == rhs.date &&
               lhs.hour == rhs.hour &&
               lhs.sleepStage == rhs.sleepStage &&
               lhs.duration == rhs.duration
    }
}

**Explanation:**

-   Two `SleepData` instances are considered equal if their `id`, `date`, `hour`, `sleepStage`, and `duration` properties are equal.

### Date Extension

This extension adds a method to convert a `Date` object to the current time zone.

Swift

```
extension Date {
    func toLocalTime() -> Date {
        let timeZone = TimeZone.current
        let seconds = TimeInterval(timeZone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}

```

**Explanation:**

-   `toLocalTime()`: Converts the date to the local time zone by adding or subtracting the difference in seconds between the current time zone and GMT.

## SleepData Struct

Represents a single data point for sleep analysis.

Swift

```
struct SleepData: Identifiable {
    let id = UUID()
    let date: Date
    let hour: Int
    let sleepStage: Int
    let duration: TimeInterval
    
    var sleepStageName: String { ... }
}

```

### SleepData Properties

-   `id`: A unique `UUID` to conform to `Identifiable`.
-   `date`: The `Date` of the sleep data point.
-   `hour`: The hour of the day (0-23) for the sleep data point.
-   `sleepStage`: An integer representing the sleep stage (0: In Bed, 1: Awake, 2: Light, 3: Deep, 4: REM).
-   `duration`: The duration of the sleep stage in seconds.

### SleepData Computed Properties

-   `sleepStageName`: Returns a string representation of the `sleepStage`.

Swift

```
var sleepStageName: String {
    switch sleepStage {
    case 0: return "In Bed"
    case 1: return "Awake"
    case 2: return "Light"
    case 3: return "Deep"
    case 4: return "REM"
    default: return "Unknown"
    }
}

```

## SleepDashboardView Struct

The main view that displays the sleep analysis dashboard.

Swift

```
struct SleepDashboardView: View {
    // ... properties ...

    var body: some View { ... }

    // ... helper functions ...
}

```

### SleepDashboardView Properties

-   `@State private var selectedDate: Date`: The currently selected date for analysis.
-   `@State private var sleepData: [SleepData]`: An array of `SleepData` for the selected date.
-   `@State private var healthStore: HKHealthStore?`: An instance of `HKHealthStore` to access HealthKit data.
-   `@State private var isLoading: Bool`: Indicates whether data is currently being loaded.
-   `@State private var totalSleep: String`: String representation of the total sleep time.
-   `@State private var deepSleep: String`: String representation of deep sleep time.
-   `@State private var remSleep: String`: String representation of REM sleep time.
-   `@State private var lightSleep: String`: String representation of light sleep time.
-   `@State private var averageSleepOnset: String`: String representation of average sleep onset time.
-   `@State private var sleepConsistency: String`: String representation of sleep consistency.
-   `@State private var sleepEfficiency: String`: String representation of sleep efficiency.
-   `@State private var timeInBed: String`: String representation of total time in bed.
-   `@State private var heartRateDip: String`: String representation of the average heart rate dip during sleep.
-   `@State private var sleepInterruptions: Int`: The number of sleep interruptions.
-   `@State private var sleepStageTransitions: Int`: The number of transitions between sleep stages.
-   `@State private var hrvData: [HRVData]`: Array of heart rate variability data.
-   `@State private var averageSleepingHeartRate: String`: String representation of average sleeping heart rate.
-   `@State private var averageSleepingHRV: String`: String representation of average sleeping heart rate variability.
-   `@State private var averageSleepingBloodOxygen: String`: String representation of average sleeping blood oxygen saturation.
-   `@State private var averageRespiratoryRate: String`: String representation of average respiratory rate during sleep.
-   `@State private var sleepQualityScore: Int?`: Calculated sleep quality score.
-   `@State private var notificationManager: SleepNotificationManager`: Manager for handling sleep related notifications.
-   `let columns: [GridItem]`: Defines the layout for the `LazyVGrid`.
-   `@State private var deepSleepPopover: Bool`: Controls the visibility of the deep sleep popover.
-   `@State private var remSleepPopover: Bool`: Controls the visibility of the REM sleep popover.
-   `@State private var lightSleepPopover: Bool`: Controls the visibility of the light sleep popover.
-   `@State private var sleepOnsetPopover: Bool`: Controls the visibility of the sleep onset popover.
-   `@State private var sleepEfficiencyPopover: Bool`: Controls the visibility of the sleep efficiency popover.
-   `@State private var timeInBedPopover: Bool`: Controls the visibility of the time in bed popover.
-   `@State private var sleepConsistencyPopover: Bool`: Controls the visibility of the sleep consistency popover.
-   `@State private var heartRateDipPopover: Bool`: Controls the visibility of the heart rate dip popover.
-   `@State private var interruptionsPopover: Bool`: Controls the visibility of the sleep interruptions popover.
-   `@State private var transitionsPopover: Bool`: Controls the visibility of the sleep stage transitions popover.
-   `@State private var averageRespiratoryRatePopover: Bool`: Controls the visibility of the average respiratory rate popover.
-   `@State private var averageSleepingHeartRatePopover: Bool`: Controls the visibility of the average sleeping heart rate popover.
-   `@State private var averageSleepingHRVPopover: Bool`: Controls the visibility of the average sleeping HRV popover.
-   `@State private var averageSleepingBloodOxygenPopover: Bool`: Controls the visibility of the average sleeping blood oxygen popover.

### SleepDashboardView Computed Properties

-   None explicitly defined in this code snippet.

### Body

The `body` of `SleepDashboardView` constructs the UI using various SwiftUI components, including:

-   `NavigationView`: Provides a navigation bar.
-   `ScrollView`: Allows scrolling of the content.
-   `VStack`: Arranges views vertically.
-   `DatePicker`: Allows selection of a date.
-   `HStack`: Arranges views horizontally.
-   `CircularProgressView`: Displays circular progress indicators.
-   `AreaChartView`: Displays sleep data as an area chart.
-   `HRVLineChartView`: Displays HRV data as a line chart.
-   `SleepStageDistributionView`: Displays the distribution of sleep stages.
-   `LazyVGrid`: Arranges views in a grid layout.
-   `StatView`: Displays individual sleep statistics.
-   `AudioPlayerView`: Placeholder for an audio player.
-   `.navigationTitle`: Sets the title of the navigation bar.
-   `.preferredColorScheme`: Sets the color scheme to dark.
-   `.onAppear`: Executes code when the view appears.
-   `.onChange`: Executes code when a specified value changes.

**Key UI Elements and Interactions:**

1.  **Date Picker:** Selects the date for which to display sleep data. The `onChange` modifier triggers `fetchSleepData`, `fetchHRVData` when the date changes.
2.  **Circular Progress Views:** Show total sleep time, sleep quality and 3-day sleep target.
3.  **Area Chart:** Visualizes sleep stages over time.
4.  **HRV Line Chart:** Visualizes heart rate variability over time.
5.  **Sleep Stage Distribution Chart:** Shows the proportion of time spent in each sleep stage.
6.  **Grid of Statistics:** Presents key sleep metrics like deep sleep, REM sleep, light sleep, sleep onset, sleep efficiency, time in bed, sleep consistency, heart rate dip, sleep interruptions, and sleep stage transitions. Each `StatView` has a tap gesture that triggers a popover (`PopoverTextView`) with more information.
7.  **Audio Player:** A placeholder for audio playback functionality.
8.  **Navigation Title:** Sets the title of the view to "Sleep Dashboard".
9.  **Color Scheme:** Forces the view to use a dark color scheme.

### Helper Functions

-   `checkHealthKitAuthorization()`: Requests authorization to access HealthKit data.
-   `fetchSleepData(for:)`: Fetches sleep data from HealthKit for the specified date.
-   `fetchHRVData(for:)`: Fetches HRV data from HealthKit for the specified date.
-   `fetchHeartRateDip(for:)`: Calculates the average heart rate dip during sleep for the specified date.
-   `fetchAverageSleepingHeartRate(for:)`: Calculates the average sleeping heart rate for the specified date.
-   `fetchAverageSleepingHRV(for:)`: Calculates the average sleeping HRV for the specified date.
-   `fetchAverageSleepingBloodOxygen(for:)`: Calculates the average sleeping blood oxygen for the specified date.
-   `fetchAverageRespiratoryRate(for:)`: Calculates the average respiratory rate during sleep for the specified date.
-   `sleepStage(from:)`: Converts an `HKCategorySample` value to an integer representing the sleep stage.
-   `updateSleepSummary()`: Updates the state variables with calculated sleep metrics.
-   `calculateSleepConsistency(for:)`: Calculates sleep consistency over the past 7 days.
-   `calculateSleepStagePercentage(stage:)`: Calculates the percentage of time spent in a specific sleep stage.
-   `calculateTotalSleepPercentage()`: Calculates the percentage of the sleep goal achieved.
-   `formatTimeInterval(seconds:)`: Formats a time interval in seconds to a "hh mm" string.
-   `calculateSleepQualityScore()`: Calculates the overall sleep quality score based on various metrics.

## Helper Views

### CircularProgressView

Displays a circular progress indicator with a title and value.

Swift

```
struct CircularProgressView: View {
    let percentage: CGFloat
    let title: String
    let value: String

    var body: some View { ... }
}

```

**Properties:**

-   `percentage`: The progress percentage (0.0 to 1.0).
-   `title`: The title of the progress indicator.
-   `value`: The value to display.

### StatView

Displays a single statistic with an optional icon, value, percentage, and description.

Swift

```
struct StatView: View {
    let title: String
    let value: String
    let percentage: String?
    let description: String?
    let icon: String?

    var body: some View { ... }
}

```

**Properties:**

-   `title`: The title of the statistic.
-   `value`: The value of the statistic.
-   `percentage`: The optional percentage value.
-   `description`: The optional description of the statistic.
-   `icon`: The optional icon to display.

### AreaChartView

Displays sleep stages as an area chart.

Swift

```
struct AreaChartView: View {
    let sleepData: [SleepData]

    var body: some View { ... }
}

```

**Properties:**

-   `sleepData`: The array of `SleepData` to display.

**Computed Properties:**

-   `startOfDay`: The start of the day for the x-axis.
-   `endOfDay`: The end of the day for the x-axis.
-   `next12Hours`: Array of dates representing every 2-hour interval from the start hour of the first data point.

**Helper Functions:**

-   `formatTime(from:)`: Formats a date to display the hour and AM/PM.
-   `minDuration(for:)`: Returns the minimum y-value (always 0 in this case).
-   `maxDuration(for:)`: Returns the maximum y-value based on the data point's duration.
-   `maxDuration()`: Returns the maximum duration among all data points, or 1.0 if the array is empty.

### HRVLineChartView

Displays HRV data as a line chart.

Swift

```
struct HRVLineChartView: View {
    let hrvData: [HRVData]
    let sleepData: [SleepData]

    var body: some View { ... }
}

```

**Properties:**

-   `hrvData`: The array of `HRVData` to display.
-   `sleepData`: The array of `SleepData` used to filter HRV data based on sleep time.

**Computed Properties:**

-   `filteredHRVData`: Filters `hrvData` to include only data points within the sleep period.
-   `xDomain`: The domain for the x-axis, based on sleep start and end times.
-   `sleepStartTime`: The start time of sleep.
-   `sleepEndTime`: The end time of sleep.

### SleepStageDistributionView

Displays the distribution of sleep stages as a bar chart.

Swift

```
struct SleepStageDistributionView: View {
    let sleepData: [SleepData]

    var body: some View { ... }
}

```

**Properties:**

-   `sleepData`: The array of `SleepData` to use for calculating the distribution.

**Computed Properties:**

-   `sleepStageDistribution`: An array of `SleepStage` structs representing the distribution of each sleep stage.

**Helper Functions:**

-   `colorForSleepStage(_:)`: Returns the color associated with a specific sleep stage.

### PopoverTextView

Displays a popover with a title and content text.

Swift

```
struct PopoverTextView: View {
    let title: String
    let content: String

    var body: some View { ... }
}

```

**Properties:**

-   `title`: The title of the popover.
-   `content`: The content text of the popover.