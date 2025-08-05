//
//  SettingsView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("user_name") private var userName = "John Doe"
    @AppStorage("user_role") private var userRole = "Manager"
    @State private var notificationsEnabled = true
    @State private var emailNotifications = true
    @State private var pushNotifications = true
    @State private var taskReminders = true
    @State private var weeklyReports = true
    @State private var darkMode = true
    @State private var preferredView = "Dashboard"
    @State private var workingHoursStart = Date()
    @State private var workingHoursEnd = Date()
    @State private var showingAbout = false
    @State private var showingExportData = false
    @State private var showingDeleteData = false
    
    private let viewOptions = ["Dashboard", "Kanban", "Calendar"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                List {
                    // Profile Section
                    ProfileSection(userName: userName, userRole: userRole)
                    
                    // Preferences Section
                    PreferencesSection(
                        preferredView: $preferredView,
                        viewOptions: viewOptions,
                        darkMode: $darkMode
                    )
                    
                    // Notifications Section
                    NotificationsSection(
                        notificationsEnabled: $notificationsEnabled,
                        emailNotifications: $emailNotifications,
                        pushNotifications: $pushNotifications,
                        taskReminders: $taskReminders,
                        weeklyReports: $weeklyReports
                    )
                    
                    // Working Hours Section
                    WorkingHoursSection(
                        workingHoursStart: $workingHoursStart,
                        workingHoursEnd: $workingHoursEnd
                    )
                    
                    // Data & Privacy Section
                    DataPrivacySection(
                        showingExportData: $showingExportData,
                        showingDeleteData: $showingDeleteData
                    )
                    
                    // About Section
                    AboutSection(showingAbout: $showingAbout)
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showingDeleteData
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your tasks, projects, and settings. This action cannot be undone.")
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        // Setup initial working hours
        let calendar = Calendar.current
        workingHoursStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        workingHoursEnd = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    private func deleteAllData() {
        // In a real app, this would clear all user data
        UserDefaults.standard.removeObject(forKey: "taskmaster_tasks")
        UserDefaults.standard.removeObject(forKey: "taskmaster_projects")
        UserDefaults.standard.removeObject(forKey: "taskmaster_onboarding_completed")
        
        // Show confirmation
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
}

// MARK: - Profile Section

struct ProfileSection: View {
    let userName: String
    let userRole: String
    
    var body: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(userName.initials)
                            .font(.title2.bold())
                            .foregroundColor(.black)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(userRole)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.appSuccess)
                            .frame(width: 8, height: 8)
                        
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.appSuccess)
                    }
                }
                
                Spacer()
                
                Button("Edit") {
                    // Navigate to profile editing
                }
                .foregroundColor(.appAccent)
                .font(.subheadline)
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - Preferences Section

struct PreferencesSection: View {
    @Binding var preferredView: String
    let viewOptions: [String]
    @Binding var darkMode: Bool
    
