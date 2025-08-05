//
//  DaFom777App.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI
import UserNotifications

@main
struct DaFom777App: App {
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("taskmaster_onboarding_completed") private var onboardingCompleted = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        // Setup notification delegate
        UNUserNotificationCenter.current().delegate = notificationService
        
        // Configure app appearance
        configureAppearance()
        
        // Request notification permissions if needed
        requestNotificationPermissions()
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.appBackground)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Configure tint colors
        UITabBar.appearance().tintColor = UIColor(Color.appAccent)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.secondary)
    }
    
    private func requestNotificationPermissions() {
        // Now that we renamed our Task model to TaskItem, we can use Task normally
        Task {
            if notificationService.authorizationStatus == .notDetermined {
                await notificationService.requestAuthorization()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            TasksListView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "checklist" : "checklist")
                    Text("Tasks")
                }
                .tag(1)
            
            ProjectsListView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "folder.fill" : "folder")
                    Text("Projects")
                }
                .tag(2)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                    Text("Analytics")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .preferredColorScheme(.dark)
        .accentColor(.appAccent)
    }
}

// MARK: - Placeholder Views (to be implemented)

struct TasksListView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingCreateTask = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                if viewModel.tasks.isEmpty {
                    EmptyStateView(
                        title: "No Tasks Yet",
                        subtitle: "Create your first task to get started with TaskMaster Pro",
                        systemImage: "checklist",
                        actionTitle: "Create Task",
                        action: { showingCreateTask = true }
                    )
                } else {
                    List {
                        ForEach(viewModel.tasks, id: \.id) { task in
                            TaskRowView(task: task) {
                                viewModel.selectTask(task)
                            } onToggleComplete: {
                                viewModel.toggleTaskCompletion(task)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .navigationTitle("All Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView { task in
                viewModel.addTask(task)
            }
        }
        .sheet(isPresented: $viewModel.showingTaskDetail) {
            if let task = viewModel.selectedTask {
                TaskDetailView(task: task) { updatedTask in
                    viewModel.updateTask(updatedTask)
                } onDelete: { deletedTask in
                    viewModel.deleteTask(deletedTask)
                }
            }
        }
    }
}

struct ProjectsListView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingCreateProject = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                if viewModel.projects.isEmpty {
                    EmptyStateView(
                        title: "No Projects Yet",
                        subtitle: "Create your first project to organize your tasks and collaborate with your team",
                        systemImage: "folder.badge.plus",
                        actionTitle: "Create Project",
                        action: { showingCreateProject = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.projects, id: \.id) { project in
                                ProjectCard(project: project) {
                                    // Navigate to project detail
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateProject = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView { project in
                viewModel.addProject(project)
            }
        }
    }
}

struct AnalyticsView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overview Cards
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            AnalyticsCard(
                                title: "Completion Rate",
                                value: "\(Int(viewModel.productivityStats?.completionRate ?? 0))%",
                                icon: "chart.pie.fill",
                                color: .appSuccess,
                                trend: "+5%"
                            )
                            
                            AnalyticsCard(
                                title: "Team Efficiency",
                                value: "\(Int(viewModel.getTeamEfficiencyScore()))%",
                                icon: "speedometer",
                                color: .appAccent,
                                trend: "+12%"
                            )
                            
                            AnalyticsCard(
                                title: "Active Projects",
                                value: "\(viewModel.projects.filter { $0.status == .active }.count)",
                                icon: "folder.fill",
                                color: .appInfo,
                                trend: "2 new"
                            )
                            
                            AnalyticsCard(
                                title: "Avg. Task Time",
                                value: String(format: "%.1fh", viewModel.productivityStats?.averageCompletionTime ?? 0),
                                icon: "clock.fill",
                                color: .appWarning,
                                trend: "-0.5h"
                            )
                        }
                        
                        // Weekly Progress Chart
                        if let stats = viewModel.productivityStats {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Weekly Progress")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                WeeklyProgressChart(weeklyProgress: viewModel.weeklyProgress)
                                    .frame(height: 200)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Completion Trend
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Completion Trend")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            CompletionTrendChart(data: viewModel.getCompletionTrend())
                                .frame(height: 150)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.appSuccess)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appSuccess.opacity(0.2))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CompletionTrendChart: View {
    let data: [CompletionPoint]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.appAccent)
                        .frame(width: 20, height: max(4, CGFloat(point.completed) * 10))
                        .cornerRadius(2)
                    
                    Text("\(Calendar.current.component(.day, from: point.date))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
