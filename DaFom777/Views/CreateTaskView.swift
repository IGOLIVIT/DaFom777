//
//  CreateTaskView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct CreateTaskView: View {
    let onSave: (TaskItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var complexity: TaskComplexity = .moderate
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var estimatedHours = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingDatePicker = false
    @FocusState private var titleFocused: Bool
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter task title", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($titleFocused)
                        }
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Add a description (optional)", text: $description)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(4)
                        }
                        
                        // Priority and Complexity
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priority")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Menu {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        Button(p.rawValue) {
                                            priority = p
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(priority.rawValue)
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
                                Text("Complexity")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Menu {
                                    ForEach(TaskComplexity.allCases, id: \.self) { c in
                                        Button(c.rawValue) {
                                            complexity = c
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(complexity.rawValue)
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
                        
                        // Due Date Section
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Set Due Date", isOn: $hasDueDate)
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                            
                            if hasDueDate {
                                Button {
                                    showingDatePicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.appAccent)
                                        
                                        Text(dueDate?.formatted(style: .medium) ?? "Select Date")
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .sheet(isPresented: $showingDatePicker) {
                                    DatePickerView(selectedDate: Binding(
                                        get: { dueDate ?? Date() },
                                        set: { dueDate = $0 }
                                    ))
                                }
                            }
                        }
                        
                        // Estimated Hours
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Hours")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("e.g., 2.5", text: $estimatedHours)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        
                        // Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button("Add") {
                                    addTag()
                                }
                                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.appAccent.opacity(newTag.isEmpty ? 0.3 : 1.0))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                            }
                            
                            if !tags.isEmpty {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        TagView(tag: tag) {
                                            removeTag(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .foregroundColor(.appAccent)
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            titleFocused = true
            estimatedHours = String(complexity.estimatedHours)
        }
        .onChange(of: complexity) { newComplexity in
            if estimatedHours.isEmpty || Double(estimatedHours) == nil {
                estimatedHours = String(newComplexity.estimatedHours)
            }
        }
        .onChange(of: hasDueDate) { hasDate in
            if hasDate && dueDate == nil {
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            } else if !hasDate {
                dueDate = nil
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !tags.contains(trimmed) else { return }
        
        tags.append(trimmed)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let task = TaskItem(
            title: trimmedTitle,
            description: description,
            priority: priority,
            complexity: complexity,
            dueDate: hasDueDate ? dueDate : nil,
            tags: tags,
            estimatedHours: Double(estimatedHours) ?? complexity.estimatedHours
        )
        
        onSave(task)
        dismiss()
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.white)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.appAccent.opacity(0.7))
        .cornerRadius(12)
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Due Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .accentColor(.appAccent)
                
                Spacer()
            }
            .padding()
            .background(Color.appBackground)
            .navigationTitle("Select Due Date")
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

#Preview {
    CreateTaskView { task in
        print("Created task: \(task.title)")
    }
}