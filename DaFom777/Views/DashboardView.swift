//
//  DashboardView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingFilterMenu = false
    @State private var showingCreateTask = false
    @State private var showingCreateProject = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header Section
                        HeaderSection(viewModel: viewModel)
                        
                        // Quick Stats
                        QuickStatsSection(viewModel: viewModel)
                        
                        // Quick Actions
                        QuickActionsSection(viewModel: viewModel)
                        
                        // Tasks Section
                        TasksSection(viewModel: viewModel)
                        
                        // Projects Section
                        if !viewModel.projects.isEmpty {
                            ProjectsSection(viewModel: viewModel)
                        }
                        
                        // Productivity Insights
                        if let stats = viewModel.productivityStats {
                            ProductivitySection(stats: stats, weeklyProgress: viewModel.weeklyProgress)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            showingCreateTask = true
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFilterMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(.appAccent)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("New Task") {
                            showingCreateTask = true
                        }
                        Button("New Project") {
                            showingCreateProject = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingFilterMenu) {
            FilterMenuView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView { task in
                viewModel.addTask(task)
            }
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView { project in
                viewModel.addProject(project)
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

// MARK: - Header Section

struct HeaderSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDay)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Ready to be productive?")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Profile Avatar
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("JD")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                    )
            }
            
            // Search Bar
            SearchBar(text: $viewModel.searchText)
        }
    }
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks, projects...", text: $text)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Stats Section

struct QuickStatsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Due Today",
                    value: "\(viewModel.todayTasks.count)",
                    icon: "calendar",
                    color: .appAccent
                )
                
                StatCard(
                    title: "Overdue",
                    value: "\(viewModel.overdueTasks.count)",
                    icon: "exclamationmark.triangle",
                    color: .appDanger
                )
                
                StatCard(
                    title: "In Progress",
                    value: "\(viewModel.tasks.filter { $0.status == .inProgress }.count)",
                    icon: "clock",
                    color: .appWarning
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(viewModel.tasks.filter { $0.status == .completed }.count)",
                    icon: "checkmark.circle",
                    color: .appSuccess
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.getQuickActionTasks().prefix(5), id: \.id) { task in
                        QuickTaskCard(task: task) {
                            viewModel.selectTask(task)
                        }
                    }
                    
                    // Add new task button
                    AddTaskCard {
                        viewModel.showingCreateTask = true
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct QuickTaskCard: View {
    let task: TaskItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: task.priority.color))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if task.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.appDanger)
                            .font(.caption)
                    }
                }
                
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if let dueDate = task.dueDate {
                    Text(dueDate.relativeDateString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 150, height: 100)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddTaskCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.appAccent)
                
                Text("Add Task")
                    .font(.subheadline)
                    .foregroundColor(.appAccent)
            }
            .frame(width: 150, height: 100)
            .background(Color.appAccent.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appAccent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tasks Section

struct TasksSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.filteredTasks.count) of \(viewModel.tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isLoading {
                LoadingView("Loading tasks...")
                    .frame(height: 200)
            } else if viewModel.filteredTasks.isEmpty {
                EmptyStateView(
                    title: "No Tasks Found",
                    subtitle: viewModel.searchText.isEmpty ? "Create your first task to get started" : "No tasks match your search",
                    systemImage: "checklist",
                    actionTitle: viewModel.searchText.isEmpty ? "Create Task" : nil,
                    action: viewModel.searchText.isEmpty ? { viewModel.showingCreateTask = true } : nil
                )
                .frame(height: 200)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredTasks.prefix(10), id: \.id) { task in
                        TaskRowView(task: task) {
                            viewModel.selectTask(task)
                        } onToggleComplete: {
                            viewModel.toggleTaskCompletion(task)
                        }
                    }
                    
                    if viewModel.filteredTasks.count > 10 {
                        Button("View All Tasks (\(viewModel.filteredTasks.count))") {
                            // Navigate to full task list
                        }
                        .foregroundColor(.appAccent)
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Projects Section

struct ProjectsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Projects")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to projects view
                }
                .foregroundColor(.appAccent)
                .font(.caption)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.getRecentProjects(), id: \.id) { project in
                    ProjectCard(project: project) {
                        // Navigate to project detail
                    }
                }
            }
        }
    }
}

struct ProjectCard: View {
    let project: Project
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: project.type.icon)
                        .foregroundColor(.appAccent)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(project.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(project.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: project.status.color).opacity(0.2))
                        .foregroundColor(Color(hex: project.status.color))
                        .cornerRadius(8)
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(project.progressPercentage))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    ProgressView(value: project.progressPercentage / 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Productivity Section

struct ProductivitySection: View {
    let stats: ProductivityStats
    let weeklyProgress: [DayProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Productivity Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Completion Rate
                HStack {
                    VStack(alignment: .leading) {
                        Text("Completion Rate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(stats.completionRate))%")
                            .font(.title2.bold())
                            .foregroundColor(.appSuccess)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(progress: stats.completionRate / 100, color: .appSuccess)
                        .frame(width: 60, height: 60)
                }
                
                // Weekly Progress Chart
                WeeklyProgressChart(weeklyProgress: weeklyProgress)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
        }
    }
}

struct WeeklyProgressChart: View {
    let weeklyProgress: [DayProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyProgress, id: \.day) { day in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.appAccent)
                            .frame(width: 20, height: max(4, CGFloat(day.tasksCompleted) * 8))
                            .cornerRadius(2)
                        
                        Text(day.day.prefix(1))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.black)
                .frame(width: 56, height: 56)
                .background(Color.appAccent)
                .clipShape(Circle())
                .shadow(color: .appAccent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Menu

struct FilterMenuView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Filter & Sort")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filter by Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterOptionButton(
                                title: filter.rawValue,
                                icon: filter.icon,
                                color: filter.color,
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                viewModel.updateFilter(filter)
                            }
                        }
                    }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sort by")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(TaskSortOption.allCases, id: \.self) { option in
                        SortOptionButton(
                            title: option.rawValue,
                            isSelected: viewModel.sortOption == option
                        ) {
                            viewModel.updateSort(option)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button("Apply Filters") {
                    dismiss()
                }
                .primaryButtonStyle()
                .padding()
            }
            .background(Color.appBackground)
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

struct FilterOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .black : color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? color : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SortOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.appAccent)
                }
            }
            .padding()
            .background(isSelected ? Color.appAccent.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
}