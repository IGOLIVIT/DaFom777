//
//  TaskDetailView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    let onUpdate: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    
    @StateObject private var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(task: TaskItem, onUpdate: @escaping (TaskItem) -> Void, onDelete: @escaping (TaskItem) -> Void) {
        self.task = task
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        TaskHeaderSection(viewModel: viewModel)
                        
                        // Main Content
                        if viewModel.isEditing {
                            EditingSection(viewModel: viewModel)
                        } else {
                            ViewingSection(viewModel: viewModel)
                        }
                        
                        // Progress and Time Tracking
                        ProgressSection(viewModel: viewModel)
                        
                        // Subtasks Section
                        SubtasksSection(viewModel: viewModel)
                        
                        // AI Suggestions
                        AISection(viewModel: viewModel)
                        
                        // Time Logging (if not editing)
                        if !viewModel.isEditing {
                            TimeLoggingSection(viewModel: viewModel)
                        }
                        
                        // Danger Zone
                        if !viewModel.isEditing {
                            DangerZoneSection(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Task" : "Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(viewModel.isEditing ? "Cancel" : "Close") {
                        if viewModel.isEditing && viewModel.hasUnsavedChanges {
                            // Show confirmation alert
                            viewModel.discardChanges()
                        } else if viewModel.isEditing {
                            viewModel.toggleEditing()
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        Button("Save") {
                            viewModel.saveChanges()
                        }
                        .foregroundColor(.appAccent)
                        .disabled(!viewModel.formIsValid)
                    } else {
                        Button("Edit") {
                            viewModel.toggleEditing()
                        }
                        .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.onTaskUpdated = onUpdate
            viewModel.onTaskDeleted = { deletedTask in
                onDelete(deletedTask)
                dismiss()
            }
        }
        .confirmationDialog(
            "Delete Task",
            isPresented: $viewModel.showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteTask()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Header Section

struct TaskHeaderSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Completion Toggle
                Button {
                    viewModel.toggleTaskCompletion()
                } label: {
                    Image(systemName: viewModel.task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(viewModel.task.status == .completed ? .appSuccess : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.task.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .strikethrough(viewModel.task.status == .completed)
                        .opacity(viewModel.task.status == .completed ? 0.6 : 1.0)
                    
                    HStack(spacing: 12) {
                        // Priority Badge
                        Text(viewModel.task.priority.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: viewModel.task.priority.color))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        // Status Badge
                        Text(viewModel.task.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getStatusColor().opacity(0.2))
                            .foregroundColor(getStatusColor())
                            .cornerRadius(8)
                        
                        // AI Score if available
                        if viewModel.task.aiPriorityScore > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption2)
                                Text("\(Int(viewModel.task.aiPriorityScore))")
                                    .font(.caption)
                            }
                            .foregroundColor(.appAccent)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Due Date and Time Remaining
            if let dueDate = viewModel.task.dueDate {
                HStack {
                    Label {
                        Text(dueDate.formatted(style: .long))
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.appAccent)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.timeRemaining)
                        .font(.caption)
                        .foregroundColor(viewModel.task.isOverdue ? .appDanger : .secondary)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private func getStatusColor() -> Color {
        switch viewModel.task.status {
        case .todo: return .appInfo
        case .inProgress: return .appWarning
        case .review: return .appAccent
        case .completed: return .appSuccess
        case .cancelled: return .appDanger
        }
    }
}

// MARK: - Viewing Section

struct ViewingSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.task.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(viewModel.task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            // Metadata Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetadataCard(
                    title: "Complexity",
                    value: viewModel.task.complexity.rawValue,
                    icon: "gauge.medium",
                    color: .appInfo
                )
                
                MetadataCard(
                    title: "Estimated",
                    value: viewModel.estimatedDurationText(),
                    icon: "clock",
                    color: .appWarning
                )
                
                MetadataCard(
                    title: "Actual",
                    value: viewModel.actualDurationText(),
                    icon: "stopwatch",
                    color: .appSuccess
                )
                
                if let projectName = viewModel.projectName {
                    MetadataCard(
                        title: "Project",
                        value: projectName,
                        icon: "folder",
                        color: .appAccent
                    )
                }
            }
            
            // Tags
            if !viewModel.task.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.appAccent.opacity(0.2))
                                .foregroundColor(.appAccent)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Editing Section

struct EditingSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @FocusState private var titleFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Task title", text: $viewModel.editingTitle)
                    .textFieldStyle(CustomTextFieldStyle())
                    .focused($titleFocused)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Description", text: $viewModel.editingDescription)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(4)
            }
            
            // Priority and Status
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Menu {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Button(priority.rawValue) {
                                viewModel.editingPriority = priority
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.editingPriority.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Menu {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                viewModel.editingStatus = status
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.editingStatus.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Due Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Due Date")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { viewModel.editingDueDate ?? Date() },
                            set: { viewModel.editingDueDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(.appAccent)
                    
                    if viewModel.editingDueDate != nil {
                        Button("Clear") {
                            viewModel.editingDueDate = nil
                        }
                        .foregroundColor(.appDanger)
                        .font(.caption)
                    }
                }
            }
            
            // Estimated Hours
            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated Hours")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Hours", text: $viewModel.editingEstimatedHours)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
        }
    }
}

// MARK: - Progress Section

struct ProgressSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Completion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.progressPercentage))%")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                }
                
                ProgressView(value: viewModel.progressPercentage / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                    .scaleEffect(y: 2)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

// MARK: - Subtasks Section

struct SubtasksSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subtasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isEditing {
                    Button("Add") {
                        viewModel.addSubtask()
                    }
                    .foregroundColor(.appAccent)
                    .disabled(viewModel.newSubtask.isEmpty)
                }
            }
            
            if viewModel.isEditing {
                HStack {
                    TextField("New subtask", text: $viewModel.newSubtask)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onSubmit {
                            viewModel.addSubtask()
                        }
                }
            }
            
            if !viewModel.editingSubtasks.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.editingSubtasks.enumerated()), id: \.offset) { index, subtask in
                        HStack {
                            if viewModel.isEditing {
                                Button {
                                    viewModel.removeSubtask(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.appDanger)
                                }
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(subtask)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("No subtasks")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - AI Section

struct AISection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.appAccent)
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Priority Suggestion
                if let suggestion = viewModel.aiPrioritySuggestion {
                    SuggestionCard(
                        title: "Priority Suggestion",
                        description: "AI suggests changing priority to \(suggestion.rawValue)",
                        action: "Apply",
                        onAction: {
                            viewModel.applyAIPrioritySuggestion()
                        }
                    )
                }
                
                // Workflow Suggestions
                ForEach(viewModel.getWorkflowSuggestions().prefix(2), id: \.self) { suggestion in
                    SuggestionCard(
                        title: "Workflow Tip",
                        description: suggestion,
                        action: nil,
                        onAction: nil
                    )
                }
            }
        }
    }
}

