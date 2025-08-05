//
//  Task.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "#3cc45b"
        case .medium: return "#fcc418"
        case .high: return "#ff6b35"
        case .urgent: return "#e74c3c"
        }
    }
    
    var weight: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case review = "Review"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

enum TaskComplexity: String, CaseIterable, Codable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    case expert = "Expert"
    
    var estimatedHours: Double {
        switch self {
        case .simple: return 1.0
        case .moderate: return 4.0
        case .complex: return 8.0
        case .expert: return 16.0
        }
    }
}

struct TaskItem: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var priority: TaskPriority
    var status: TaskStatus
    var complexity: TaskComplexity
    var dueDate: Date?
    var createdDate: Date
    var completedDate: Date?
    var projectId: UUID?
    var assignedUserId: UUID?
    var tags: [String]
    var estimatedHours: Double
    var actualHours: Double
    var aiPriorityScore: Double
    var subtasks: [String]
    var attachments: [String]
    var collaborators: [UUID]
    
    init(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        status: TaskStatus = .todo,
        complexity: TaskComplexity = .moderate,
        dueDate: Date? = nil,
        projectId: UUID? = nil,
        assignedUserId: UUID? = nil,
        tags: [String] = [],
        estimatedHours: Double? = nil,
        subtasks: [String] = [],
        attachments: [String] = [],
        collaborators: [UUID] = []
    ) {
        self.title = title
        self.description = description
        self.priority = priority
        self.status = status
        self.complexity = complexity
        self.dueDate = dueDate
        self.createdDate = Date()
        self.projectId = projectId
        self.assignedUserId = assignedUserId
        self.tags = tags
        self.estimatedHours = estimatedHours ?? complexity.estimatedHours
        self.actualHours = 0.0
        self.aiPriorityScore = 0.0
        self.subtasks = subtasks
        self.attachments = attachments
        self.collaborators = collaborators
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .completed
    }
    
    var progressPercentage: Double {
        guard !subtasks.isEmpty else {
            return status == .completed ? 100.0 : 0.0
        }
        // In a real app, you'd track subtask completion
        return status == .completed ? 100.0 : Double(subtasks.count) * 10.0
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: dueDate).day
        return days
    }
}

// MARK: - Sample Data
extension TaskItem {
    static let sampleTasks: [TaskItem] = [
        TaskItem(
            title: "Design new onboarding flow",
            description: "Create a comprehensive onboarding experience for new users with interactive tutorials and feature highlights.",
            priority: .high,
            status: .inProgress,
            complexity: .complex,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            tags: ["Design", "UX", "Onboarding"],
            estimatedHours: 12.0,
            subtasks: ["Research competitors", "Create wireframes", "Design mockups", "User testing"],
            collaborators: [UUID()]
        ),
        TaskItem(
            title: "Implement push notifications",
            description: "Set up push notification system for task reminders and team updates.",
            priority: .medium,
            status: .todo,
            complexity: .moderate,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            tags: ["Development", "Backend", "Notifications"],
            estimatedHours: 6.0,
            subtasks: ["Configure APNs", "Create notification templates", "Test delivery"]
        ),
        TaskItem(
            title: "Weekly team standup",
            description: "Regular team sync to discuss progress and blockers.",
            priority: .low,
            status: .completed,
            complexity: .simple,
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            tags: ["Meeting", "Team"],
            estimatedHours: 1.0
        ),
        TaskItem(
            title: "Security audit",
            description: "Comprehensive security review of the application infrastructure.",
            priority: .urgent,
            status: .review,
            complexity: .expert,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            tags: ["Security", "Audit", "Critical"],
            estimatedHours: 20.0,
            collaborators: [UUID(), UUID()]
        )
    ]
}