    var body: some View {
        Section("Preferences") {
            // Preferred View
            HStack {
                Label("Default View", systemImage: "rectangle.stack")
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    ForEach(viewOptions, id: \.self) { option in
                        Button(option) {
                            preferredView = option
                        }
                    }
                } label: {
                    HStack {
                        Text(preferredView)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Dark Mode
            HStack {
                Label("Dark Mode", systemImage: "moon.fill")
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $darkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .appAccent))
            }
            .padding(.vertical, 4)
            
            // Language
            HStack {
                Label("Language", systemImage: "globe")
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("English")
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - Notifications Section

struct NotificationsSection: View {
    @Binding var notificationsEnabled: Bool
    @Binding var emailNotifications: Bool
    @Binding var pushNotifications: Bool
    @Binding var taskReminders: Bool
    @Binding var weeklyReports: Bool
    
    var body: some View {
        Section("Notifications") {
            // Master Toggle
            HStack {
                Label("Enable Notifications", systemImage: "bell")
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .appAccent))
            }
            .padding(.vertical, 4)
            
            if notificationsEnabled {
                // Email Notifications
                HStack {
                    Label("Email Notifications", systemImage: "envelope")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $emailNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                }
                .padding(.vertical, 4)
                
                // Push Notifications
                HStack {
                    Label("Push Notifications", systemImage: "iphone")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $pushNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                }
                .padding(.vertical, 4)
                
                // Task Reminders
                HStack {
                    Label("Task Reminders", systemImage: "alarm")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $taskReminders)
                        .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                }
                .padding(.vertical, 4)
                
                // Weekly Reports
                HStack {
                    Label("Weekly Reports", systemImage: "chart.bar")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $weeklyReports)
                        .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - Working Hours Section

struct WorkingHoursSection: View {
    @Binding var workingHoursStart: Date
    @Binding var workingHoursEnd: Date
    
    var body: some View {
        Section("Working Hours") {
            // Start Time
            HStack {
                Label("Start Time", systemImage: "sunrise")
                    .foregroundColor(.white)
                
                Spacer()
                
                DatePicker("", selection: $workingHoursStart, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .accentColor(.appAccent)
            }
            .padding(.vertical, 4)
            
            // End Time
            HStack {
                Label("End Time", systemImage: "sunset")
                    .foregroundColor(.white)
                
                Spacer()
                
                DatePicker("", selection: $workingHoursEnd, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .accentColor(.appAccent)
            }
            .padding(.vertical, 4)
            
            // Time Zone
            HStack {
                Label("Time Zone", systemImage: "clock")
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(TimeZone.current.localizedName(for: .standard, locale: .current) ?? "Local")
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - Data & Privacy Section

struct DataPrivacySection: View {
    @Binding var showingExportData: Bool
    @Binding var showingDeleteData: Bool
    
    var body: some View {
        Section("Data & Privacy") {
            // Export Data
            Button {
                showingExportData = true
            } label: {
                HStack {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            
            // Storage Usage
            HStack {
                Label("Storage Used", systemImage: "internaldrive")
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("2.4 MB")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            // Delete All Data
            Button {
                showingDeleteData = true
            } label: {
                HStack {
                    Label("Delete All Data", systemImage: "trash")
                        .foregroundColor(.appDanger)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - About Section

struct AboutSection: View {
    @Binding var showingAbout: Bool
    
    var body: some View {
        Section("About") {
            // Version
            HStack {
                Label("Version", systemImage: "info.circle")
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            // About App
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Label("About TaskMaster Pro", systemImage: "questionmark.circle")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            
            // Support
            Button {
                // Open support URL or email
            } label: {
                HStack {
                    Label("Support & Feedback", systemImage: "envelope")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            
            // Privacy Policy
            Button {
                // Open privacy policy
            } label: {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - Supporting Views

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [.appAccent, .appSuccess],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "checkmark.square.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.black)
                            )
                        
                        VStack(spacing: 8) {
                            Text("TaskMaster Pro")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("TaskMaster Pro is a comprehensive task and project management application designed for business professionals and teams. It combines AI-powered prioritization, dynamic workflows, and team collaboration features to help you stay productive and organized.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Features")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            FeatureRow(icon: "brain.head.profile", title: "AI-Powered Prioritization", description: "Smart task prioritization based on deadlines and complexity")
                            FeatureRow(icon: "flowchart.fill", title: "Dynamic Workflows", description: "Customizable automation for seamless project management")
                            FeatureRow(icon: "person.3.fill", title: "Team Collaboration", description: "Real-time messaging and file sharing capabilities")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Productivity Insights", description: "Detailed analytics and performance metrics")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        Text("© 2025 TaskMaster Pro. All rights reserved.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportComplete = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(.appAccent)
                    
                    VStack(spacing: 8) {
                        Text("Export Your Data")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Download all your tasks, projects, and settings as a JSON file.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your export will include:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ExportItem(text: "All tasks and subtasks")
                        ExportItem(text: "Project information")
                        ExportItem(text: "User preferences and settings")
                        ExportItem(text: "Time tracking data")
                        ExportItem(text: "Analytics and insights")
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    if exportComplete {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.appSuccess)
                            
                            Text("Export Complete!")
                                .font(.headline)
                                .foregroundColor(.appSuccess)
                            
                            Text("Your data has been exported successfully.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            exportData()
                        } label: {
                            if isExporting {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                    Text("Exporting...")
                                        .foregroundColor(.black)
                                }
                            } else {
                                Text("Export Data")
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .cornerRadius(12)
                        .disabled(isExporting)
                    }
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.appAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            exportComplete = true
            
            // In a real app, you would generate and share the actual file
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

struct ExportItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appSuccess)
                .font(.caption)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}