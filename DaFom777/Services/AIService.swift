//
//  AIService.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation
import Combine

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isProcessing = false
    @Published var lastUpdate = Date()
    
    private init() {}
    
    // MARK: - TaskItem Prioritization AI
    
    func calculatePriorityScore(for task: TaskItem) -> Double {
        var score: Double = 0.0
        
        // Base priority weight (40% of total score)
        score += Double(task.priority.weight) * 10.0
        
        // Deadline urgency (30% of total score)
        if let dueDate = task.dueDate {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            let urgencyScore = max(0, 30 - Double(daysUntilDue)) // Higher score for sooner deadlines
            score += urgencyScore * 0.75
        }
        
        // Complexity factor (15% of total score)
        let complexityMultiplier: Double
        switch task.complexity {
        case .simple: complexityMultiplier = 0.5
        case .moderate: complexityMultiplier = 1.0
        case .complex: complexityMultiplier = 1.5
        case .expert: complexityMultiplier = 2.0
        }
        score += complexityMultiplier * 7.5
        
        // Project importance (10% of total score)
        // In a real implementation, this would consider project priority
        score += 5.0
        
        // Recent activity boost (5% of total score)
        let daysSinceCreated = Calendar.current.dateComponents([.day], from: task.createdDate, to: Date()).day ?? 0
        if daysSinceCreated <= 1 {
            score += 5.0 // Boost for recently created tasks
        }
        
        return min(100.0, score)
    }
    
    func updateTaskPriorities(tasks: [TaskItem]) -> [TaskItem] {
        isProcessing = true
        defer { isProcessing = false }
        
        var updatedTaskItems = tasks
        
        for i in 0..<updatedTaskItems.count {
            updatedTaskItems[i].aiPriorityScore = calculatePriorityScore(for: updatedTaskItems[i])
        }
        
        lastUpdate = Date()
        return updatedTaskItems
    }
    
    func suggestPriorityAdjustment(for task: TaskItem) -> TaskPriority? {
        let aiScore = calculatePriorityScore(for: task)
        
        // Suggest priority based on AI score
        switch aiScore {
        case 80...100:
            return task.priority != .urgent ? .urgent : nil
        case 60..<80:
            return task.priority != .high ? .high : nil
        case 40..<60:
            return task.priority != .medium ? .medium : nil
        case 0..<40:
            return task.priority != .low ? .low : nil
        default:
            return nil
        }
    }
    
    // MARK: - Dynamic Workflows
    
    func suggestWorkflowOptimizations(for project: Project, with tasks: [TaskItem]) -> [WorkflowSuggestion] {
        var suggestions: [WorkflowSuggestion] = []
        
        let projectTaskItems = tasks.filter { $0.projectId == project.id }
        
        // Analyze task dependencies and suggest optimal ordering
        let highPriorityTaskItems = projectTaskItems.filter { $0.priority == .high || $0.priority == .urgent }
        if highPriorityTaskItems.count > 3 {
            suggestions.append(
                WorkflowSuggestion(
                    type: .taskReordering,
                    title: "Reorder High Priority TaskItems",
                    description: "Consider breaking down or redistributing high priority tasks to improve team focus.",
                    priority: .medium,
                    estimatedImpact: "15% efficiency improvement"
                )
            )
        }
        
        // Check for overdue tasks
        let overdueTaskItems = projectTaskItems.filter { $0.isOverdue }
        if !overdueTaskItems.isEmpty {
            suggestions.append(
                WorkflowSuggestion(
                    type: .deadlineAdjustment,
                    title: "Address Overdue TaskItems",
                    description: "You have \(overdueTaskItems.count) overdue task(s). Consider reassigning or extending deadlines.",
                    priority: .high,
                    estimatedImpact: "Prevent project delays"
                )
            )
        }
        
        // Suggest team collaboration improvements
        let tasksWithMultipleCollaborators = projectTaskItems.filter { $0.collaborators.count > 2 }
        if tasksWithMultipleCollaborators.count > 2 {
            suggestions.append(
                WorkflowSuggestion(
                    type: .teamOptimization,
                    title: "Optimize Team Collaboration",
                    description: "Multiple tasks have many collaborators. Consider creating sub-teams or clearer role definitions.",
                    priority: .low,
                    estimatedImpact: "Improved communication flow"
                )
            )
        }
        
        return suggestions
    }
    
    func generateAutomationRules(for user: User, based tasks: [TaskItem]) -> [AutomationRule] {
        var rules: [AutomationRule] = []
        
        // Analyze user patterns
        let userTaskItems = tasks.filter { $0.assignedUserId == user.id }
        let completedTaskItems = userTaskItems.filter { $0.status == .completed }
        
        // Suggest automatic priority assignment
        if completedTaskItems.count > 5 {
            let avgCompletionTime = completedTaskItems.reduce(0.0) { acc, task in
                guard let completedDate = task.completedDate else { return acc }
                return acc + completedDate.timeIntervalSince(task.createdDate)
            } / Double(completedTaskItems.count)
            
            if avgCompletionTime < 86400 { // Less than 1 day
                rules.append(
                    AutomationRule(
                        name: "Quick TaskItem Auto-Priority",
                        description: "Automatically set priority to High for tasks estimated under 2 hours",
                        trigger: .taskCreated,
                        condition: "estimatedHours < 2",
                        action: .setPriority(.high)
                    )
                )
            }
        }
        
        // Suggest deadline reminders
        rules.append(
            AutomationRule(
                name: "Smart Deadline Reminders",
                description: "Send reminders based on task complexity and your completion patterns",
                trigger: .timeBasedReminder,
                condition: "dueDate approaching",
                action: .sendNotification
            )
        )
        
        return rules
    }
    
    // MARK: - Productivity Insights
    
    func generateProductivityInsights(for user: User, with tasks: [TaskItem], projects: [Project]) -> ProductivityInsights {
        let userTaskItems = tasks.filter { $0.assignedUserId == user.id }
        let completedTaskItems = userTaskItems.filter { $0.status == .completed }
        
        // Calculate productivity metrics
        let completionRate = userTaskItems.isEmpty ? 0.0 : Double(completedTaskItems.count) / Double(userTaskItems.count) * 100
        
        let averageTaskItemDuration = completedTaskItems.isEmpty ? 0.0 : completedTaskItems.reduce(0.0) { acc, task in
            guard let completedDate = task.completedDate else { return acc }
            return acc + completedDate.timeIntervalSince(task.createdDate)
        } / Double(completedTaskItems.count) / 3600 // Convert to hours
        
        // Identify peak productivity times
        let taskCreationHours = userTaskItems.compactMap { task in
            Calendar.current.component(.hour, from: task.createdDate)
        }
        let peakHour = taskCreationHours.mostFrequent() ?? 9
        
        // Generate recommendations
        var recommendations: [String] = []
        
        if completionRate < 70 {
            recommendations.append("Consider breaking down large tasks into smaller, manageable subtasks")
        }
        
        if averageTaskItemDuration > 24 {
            recommendations.append("Focus on setting more realistic time estimates for complex tasks")
        }
        
        recommendations.append("Your peak productivity appears to be around \(peakHour):00. Consider scheduling important tasks during this time.")
        
        return ProductivityInsights(
            completionRate: completionRate,
            averageTaskItemDuration: averageTaskItemDuration,
            peakProductivityHour: peakHour,
            totalTaskItemsCompleted: completedTaskItems.count,
            recommendations: recommendations,
            trendAnalysis: generateTrendAnalysis(from: completedTaskItems)
        )
    }
    
    private func generateTrendAnalysis(from tasks: [TaskItem]) -> TrendAnalysis {
        let last30Days = tasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return completedDate >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        }
        
        let previous30Days = tasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            let startDate = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return completedDate >= startDate && completedDate < endDate
        }
        
        let currentPeriodCount = last30Days.count
        let previousPeriodCount = previous30Days.count
        
        let changePercentage = previousPeriodCount == 0 ? 0.0 : 
            Double(currentPeriodCount - previousPeriodCount) / Double(previousPeriodCount) * 100
        
        let direction: TrendDirection = changePercentage > 5 ? .improving : 
                                       changePercentage < -5 ? .declining : .stable
        
        return TrendAnalysis(
            direction: direction,
            changePercentage: abs(changePercentage),
            currentPeriodValue: currentPeriodCount,
            previousPeriodValue: previousPeriodCount
        )
    }
}

