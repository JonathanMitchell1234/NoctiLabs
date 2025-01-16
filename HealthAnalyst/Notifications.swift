//
//  Notifications.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/16/25.
//

import UserNotifications
import HealthKit

class SleepNotificationManager: NSObject, UNUserNotificationCenterDelegate {

    private let healthStore: HKHealthStore?

    init(healthStore: HKHealthStore?) {
        self.healthStore = healthStore
    }

    func calculateAndSendSleepQualityNotification(for sleepData: [SleepData], score: Int) {
        scheduleNotification(with: score)
    }

    private func scheduleNotification(with score: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your Sleep Quality Score"
        content.body = "Last night's sleep quality score is \(score) out of 100."
        content.sound = UNNotificationSound.default

        // Trigger after a time interval (e.g., 5 seconds from now for testing)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "sleepQualityNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully!")
            }
        }
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted.")
            } else if let error = error {
                print("Error requesting notifications permissions: \(error)")
            }
        }
    }

    // Optional: Implement delegate methods to handle notification responses
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
