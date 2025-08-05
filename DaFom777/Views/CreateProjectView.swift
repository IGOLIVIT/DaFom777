//
//  CreateProjectView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct CreateProjectView: View {
    let onSave: (Project) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var type: ProjectType = .development
    @State private var deadline: Date?
    @State private var hasDeadline = false
    @State private var estimatedHours = ""
    @State private var estimatedBudget = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingDatePicker = false
    @FocusState private var nameFocused: Bool
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter project name", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($nameFocused)
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
                        
                        // Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(ProjectType.allCases, id: \.self) { projectType in
                                    ProjectTypeButton(
                                        type: projectType,
                                        isSelected: type == projectType
                                    ) {
                                        type = projectType
                                    }
                                }
                            }
                        }
                        
                        // Deadline Section
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Set Deadline", isOn: $hasDeadline)
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                            
                            if hasDeadline {
                                Button {
                                    showingDatePicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.appAccent)
                                        
                                        Text(deadline?.formatted(style: .medium) ?? "Select Deadline")
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
                                    ProjectDatePickerView(selectedDate: Binding(
                                        get: { deadline ?? Date() },
                                        set: { deadline = $0 }
                                    ))
                                }
                            }
                        }
                        
                        // Estimates Section
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Estimated Hours")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., 40", text: $estimatedHours)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Budget (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("e.g., 5000", text: $estimatedBudget)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
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
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveProject()
                    }
                    .foregroundColor(.appAccent)
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            nameFocused = true
            estimatedHours = "40"
        }
        .onChange(of: hasDeadline) { hasDate in
            if hasDate && deadline == nil {
                deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            } else if !hasDate {
                deadline = nil
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
    
    private func saveProject() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let project = Project(
            name: trimmedName,
            description: description,
            type: type,
            deadline: hasDeadline ? deadline : nil,
            ownerId: UUID(), // In a real app, this would be the current user's ID
            tags: tags,
            estimatedBudget: estimatedBudget.isEmpty ? nil : Double(estimatedBudget),
            estimatedHours: Double(estimatedHours) ?? 40.0
        )
        
        onSave(project)
        dismiss()
    }
}

struct ProjectTypeButton: View {
    let type: ProjectType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .appAccent)
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black : .white)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.appAccent : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProjectDatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Project Deadline",
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
            .navigationTitle("Select Deadline")
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
    CreateProjectView { project in
        print("Created project: \(project.name)")
    }
}