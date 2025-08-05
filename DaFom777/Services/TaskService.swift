//
//  TaskService.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation
import Combine

class TaskService: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "taskmaster_tasks"
    private let projectsKey = "taskmaster_projects"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        loadTasks()
        loadProjects()
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decodedTaskItems = try? JSONDecoder().decode([TaskItem].self, from: data) {
            self.tasks = decodedTaskItems
        } else {
            // Load sample data on first launch
            self.tasks = TaskItem.sampleTasks
            saveTasks()
        }
    }
    
    private func loadProjects() {
        if let data = userDefaults.data(forKey: projectsKey),
           let decodedProjects = try? JSONDecoder().decode([Project].self, from: data) {
            self.projects = decodedProjects
        } else {
            // Load sample data on first launch
            self.projects = Project.sampleProjects
            saveProjects()
        }
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            userDefaults.set(data, forKey: tasksKey)
        }
    }
    
    private func saveProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            userDefaults.set(data, forKey: projectsKey)
        }
    }
    
    // MARK: - TaskItem Management
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
        
        // Schedule notification if due date is set
        if let dueDate = task.dueDate {
            NotificationService.shared.scheduleTaskReminder(for: task, at: dueDate)
        }
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
        
        // Cancel notification
        NotificationService.shared.cancelTaskReminder(for: task)
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        var updatedTaskItem = task
        updatedTaskItem.status = task.status == .completed ? .todo : .completed
        updatedTaskItem.completedDate = task.status == .completed ? nil : Date()
        updateTask(updatedTaskItem)
    }
    
    // MARK: - Project Management
    
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        
        // Remove project reference from tasks
        for task in tasks where task.projectId == project.id {
            var updatedTaskItem = task
            updatedTaskItem.projectId = nil
            updateTask(updatedTaskItem)
        }
        
        saveProjects()
    }
    
    // MARK: - Filtering and Sorting
    
    func getTasks(for project: Project) -> [TaskItem] {
        return tasks.filter { $0.projectId == project.id }
    }
    
    func getTasksForUser(_ userId: UUID) -> [TaskItem] {
        return tasks.filter { $0.assignedUserId == userId }
    }
    
    func getOverdueTasks() -> [TaskItem] {
        return tasks.filter { $0.isOverdue }
    }
    
    func getTasksByPriority(_ priority: TaskPriority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }
    
    func getTasksByStatus(_ status: TaskStatus) -> [TaskItem] {
        return tasks.filter { $0.status == status }
    }
    
    func getUpcomingTasks(days: Int = 7) -> [TaskItem] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= Date() && dueDate <= endDate && task.status != .completed
        }
    }
    
    func searchTasks(query: String) -> [TaskItem] {
        guard !query.isEmpty else { return tasks }
        
        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            task.description.localizedCaseInsensitiveContains(query) ||
            task.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func sortTasks(_ tasks: [TaskItem], by sortOption: TaskSortOption) -> [TaskItem] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { lhs, rhs in
                if lhs.dueDate == nil && rhs.dueDate == nil { return false }
                if lhs.dueDate == nil { return false }
                if rhs.dueDate == nil { return true }
                return lhs.dueDate! < rhs.dueDate!
            }
        case .priority:
            return tasks.sorted { $0.priority.weight > $1.priority.weight }
        case .aiScore:
            return tasks.sorted { $0.aiPriorityScore > $1.aiPriorityScore }
        case .createdDate:
            return tasks.sorted { $0.createdDate > $1.createdDate }
        case .title:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    // MARK: - Analytics
    
    func getProductivityStats() -> ProductivityStats {
        let totalTaskItems = tasks.count
        let completedTaskItems = tasks.filter { $0.status == .completed }.count
        let overdueTaskItems = getOverdueTasks().count
        let inProgressTaskItems = tasks.filter { $0.status == .inProgress }.count
        
        let completionRate = totalTaskItems > 0 ? Double(completedTaskItems) / Double(totalTaskItems) * 100 : 0
        
        // Calculate average completion time
        let completedTaskItemsWithTime = tasks.filter { 
            $0.status == .completed && $0.completedDate != nil 
        }
        let averageCompletionTime = completedTaskItemsWithTime.isEmpty ? 0 : 
            completedTaskItemsWithTime.reduce(0) { acc, task in
                guard let completedDate = task.completedDate else { return acc }
                let duration = completedDate.timeIntervalSince(task.createdDate)
                return acc + duration
            } / Double(completedTaskItemsWithTime.count)
        
        return ProductivityStats(
            totalTaskItems: totalTaskItems,
            completedTaskItems: completedTaskItems,
            overdueTaskItems: overdueTaskItems,
            inProgressTaskItems: inProgressTaskItems,
            completionRate: completionRate,
            averageCompletionTime: averageCompletionTime / 3600 // Convert to hours
        )
    }
    
    func getProjectStats(_ project: Project) -> ProjectStats {
        let projectTaskItems = getTasks(for: project)
        let totalTaskItems = projectTaskItems.count
        let completedTaskItems = projectTaskItems.filter { $0.status == .completed }.count
        let totalHours = projectTaskItems.reduce(0) { $0 + $1.actualHours }
        let estimatedHours = projectTaskItems.reduce(0) { $0 + $1.estimatedHours }
        
        let progress = totalTaskItems > 0 ? Double(completedTaskItems) / Double(totalTaskItems) * 100 : 0
        
        return ProjectStats(
            totalTaskItems: totalTaskItems,
            completedTaskItems: completedTaskItems,
            progress: progress,
            totalHours: totalHours,
            estimatedHours: estimatedHours,
            budgetUsed: project.actualBudget ?? 0,
            budgetAllocated: project.estimatedBudget ?? 0
        )
    }
}

// MARK: - Supporting Types

enum TaskSortOption: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case aiScore = "AI Score"
    case createdDate = "Created Date"
    case title = "Title"
}

struct ProductivityStats {
    let totalTaskItems: Int
    let completedTaskItems: Int
    let overdueTaskItems: Int
    let inProgressTaskItems: Int
    let completionRate: Double
    let averageCompletionTime: Double // in hours
}

struct ProjectStats {
    let totalTaskItems: Int
    let completedTaskItems: Int
    let progress: Double
    let totalHours: Double
    let estimatedHours: Double
    let budgetUsed: Double
    let budgetAllocated: Double
}