//
//  User.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation

enum UserRole: String, CaseIterable, Codable {
    case admin = "Admin"
    case manager = "Manager"
    case teamLead = "Team Lead"
    case developer = "Developer"
    case designer = "Designer"
    case analyst = "Analyst"
    case member = "Member"
    
    var permissions: [String] {
        switch self {
        case .admin:
            return ["create_project", "delete_project", "manage_users", "view_analytics", "manage_settings"]
        case .manager:
            return ["create_project", "manage_team", "view_analytics", "assign_tasks"]
        case .teamLead:
            return ["create_tasks", "assign_tasks", "view_team_analytics"]
        case .developer, .designer, .analyst:
            return ["create_tasks", "edit_own_tasks", "view_project"]
        case .member:
            return ["create_tasks", "edit_own_tasks"]
        }
    }
    
    var badgeColor: String {
        switch self {
        case .admin: return "#e74c3c"
        case .manager: return "#9b59b6"
        case .teamLead: return "#3498db"
        case .developer: return "#2ecc71"
        case .designer: return "#f39c12"
        case .analyst: return "#1abc9c"
        case .member: return "#95a5a6"
        }
    }
}

enum UserStatus: String, CaseIterable, Codable {
    case active = "Active"
    case away = "Away"
    case busy = "Busy"
    case offline = "Offline"
    
    var color: String {
        switch self {
        case .active: return "#3cc45b"
        case .away: return "#fcc418"
        case .busy: return "#e74c3c"
        case .offline: return "#95a5a6"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "circle.fill"
        case .away: return "moon.fill"
        case .busy: return "minus.circle.fill"
        case .offline: return "circle"
        }
    }
}

struct User: Identifiable, Codable, Hashable {
    let id = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var role: UserRole
    var status: UserStatus
    var avatar: String?
    var department: String?
    var joinDate: Date
    var lastActive: Date
    var timezone: String
    var preferences: UserPreferences
    var stats: UserStats
    var projects: [UUID]
    var skills: [String]
    var phoneNumber: String?
    var bio: String?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
    
    init(
        firstName: String,
        lastName: String,
        email: String,
        role: UserRole = .member,
        status: UserStatus = .active,
        avatar: String? = nil,
        department: String? = nil,
        timezone: String = "UTC",
        projects: [UUID] = [],
        skills: [String] = [],
        phoneNumber: String? = nil,
        bio: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.status = status
        self.avatar = avatar
        self.department = department
        self.joinDate = Date()
        self.lastActive = Date()
        self.timezone = timezone
        self.preferences = UserPreferences()
        self.stats = UserStats()
        self.projects = projects
        self.skills = skills
        self.phoneNumber = phoneNumber
        self.bio = bio
    }
}

struct UserPreferences: Codable, Hashable {
    var notificationsEnabled: Bool = true
    var emailNotifications: Bool = true
    var pushNotifications: Bool = true
    var taskReminders: Bool = true
    var weeklyReports: Bool = true
    var darkMode: Bool = false
    var preferredView: String = "dashboard" // dashboard, kanban, calendar
    var workingHours: WorkingHours = WorkingHours()
    var language: String = "en"
    var dateFormat: String = "MM/dd/yyyy"
    var timeFormat: String = "12h" // 12h or 24h
}

struct WorkingHours: Codable, Hashable {
    var startTime: String = "09:00"
    var endTime: String = "17:00"
    var workDays: [String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    var timezone: String = "UTC"
}

struct UserStats: Codable, Hashable {
    var tasksCompleted: Int = 0
    var projectsCompleted: Int = 0
    var totalHoursWorked: Double = 0.0
    var averageTaskCompletionTime: Double = 0.0 // in hours
    var productivityScore: Double = 0.0 // 0-100
    var streakDays: Int = 0
    var lastUpdated: Date = Date()
    
    var completionRate: Double {
        // This would be calculated based on assigned vs completed tasks
        return tasksCompleted > 0 ? min(100.0, Double(tasksCompleted) * 10.0) : 0.0
    }
    
    var averageHoursPerDay: Double {
        let daysWorked = max(1, Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 1)
        return totalHoursWorked / Double(daysWorked)
    }
}

// MARK: - Sample Data
extension User {
    static let currentUser = User(
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@company.com",
        role: .manager,
        status: .active,
        department: "Product Development",
        skills: ["Project Management", "Strategy", "Leadership"],
        bio: "Experienced product manager with a passion for building great teams and delivering exceptional products."
    )
    
    static let sampleUsers: [User] = [
        User(
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah.johnson@company.com",
            role: .developer,
            status: .active,
            department: "Engineering",
            skills: ["Swift", "iOS", "SwiftUI", "Backend"]
        ),
        User(
            firstName: "Mike",
            lastName: "Chen",
            email: "mike.chen@company.com",
            role: .designer,
            status: .busy,
            department: "Design",
            skills: ["UI/UX", "Figma", "Prototyping", "User Research"]
        ),
        User(
            firstName: "Emily",
            lastName: "Rodriguez",
            email: "emily.rodriguez@company.com",
            role: .analyst,
            status: .away,
            department: "Data",
            skills: ["Analytics", "SQL", "Python", "Data Visualization"]
        ),
        User(
            firstName: "David",
            lastName: "Wilson",
            email: "david.wilson@company.com",
            role: .teamLead,
            status: .active,
            department: "Engineering",
            skills: ["Team Leadership", "Architecture", "Mentoring"]
        )
    ]
}