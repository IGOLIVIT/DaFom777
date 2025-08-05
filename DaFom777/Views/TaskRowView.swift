//
//  TaskRowView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion Button
                Button(action: onToggleComplete) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.status == .completed ? .appSuccess : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Priority
                    HStack {
                        Text(task.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .strikethrough(task.status == .completed)
                            .opacity(task.status == .completed ? 0.6 : 1.0)
                        
                        Spacer()
                        
                        Text(task.priority.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: task.priority.color))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    // Description (if available)
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Bottom row with metadata
                    HStack(spacing: 8) {
                        // Due date
                        if let dueDate = task.dueDate {
                            Label {
                                Text(dueDate.relativeDateString())
                                    .font(.caption2)
                                    .foregroundColor(task.isOverdue ? .appDanger : .secondary)
                            } icon: {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(task.isOverdue ? .appDanger : .secondary)
                            }
                        }
                        
                        // Project name
                        if let projectName = getProjectName() {
                            Label {
                                Text(projectName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "folder")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Text(task.status.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(getStatusColor().opacity(0.2))
                            .foregroundColor(getStatusColor())
                            .cornerRadius(6)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getProjectName() -> String? {
        // In a real app, you would fetch this from the task service
        return nil
    }
    
    private func getStatusColor() -> Color {
        switch task.status {
        case .todo: return .appInfo
        case .inProgress: return .appWarning
        case .review: return .appAccent
        case .completed: return .appSuccess
        case .cancelled: return .appDanger
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        TaskRowView(
            task: TaskItem.sampleTasks[0],
            onTap: {},
            onToggleComplete: {}
        )
        
        TaskRowView(
            task: TaskItem.sampleTasks[1],
            onTap: {},
            onToggleComplete: {}
        )
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}