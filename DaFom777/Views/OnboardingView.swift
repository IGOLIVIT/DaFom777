//
//  OnboardingView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                    .scaleEffect(y: 2)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView(viewModel: viewModel)
                        .tag(0)
                    
                    FeaturesStepView(viewModel: viewModel)
                        .tag(1)
                    
                    PermissionsStepView(viewModel: viewModel)
                        .tag(2)
                    
                    SetupStepView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // Navigation Controls
                HStack {
                    if viewModel.currentStep > 0 {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .secondaryButtonStyle()
                    } else {
                        Button("Skip") {
                            viewModel.skipOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(viewModel.currentStep == 3 ? "Get Started" : "Next") {
                        if viewModel.currentStep == 3 {
                            viewModel.createUserProfile()
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(!viewModel.canProceed)
                    .opacity(viewModel.canProceed ? 1.0 : 0.6)
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.isCompleted) { completed in
            if completed {
                dismiss()
            }
        }
        .errorAlert(
            isPresented: .constant(viewModel.errorMessage != nil),
            message: viewModel.errorMessage ?? ""
        )
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon/Logo
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [.appAccent, .appSuccess],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                )
                .shadow(color: .appAccent.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("TaskMaster Pro")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Professional task and project management designed for business teams")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                FeatureBadge(icon: "brain.head.profile", text: "AI-Powered Prioritization")
                FeatureBadge(icon: "flowchart.fill", text: "Dynamic Workflows")
                FeatureBadge(icon: "person.3.fill", text: "Team Collaboration")
                FeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Productivity Insights")
            }
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appAccent)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Features Step

struct FeaturesStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var currentFeature = 0
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Powerful Features")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Discover what makes TaskMaster Pro unique")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            TabView(selection: $currentFeature) {
                ForEach(Array(viewModel.features.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 400)
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<viewModel.features.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentFeature ? Color.appAccent : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentFeature ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentFeature)
                }
            }
            .padding(.bottom)
        }
        .padding()
    }
}

struct FeatureCard: View {
    let feature: OnboardingViewModel.OnboardingFeature
    
    var body: some View {
        VStack(spacing: 20) {
            // Feature Icon
            Image(systemName: feature.imageName)
                .font(.system(size: 60))
                .foregroundColor(.appAccent)
                .frame(height: 80)
            
            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            VStack(spacing: 8) {
                ForEach(feature.benefits, id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appSuccess)
                            .font(.caption)
                        
                        Text(benefit)
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Permissions Step

struct PermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Enable Notifications")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Stay updated with your tasks and deadlines")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 24) {
                PermissionCard(
                    icon: "bell.badge.fill",
                    title: "Push Notifications",
                    description: "Get reminded about upcoming deadlines and important updates",
                    isGranted: viewModel.notificationPermissionGranted,
                    action: {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }
                )
                
                PermissionCard(
                    icon: "calendar.badge.plus",
                    title: "Calendar Access",
                    description: "Sync your tasks with your calendar for better planning",
                    isGranted: viewModel.calendarPermissionGranted,
                    action: {
                        viewModel.requestCalendarAccess()
                    }
                )
            }
            
            if viewModel.hasRequestedNotifications {
                VStack(spacing: 16) {
                    if viewModel.notificationPermissionGranted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appSuccess)
                            Text("Notifications enabled")
                                .foregroundColor(.appSuccess)
                                .font(.subheadline)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("Notifications were declined")
                                .foregroundColor(.appWarning)
                                .font(.subheadline)
                            
                            Text("You can enable them later in Settings")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .appSuccess : .appAccent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.appSuccess)
                    .font(.title3)
            } else {
                Button("Allow") {
                    action()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.appAccent)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Setup Step

struct SetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Setup Your Profile")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Tell us a bit about yourself")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter your name", text: $viewModel.userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($nameFieldFocused)
                    }
                    
                    // Role Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Role")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                Button {
                                    viewModel.userRole = role
                                } label: {
                                    Text(role.rawValue)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            viewModel.userRole == role ? 
                                            Color.appAccent : Color.white.opacity(0.1)
                                        )
                                        .foregroundColor(
                                            viewModel.userRole == role ? .black : .white
                                        )
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Preferences
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(viewModel.availablePreferences, id: \.0) { preference in
                            PreferenceRow(
                                id: preference.0,
                                title: preference.1,
                                icon: preference.2,
                                description: preference.3,
                                isSelected: viewModel.selectedPreferences.contains(preference.0),
                                action: {
                                    viewModel.togglePreference(preference.0)
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            nameFieldFocused = true
        }
    }
}

struct PreferenceRow: View {
    let id: String
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .appAccent : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .appAccent : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Color.appAccent.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingView()
}