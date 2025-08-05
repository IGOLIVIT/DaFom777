//
//  OnboardingViewModel.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation
import SwiftUI
import UserNotifications

class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var isCompleted = false
    @Published var userName = ""
    @Published var userRole: UserRole = .member
    @Published var hasRequestedNotifications = false
    @Published var notificationPermissionGranted = false
    @Published var hasRequestedCalendarAccess = false
    @Published var calendarPermissionGranted = false
    @Published var selectedPreferences: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let totalSteps = 4
    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "taskmaster_onboarding_completed"
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 0: return true // Welcome screen
        case 1: return true // Feature carousel
        case 2: return hasRequestedNotifications // Permissions
        case 3: return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty // Setup
        default: return false
        }
    }
    
    init() {
        checkOnboardingStatus()
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard canProceed else { return }
        
        if currentStep < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    func previousStep() {
        guard currentStep > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
    
    func skipOnboarding() {
        completeOnboarding()
    }
    
    // MARK: - Permissions
    
    @MainActor
    func requestNotificationPermission() async {
        hasRequestedNotifications = true
        isLoading = true
        
        do {
            let granted = await NotificationService.shared.requestAuthorization()
            notificationPermissionGranted = granted
            
            if granted {
                // Schedule daily summary notification
                NotificationService.shared.scheduleDailySummary()
            }
        } catch {
            errorMessage = "Failed to request notification permission"
        }
        
        isLoading = false
    }
    
    func requestCalendarAccess() {
        hasRequestedCalendarAccess = true
        // In a real app, you would request calendar access here
        // For now, we'll simulate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.calendarPermissionGranted = true
        }
    }
    
    // MARK: - User Setup
    
    func togglePreference(_ preference: String) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }
    
    func createUserProfile() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }
        
        // Create user preferences based on selections
        var preferences = UserPreferences()
        preferences.notificationsEnabled = notificationPermissionGranted
        preferences.taskReminders = selectedPreferences.contains("reminders")
        preferences.weeklyReports = selectedPreferences.contains("reports")
        preferences.preferredView = selectedPreferences.contains("kanban") ? "kanban" : "dashboard"
        
        // In a real app, you would save this to your backend or persistent storage
        let userData: [String: Any] = [
            "name": trimmedName,
            "role": userRole.rawValue,
            "preferences": try? JSONEncoder().encode(preferences),
            "onboardingCompleted": true,
            "completedDate": Date()
        ]
        
        // Save to UserDefaults for demo purposes
        for (key, value) in userData {
            if let data = value as? Data {
                userDefaults.set(data, forKey: "user_\(key)")
            } else {
                userDefaults.set(value, forKey: "user_\(key)")
            }
        }
        
        completeOnboarding()
    }
    
    // MARK: - Completion
    
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isCompleted = true
        }
        
        userDefaults.set(true, forKey: onboardingCompletedKey)
        userDefaults.set(Date(), forKey: "user_onboarding_date")
        
        // Add slight delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // In a real app, you might want to trigger analytics event here
            print("Onboarding completed for user: \(self.userName)")
        }
    }
    
    private func checkOnboardingStatus() {
        isCompleted = userDefaults.bool(forKey: onboardingCompletedKey)
    }
    
    // MARK: - Feature Data
    
    struct OnboardingFeature {
        let title: String
        let description: String
        let imageName: String
        let benefits: [String]
    }
    
    let features: [OnboardingFeature] = [
        OnboardingFeature(
            title: "Task Prioritization AI",
            description: "Smart algorithms analyze your tasks and suggest optimal prioritization based on deadlines, complexity, and your work patterns.",
            imageName: "brain.head.profile",
            benefits: [
                "Automatic priority suggestions",
                "Deadline-aware scheduling",
                "Workload optimization",
                "Focus improvement"
            ]
        ),
        OnboardingFeature(
            title: "Dynamic Workflows",
            description: "Customizable automation that adapts to your project needs and team dynamics for seamless project management.",
            imageName: "flowchart.fill",
            benefits: [
                "Automated task routing",
                "Smart team assignments",
                "Progress tracking",
                "Workflow optimization"
            ]
        ),
        OnboardingFeature(
            title: "Team Collaboration Hub",
            description: "Built-in real-time messaging and file sharing keeps all team communication organized and accessible.",
            imageName: "person.3.fill",
            benefits: [
                "Real-time messaging",
                "File sharing",
                "Team notifications",
                "Centralized communication"
            ]
        ),
        OnboardingFeature(
            title: "Productivity Insights",
            description: "Detailed analytics provide actionable insights into team efficiency and help improve decision-making.",
            imageName: "chart.line.uptrend.xyaxis",
            benefits: [
                "Performance analytics",
                "Time tracking insights",
                "Team efficiency metrics",
                "Actionable recommendations"
            ]
        )
    ]
    
    let availablePreferences = [
        ("reminders", "Task Reminders", "bell.fill", "Get notified about upcoming deadlines"),
        ("reports", "Weekly Reports", "doc.text.fill", "Receive productivity summaries"),
        ("kanban", "Kanban View", "rectangle.3.offgrid.fill", "Prefer board-style task management"),
        ("darkmode", "Dark Mode", "moon.fill", "Use dark theme by default"),
        ("analytics", "Analytics", "chart.bar.fill", "Enable detailed productivity tracking")
    ]
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case features = 1
    case permissions = 2
    case setup = 3
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to TaskMaster Pro"
        case .features: return "Powerful Features"
        case .permissions: return "Enable Notifications"
        case .setup: return "Setup Your Profile"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "Professional task and project management designed for business teams"
        case .features: return "Discover what makes TaskMaster Pro unique"
        case .permissions: return "Stay updated with your tasks and deadlines"
        case .setup: return "Tell us a bit about yourself"
        }
    }
}