struct SuggestionCard: View {
    let title: String
    let description: String
    let action: String?
    let onAction: (() -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appAccent)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let action = action, let onAction = onAction {
                Button(action) {
                    onAction()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.appAccent)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.appAccent.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Time Logging Section

struct TimeLoggingSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Tracking")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                TextField("Hours worked", text: $viewModel.timeLog)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                Button("Log Time") {
                    viewModel.logTime()
                }
                .disabled(viewModel.timeLog.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appAccent.opacity(viewModel.timeLog.isEmpty ? 0.3 : 1.0))
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            
            HStack {
                Text("Total logged: \(viewModel.actualDurationText())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Estimated: \(viewModel.estimatedDurationText())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Danger Zone

struct DangerZoneSection: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.appDanger)
            
            Button("Delete Task") {
                viewModel.showingDeleteConfirmation = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appDanger.opacity(0.1))
            .foregroundColor(.appDanger)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appDanger.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Supporting Views

struct MetadataCard: View {
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
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// iOS 15.6 Compatible FlowLayout replacement
struct FlowLayout {
    let spacing: CGFloat
    
    init(spacing: CGFloat) {
        self.spacing = spacing
    }
}

extension FlowLayout {
    func callAsFunction<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        FlowLayoutView(spacing: spacing, content: content())
    }
}

struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat, content: Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        // For iOS 15.6, we'll use a simple HStack with wrapping
        // This is a simplified version - in a real app you might want a more sophisticated layout
        content
    }
}

#Preview {
    TaskDetailView(
        task: TaskItem.sampleTasks[0],
        onUpdate: { _ in },
        onDelete: { _ in }
    )
}