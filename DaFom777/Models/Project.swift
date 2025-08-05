//
//  Project.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation

enum ProjectStatus: String, CaseIterable, Codable {
    case planning = "Planning"
    case active = "Active"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .planning: return "#fcc418"
        case .active: return "#3cc45b"
        case .onHold: return "#95a5a6"
        case .completed: return "#27ae60"
        case .cancelled: return "#e74c3c"
        }
    }
}

enum ProjectType: String, CaseIterable, Codable {
    case development = "Development"
    case design = "Design"
    case marketing = "Marketing"
    case research = "Research"
    case operations = "Operations"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .development: return "laptopcomputer"
        case .design: return "paintbrush"
        case .marketing: return "megaphone"
        case .research: return "magnifyingglass"
        case .operations: return "gearshape"
        case .other: return "folder"
        }
    }
}

struct Project: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var status: ProjectStatus
    var type: ProjectType
    var startDate: Date
    var endDate: Date?
    var deadline: Date?
    var createdDate: Date
    var ownerId: UUID
    var teamMembers: [UUID]
    var tags: [String]
    var color: String
    var estimatedBudget: Double?
    var actualBudget: Double?
    var estimatedHours: Double
    var actualHours: Double
    
    init(
        name: String,
        description: String = "",
        status: ProjectStatus = .planning,
        type: ProjectType = .other,
        startDate: Date = Date(),
        endDate: Date? = nil,
        deadline: Date? = nil,
        ownerId: UUID,
        teamMembers: [UUID] = [],
        tags: [String] = [],
        color: String = "#3e4464",
        estimatedBudget: Double? = nil,
        estimatedHours: Double = 40.0
    ) {
        self.name = name
        self.description = description
        self.status = status
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.deadline = deadline
        self.createdDate = Date()
        self.ownerId = ownerId
        self.teamMembers = teamMembers
        self.tags = tags
        self.color = color
        self.estimatedBudget = estimatedBudget
        self.actualBudget = 0.0
        self.estimatedHours = estimatedHours
        self.actualHours = 0.0
    }
    
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return deadline < Date() && status != .completed
    }
    
    var progressPercentage: Double {
        guard estimatedHours > 0 else { return 0.0 }
        return min(100.0, (actualHours / estimatedHours) * 100.0)
    }
    
    var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: deadline).day
        return days
    }
    
    var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
    
    var budgetUsagePercentage: Double {
        guard let estimated = estimatedBudget, estimated > 0,
              let actual = actualBudget else { return 0.0 }
        return min(100.0, (actual / estimated) * 100.0)
    }
}

// MARK: - Sample Data
extension Project {
    static let sampleProjects: [Project] = [
        Project(
            name: "TaskMaster Pro Mobile App",
            description: "Complete redesign and development of the TaskMaster Pro mobile application with new features and improved UX.",
            status: .active,
            type: .development,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            ownerId: UUID(),
            teamMembers: [UUID(), UUID(), UUID()],
            tags: ["Mobile", "iOS", "SwiftUI", "Critical"],
            color: "#3cc45b",
            estimatedBudget: 50000.0,
            estimatedHours: 320.0
        ),
        Project(
            name: "Brand Identity Refresh",
            description: "Update company branding including logo, color scheme, and marketing materials.",
            status: .planning,
            type: .design,
            startDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date(),
            deadline: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
            ownerId: UUID(),
            teamMembers: [UUID(), UUID()],
            tags: ["Branding", "Design", "Marketing"],
            color: "#fcc418",
            estimatedBudget: 25000.0,
            estimatedHours: 160.0
        ),
        Project(
            name: "Customer Analytics Platform",
            description: "Build comprehensive analytics dashboard for customer behavior analysis.",
            status: .active,
            type: .development,
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            ownerId: UUID(),
            teamMembers: [UUID(), UUID(), UUID(), UUID()],
            tags: ["Analytics", "Dashboard", "Data"],
            color: "#9b59b6",
            estimatedBudget: 75000.0,
            estimatedHours: 480.0
        ),
        Project(
            name: "Q4 Marketing Campaign",
            description: "Comprehensive marketing campaign for Q4 product launches and holiday season.",
            status: .completed,
            type: .marketing,
            startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            deadline: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            ownerId: UUID(),
            teamMembers: [UUID(), UUID()],
            tags: ["Marketing", "Campaign", "Holiday"],
            color: "#e67e22",
            estimatedBudget: 30000.0,
            estimatedHours: 200.0
        )
    ]
}