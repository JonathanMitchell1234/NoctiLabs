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
        print("calculateAndSendSleepQualityNotification called")
        print("Sleep Data: \(sleepData)")
        print("Sleep Quality Score: \(score)")
        scheduleNotification(with: score)
    }


    private func scheduleNotification(with score: Int) {
        let content = UNMutableNotificationContent()
        print("Scheduling notification with score: \(score)")
        content.title = "Your Sleep Quality Score"
        content.body = "Last night's sleep quality score is \(score) out of 100."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "sleepQualityCategory"

        // Schedule the notification for 12:44 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 13
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "sleepQualityNotification", content: content, trigger: trigger)

        //        print("Notification request: \(request)")

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