// MARK: - Supporting Types

struct WorkflowSuggestion {
    let type: WorkflowSuggestionType
    let title: String
    let description: String
    let priority: TaskPriority
    let estimatedImpact: String
}

enum WorkflowSuggestionType {
    case taskReordering
    case deadlineAdjustment
    case teamOptimization
    case resourceAllocation
}

struct AutomationRule {
    let name: String
    let description: String
    let trigger: AutomationTrigger
    let condition: String
    let action: AutomationAction
}

enum AutomationTrigger {
    case taskCreated
    case taskUpdated
    case deadlineApproaching
    case timeBasedReminder
}

enum AutomationAction {
    case setPriority(TaskPriority)
    case assignToUser(UUID)
    case sendNotification
    case moveToProject(UUID)
}

struct ProductivityInsights {
    let completionRate: Double
    let averageTaskItemDuration: Double // in hours
    let peakProductivityHour: Int
    let totalTaskItemsCompleted: Int
    let recommendations: [String]
    let trendAnalysis: TrendAnalysis
}

struct TrendAnalysis {
    let direction: TrendDirection
    let changePercentage: Double
    let currentPeriodValue: Int
    let previousPeriodValue: Int
}

enum TrendDirection {
    case improving
    case declining
    case stable
}

// MARK: - Array Extension

extension Array where Element: Hashable {
    func mostFrequent() -> Element? {
        let counts = self.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}