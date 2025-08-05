//
//  TaskDetailViewModel.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import Foundation
import SwiftUI
import Combine

class TaskDetailViewModel: ObservableObject {
    @Published var task: TaskItem
    @Published var isEditing = false
    @Published var showingDeleteConfirmation = false
    @Published var showingDatePicker = false
    @Published var showingPriorityPicker = false
    @Published var showingStatusPicker = false
    @Published var showingComplexityPicker = false
    @Published var showingProjectPicker = false
    @Published var showingCollaboratorPicker = false
    @Published var newSubtask = ""
    @Published var newTag = ""
    @Published var timeLog = ""
    @Published var notes = ""
    @Published var attachments: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Form fields for editing
    @Published var editingTitle: String
    @Published var editingDescription: String
    @Published var editingPriority: TaskPriority
    @Published var editingStatus: TaskStatus
    @Published var editingComplexity: TaskComplexity
    @Published var editingDueDate: Date?
    @Published var editingEstimatedHours: String
    @Published var editingTags: [String]
    @Published var editingSubtasks: [String]
    
    private let taskService = TaskService()
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Dependency injection for testing
    var onTaskUpdated: ((TaskItem) -> Void)?
    var onTaskDeleted: ((TaskItem) -> Void)?
    
    init(task: TaskItem) {
        self.task = task
        
        // Initialize editing fields
        self.editingTitle = task.title
        self.editingDescription = task.description
        self.editingPriority = task.priority
        self.editingStatus = task.status
        self.editingComplexity = task.complexity
        self.editingDueDate = task.dueDate
        self.editingEstimatedHours = String(task.estimatedHours)
        self.editingTags = task.tags
        self.editingSubtasks = task.subtasks
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Watch for changes to determine if form is dirty
        Publishers.CombineLatest4(
            $editingTitle,
            $editingDescription,
            $editingPriority,
            $editingStatus
        )
        .sink { [weak self] _, _, _, _ in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var hasUnsavedChanges: Bool {
        return editingTitle != task.title ||
               editingDescription != task.description ||
               editingPriority != task.priority ||
               editingStatus != task.status ||
               editingComplexity != task.complexity ||
               editingDueDate != task.dueDate ||
               editingEstimatedHours != String(task.estimatedHours) ||
               editingTags != task.tags ||
               editingSubtasks != task.subtasks
    }
    
    var formIsValid: Bool {
        return !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               Double(editingEstimatedHours) != nil
    }
    
    var aiPrioritySuggestion: TaskPriority? {
        return aiService.suggestPriorityAdjustment(for: task)
    }
    
    var projectName: String? {
        guard let projectId = task.projectId else { return nil }
        return taskService.projects.first { $0.id == projectId }?.name
    }
    
    var progressPercentage: Double {
        return task.progressPercentage
    }
    
    var timeRemaining: String {
        guard let dueDate = task.dueDate else { return "No deadline" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if dueDate < now {
            let components = calendar.dateComponents([.day, .hour], from: dueDate, to: now)
            let days = components.day ?? 0
            let hours = components.hour ?? 0
            
            if days > 0 {
                return "\(days) day\(days != 1 ? "s" : "") overdue"
            } else {
                return "\(hours) hour\(hours != 1 ? "s" : "") overdue"
            }
        } else {
            let components = calendar.dateComponents([.day, .hour], from: now, to: dueDate)
            let days = components.day ?? 0
            let hours = components.hour ?? 0
            
            if days > 0 {
                return "\(days) day\(days != 1 ? "s" : "") remaining"
            } else {
                return "\(hours) hour\(hours != 1 ? "s" : "") remaining"
            }
        }
    }
    
    // MARK: - Actions
    
    func toggleEditing() {
        if isEditing && hasUnsavedChanges {
            // Show confirmation dialog
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing.toggle()
        }
        
        if !isEditing {
            // Reset editing fields to original values
            resetEditingFields()
        }
    }
    
    func saveChanges() {
        guard formIsValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        
        // Create updated task
        var updatedTask = task
        updatedTask.title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.description = editingDescription
        updatedTask.priority = editingPriority
        updatedTask.status = editingStatus
        updatedTask.complexity = editingComplexity
        updatedTask.dueDate = editingDueDate
        updatedTask.estimatedHours = Double(editingEstimatedHours) ?? task.estimatedHours
        updatedTask.tags = editingTags
        updatedTask.subtasks = editingSubtasks
        
        // Update completion date if status changed to completed
        if editingStatus == .completed && task.status != .completed {
            updatedTask.completedDate = Date()
        } else if editingStatus != .completed {
            updatedTask.completedDate = nil
        }
        
        // Update AI priority score
        updatedTask.aiPriorityScore = aiService.calculatePriorityScore(for: updatedTask)
        
        // Save the task
        taskService.updateTask(updatedTask)
        
        // Update local task
        self.task = updatedTask
        
        // Notify parent
        onTaskUpdated?(updatedTask)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
            isLoading = false
        }
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func discardChanges() {
        resetEditingFields()
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
        }
    }
    
    func deleteTask() {
        taskService.deleteTask(task)
        onTaskDeleted?(task)
    }
    
    func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .todo : .completed
        updatedTask.completedDate = task.status == .completed ? nil : Date()
        
        taskService.updateTask(updatedTask)
        self.task = updatedTask
        
        // Update editing status if needed
        editingStatus = updatedTask.status
        
        onTaskUpdated?(updatedTask)
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // MARK: - Subtasks
    
    func addSubtask() {
        let trimmed = newSubtask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        editingSubtasks.append(trimmed)
        newSubtask = ""
    }
    
    func removeSubtask(at index: Int) {
        guard index < editingSubtasks.count else { return }
        editingSubtasks.remove(at: index)
    }
    
    func moveSubtask(from source: IndexSet, to destination: Int) {
        editingSubtasks.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Tags
    
    func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !editingTags.contains(trimmed) else { return }
        
        editingTags.append(trimmed)
        newTag = ""
    }
    
    func removeTag(_ tag: String) {
        editingTags.removeAll { $0 == tag }
    }
    
    // MARK: - Time Tracking
    
    func logTime() {
        guard let hours = Double(timeLog), hours > 0 else {
            errorMessage = "Please enter valid hours"
            return
        }
        
        var updatedTask = task
        updatedTask.actualHours += hours
        
        taskService.updateTask(updatedTask)
        self.task = updatedTask
        
        timeLog = ""
        onTaskUpdated?(updatedTask)
        
        // Show confirmation
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - AI Suggestions
    
    func applyAIPrioritySuggestion() {
        guard let suggestion = aiPrioritySuggestion else { return }
        
        editingPriority = suggestion
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func getWorkflowSuggestions() -> [String] {
        // In a real app, this would call the AI service
        var suggestions: [String] = []
        
        if task.subtasks.count > 5 {
            suggestions.append("Consider breaking this task into multiple smaller tasks")
        }
        
        if task.estimatedHours > 16 {
            suggestions.append("Large tasks often benefit from weekly progress check-ins")
        }
        
        if task.collaborators.count > 3 {
            suggestions.append("Consider assigning a lead collaborator for coordination")
        }
        
        if task.dueDate != nil && task.dueDate! < Date() {
            suggestions.append("Update the deadline or mark as completed if finished")
        }
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func resetEditingFields() {
        editingTitle = task.title
        editingDescription = task.description
        editingPriority = task.priority
        editingStatus = task.status
        editingComplexity = task.complexity
        editingDueDate = task.dueDate
        editingEstimatedHours = String(task.estimatedHours)
        editingTags = task.tags
        editingSubtasks = task.subtasks
    }
    
    // MARK: - Attachments
    
    func addAttachment(_ attachment: String) {
        if !attachments.contains(attachment) {
            attachments.append(attachment)
        }
    }
    
    func removeAttachment(_ attachment: String) {
        attachments.removeAll { $0 == attachment }
    }
    
    // MARK: - Comments/Notes
    
    func addNote() {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // In a real app, you would save this note with timestamp and user info
        print("Added note: \(trimmed)")
        notes = ""
    }
    
    // MARK: - Duration Helpers
    
    func formatDuration(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        } else if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))h"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)h \(m)m"
        }
    }
    
    func estimatedDurationText() -> String {
        return formatDuration(task.estimatedHours)
    }
    
    func actualDurationText() -> String {
        return formatDuration(task.actualHours)
    }
}