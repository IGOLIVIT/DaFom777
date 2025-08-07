//
//  DashboardViewModel.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projects: [Project] = []
    @Published var filteredTasks: [TaskItem] = []
    @Published var selectedFilter: TaskFilter = .all
    @Published var sortOption: TaskSortOption = .dueDate
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingTaskDetail = false
    @Published var selectedTask: TaskItem?
    @Published var showingCreateTask = false
    @Published var showingCreateProject = false
    @Published var showingAllProjects = false
    @Published var refreshing = false
    
    // Dashboard Stats
    @Published var todayTasks: [TaskItem] = []
    @Published var upcomingTasks: [TaskItem] = []
    @Published var overdueTasks: [TaskItem] = []
    @Published var productivityStats: ProductivityStats?
    @Published var weeklyProgress: [DayProgress] = []
    
    private let taskService = TaskService()
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadData()
        setupWeeklyProgress()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind to TaskService
        taskService.$tasks
            .receive(on: DispatchQueue.main)
            .assign(to: \.tasks, on: self)
            .store(in: &cancellables)
        
        taskService.$projects
            .receive(on: DispatchQueue.main)
            .assign(to: \.projects, on: self)
            .store(in: &cancellables)
        
        // Update filtered tasks when tasks, filter, or search changes
        Publishers.CombineLatest3($tasks, $selectedFilter, $searchText)
            .map { [weak self] tasks, filter, search in
                self?.filterTasks(tasks, filter: filter, search: search) ?? []
            }
            .assign(to: \.filteredTasks, on: self)
            .store(in: &cancellables)
        
        // Update dashboard stats when tasks change
        $tasks
            .map { [weak self] tasks in
                self?.updateDashboardStats(tasks: tasks)
            }
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    private func loadData() {
        isLoading = true
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.updateProductivityStats()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    private func filterTasks(_ tasks: [TaskItem], filter: TaskFilter, search: String) -> [TaskItem] {
        var filtered = tasks
        
        // Apply search filter
        if !search.isEmpty {
            filtered = taskService.searchTasks(query: search)
        }
        
        // Apply status filter
        switch filter {
        case .all:
            break
        case .todo:
            filtered = filtered.filter { $0.status == .todo }
        case .inProgress:
            filtered = filtered.filter { $0.status == .inProgress }
        case .completed:
            filtered = filtered.filter { $0.status == .completed }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        case .highPriority:
            filtered = filtered.filter { $0.priority == .high || $0.priority == .urgent }
        case .today:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
        case .thisWeek:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
            }
        }
        
        // Apply sorting
        return taskService.sortTasks(filtered, by: sortOption)
    }
    
    func updateFilter(_ filter: TaskFilter) {
        selectedFilter = filter
    }
    
    func updateSort(_ sort: TaskSortOption) {
        sortOption = sort
    }
    
    // MARK: - TaskItem Management
    
    func addTask(_ task: TaskItem) {
        taskService.addTask(task)
        updateAIPriorities()
    }
    
    func updateTask(_ task: TaskItem) {
        taskService.updateTask(task)
        updateAIPriorities()
    }
    
    func deleteTask(_ task: TaskItem) {
        taskService.deleteTask(task)
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        taskService.toggleTaskCompletion(task)
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    func selectTask(_ task: TaskItem) {
        selectedTask = task
        showingTaskDetail = true
    }
    
    // MARK: - Project Management
    
    func addProject(_ project: Project) {
        taskService.addProject(project)
    }
    
    func updateProject(_ project: Project) {
        taskService.updateProject(project)
    }
    
    func deleteProject(_ project: Project) {
        taskService.deleteProject(project)
    }
    
    // MARK: - AI Features
    
    private func updateAIPriorities() {
        let updatedTaskItems = aiService.updateTaskPriorities(tasks: tasks)
        // Update tasks with new AI scores
        for task in updatedTaskItems {
            taskService.updateTask(task)
        }
    }
    
    func suggestPriorityAdjustment(for task: TaskItem) -> TaskPriority? {
        return aiService.suggestPriorityAdjustment(for: task)
    }
    
    // MARK: - Dashboard Stats
    
    private func updateDashboardStats(tasks: [TaskItem]) {
        todayTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate) && task.status != .completed
        }
        
        upcomingTasks = taskService.getUpcomingTasks(days: 7)
        overdueTasks = taskService.getOverdueTasks()
    }
    
    private func updateProductivityStats() {
        productivityStats = taskService.getProductivityStats()
    }
    
    private func setupWeeklyProgress() {
        let calendar = Calendar.current
        let today = Date()
        
        weeklyProgress = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            
            let dayTaskItems = tasks.filter { task in
                guard let completedDate = task.completedDate else { return false }
                return calendar.isDate(completedDate, inSameDayAs: date)
            }
            
            let dayName = DateFormatter().shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            return DayProgress(
                day: dayName,
                date: date,
                tasksCompleted: dayTaskItems.count,
                totalHours: dayTaskItems.reduce(0) { $0 + $1.actualHours }
            )
        }.reversed()
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        refreshing = true
        
        // Simulate network refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            updateProductivityStats()
            setupWeeklyProgress()
            updateAIPriorities()
            refreshing = false
        }
    }
    
    // MARK: - Quick Actions
    
    func getQuickActionTasks() -> [TaskItem] {
        let highPriority = tasks.filter { $0.priority == .urgent || $0.priority == .high }
        let overdue = overdueTasks
        let dueToday = todayTasks
        
        let combined = Array(Set(highPriority + overdue + dueToday))
        return Array(combined.prefix(5))
    }
    
    func getRecentProjects() -> [Project] {
        return Array(projects.sorted { $0.createdDate > $1.createdDate }.prefix(3))
    }
    
    // MARK: - Analytics
    
    func getCompletionTrend() -> [CompletionPoint] {
        let calendar = Calendar.current
        let last7Days = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: Date())
        }.reversed()
        
        return last7Days.map { date in
            let dayTaskItems = tasks.filter { task in
                guard let completedDate = task.completedDate else { return false }
                return calendar.isDate(completedDate, inSameDayAs: date)
            }
            
            return CompletionPoint(
                date: date,
                completed: dayTaskItems.count,
                total: tasks.filter { task in
                    calendar.isDate(task.createdDate, lessThanOrEqualTo: date)
                }.count
            )
        }
    }
    
    func getTeamEfficiencyScore() -> Double {
        guard !tasks.isEmpty else { return 0.0 }
        
        let completedTaskItems = tasks.filter { $0.status == .completed }
        let onTimeCompletions = completedTaskItems.filter { task in
            guard let dueDate = task.dueDate, let completedDate = task.completedDate else { return true }
            return completedDate <= dueDate
        }
        
        return Double(onTimeCompletions.count) / Double(completedTaskItems.count) * 100
    }
}

// MARK: - Supporting Types

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case todo = "To Do"
    case inProgress = "In Progress"
    case completed = "Completed"
    case overdue = "Overdue"
    case highPriority = "High Priority"
    case today = "Due Today"
    case thisWeek = "This Week"
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .todo: return "circle"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .highPriority: return "flag.fill"
        case .today: return "calendar"
        case .thisWeek: return "calendar.badge.clock"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .todo: return .appInfo
        case .inProgress: return .appWarning
        case .completed: return .appSuccess
        case .overdue: return .appDanger
        case .highPriority: return .priorityUrgent
        case .today: return .appAccent
        case .thisWeek: return .appAccent
        }
    }
}

struct DayProgress {
    let day: String
    let date: Date
    let tasksCompleted: Int
    let totalHours: Double
}

struct CompletionPoint {
    let date: Date
    let completed: Int
    let total: Int
    
    var completionRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func isDate(_ date1: Date, lessThanOrEqualTo date2: Date) -> Bool {
        return date1 <= date2
    }
}