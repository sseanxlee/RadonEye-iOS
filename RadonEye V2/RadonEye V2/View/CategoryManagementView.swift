//
//  CategoryManagementView.swift
//  RadonEye V2
//
//  Created by Assistant
//

import SwiftUI

// MARK: - Category Management View
struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var categoryManager = DeviceCategoryManager.shared
    @State private var showingAddCategory = false
    @State private var editingCategory: DeviceCategory?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ] : [
                        Color(red: 0.976, green: 0.984, blue: 0.996),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if categoryManager.categories.isEmpty {
                        // Empty state
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.secondary)
                            
                            Text("No Categories Yet")
                                .font(.custom("AeonikPro-Medium", size: 18))
                                .foregroundColor(.secondary)
                            
                            Text("Create categories to organize your devices by location")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        // Categories list
                        List {
                            ForEach(categoryManager.categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { category in
                                CategoryRow(
                                    category: category,
                                    onEdit: {
                                        editingCategory = category
                                    },
                                    onDelete: {
                                        categoryManager.deleteCategory(category)
                                    }
                                )
                            }
                            .onMove(perform: moveCategories)
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737)),
                
                trailing: Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                }
            )
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditView(category: nil) { newCategory in
                categoryManager.addCategory(newCategory)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditView(category: category) { updatedCategory in
                categoryManager.updateCategory(updatedCategory)
            }
        }
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        let sortedCategories = categoryManager.categories.sorted(by: { $0.sortOrder < $1.sortOrder })
        
        for index in source {
            if index < sortedCategories.count {
                let sourceIndex = categoryManager.categories.firstIndex(where: { $0.id == sortedCategories[index].id }) ?? index
                categoryManager.moveCategory(from: sourceIndex, to: destination)
            }
        }
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: DeviceCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon and color
            ZStack {
                Circle()
                    .fill(category.color.swiftUIColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(category.color.swiftUIColor)
            }
            
            // Category info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.custom("AeonikPro-Bold", size: 18))
                    .foregroundColor(.primary)
                
                Text("\(category.deviceMacAddresses.count) device\(category.deviceMacAddresses.count == 1 ? "" : "s")")
                    .font(.custom("AeonikPro-Regular", size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Category Edit View
struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    let category: DeviceCategory?
    let onSave: (DeviceCategory) -> Void
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: DeviceCategory.CategoryColor
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private var isEditing: Bool {
        category != nil
    }
    
    init(category: DeviceCategory?, onSave: @escaping (DeviceCategory) -> Void) {
        self.category = category
        self.onSave = onSave
        
        if let category = category {
            _name = State(initialValue: category.name)
            _selectedIcon = State(initialValue: category.icon)
            _selectedColor = State(initialValue: category.color)
        } else {
            _name = State(initialValue: "")
            _selectedIcon = State(initialValue: "house.fill")
            _selectedColor = State(initialValue: .blue)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ] : [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Category Preview
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(selectedColor.swiftUIColor.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(selectedColor.swiftUIColor)
                            }
                            
                            Text(name.isEmpty ? "Category Name" : name)
                                .font(.custom("AeonikPro-Bold", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category Name")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(.primary)
                            
                            TextField("e.g., Living Room", text: $name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose Icon")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                                ForEach(DeviceCategory.availableIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedIcon == icon ? selectedColor.swiftUIColor.opacity(0.15) : (isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white))
                                                .frame(height: 60)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedIcon == icon ? selectedColor.swiftUIColor : Color.clear, lineWidth: 2)
                                                )
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(selectedIcon == icon ? selectedColor.swiftUIColor : .secondary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose Color")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                                ForEach(DeviceCategory.CategoryColor.allCases, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(color.swiftUIColor)
                                                .frame(width: 50, height: 50)
                                            
                                            if selectedColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(.secondary),
                
                trailing: Button("Save") {
                    saveCategory()
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existingCategory = category {
            var updatedCategory = existingCategory
            updatedCategory.name = trimmedName
            updatedCategory.icon = selectedIcon
            updatedCategory.color = selectedColor
            onSave(updatedCategory)
        } else {
            let newCategory = DeviceCategory(
                name: trimmedName,
                icon: selectedIcon,
                color: selectedColor
            )
            onSave(newCategory)
        }
        
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    CategoryManagementView()
}
