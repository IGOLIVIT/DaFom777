//
//  NotificationService.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Task Notifications
    
    func scheduleTaskReminder(for task: TaskItem, at date: Date) {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        
        // Add action buttons
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "Mark Complete",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: "Snooze 1 Hour",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "TASK_REMINDER"
        
        // Schedule for 1 hour before due date
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: date) ?? date
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelTaskReminder(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(task.id.uuidString)"]
        )
    }
    
    // MARK: - Daily Summary Notifications
    
    func scheduleDailySummary() {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Task Summary"
        content.body = "Check your daily progress and upcoming tasks"
        content.sound = .default
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily summary: \(error)")
            }
        }
    }
    
    // MARK: - Project Deadline Notifications
    
    func scheduleProjectDeadlineReminder(for project: Project) {
        guard authorizationStatus == .authorized,
              let deadline = project.deadline else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Project Deadline Approaching"
        content.body = "\(project.name) is due soon"
        content.sound = .default
        
        // Schedule for 24 hours before deadline
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: deadline) ?? deadline
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "project_\(project.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule project notification: \(error)")
            }
        }
    }
    
    func cancelProjectDeadlineReminder(for project: Project) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["project_\(project.id.uuidString)"]
        )
    }
    
    // MARK: - Team Notifications
    
    func sendTeamNotification(title: String, message: String, teamMembers: [UUID]) {
        // In a real app, this would send push notifications to team members
        // For now, we'll just schedule a local notification
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "team_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send team notification: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        switch response.actionIdentifier {
        case "COMPLETE_TASK":
            // Handle task completion
            if let taskId = extractTaskId(from: identifier) {
                handleTaskCompletion(taskId: taskId)
            }
            
        case "SNOOZE_TASK":
            // Handle task snoozing
            if let taskId = extractTaskId(from: identifier) {
                handleTaskSnooze(taskId: taskId)
            }
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    private func extractTaskId(from identifier: String) -> UUID? {
        if identifier.hasPrefix("task_") {
            let uuidString = String(identifier.dropFirst(5))
            return UUID(uuidString: uuidString)
        }
        return nil
    }
    
    private func handleTaskCompletion(taskId: UUID) {
        // In a real app, you would update the task status
        print("Completing task: \(taskId)")
    }
    
    private func handleTaskSnooze(taskId: UUID) {
        // In a real app, you would reschedule the notification
        print("Snoozing task: \(taskId)")
    }
}