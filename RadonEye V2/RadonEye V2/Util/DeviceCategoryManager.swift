//
//  DeviceCategoryManager.swift
//  RadonEye V2
//
//  Created by Assistant
//

import Foundation
import CoreBluetooth
import SwiftUI

// MARK: - Device Category Model
struct DeviceCategory: Codable, Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String
    var color: CategoryColor
    var deviceMacAddresses: Set<String> // Store MAC addresses of devices in this category
    var sortOrder: Int
    
    enum CategoryColor: String, CaseIterable, Codable {
        case blue = "blue"
        case green = "green"
        case orange = "orange"
        case purple = "purple"
        case red = "red"
        case teal = "teal"
        case indigo = "indigo"
        case pink = "pink"
        
        var swiftUIColor: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            case .red: return .red
            case .teal: return .teal
            case .indigo: return .indigo
            case .pink: return .pink
            }
        }
        
        var displayName: String {
            switch self {
            case .blue: return "Blue"
            case .green: return "Green"
            case .orange: return "Orange"
            case .purple: return "Purple"
            case .red: return "Red"
            case .teal: return "Teal"
            case .indigo: return "Indigo"
            case .pink: return "Pink"
            }
        }
    }
    
    init(name: String, icon: String = "house.fill", color: CategoryColor = .blue, sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.color = color
        self.deviceMacAddresses = Set<String>()
        self.sortOrder = sortOrder
    }
}

// MARK: - Device Category Manager
class DeviceCategoryManager: ObservableObject {
    static let shared = DeviceCategoryManager()
    
    @Published var categories: [DeviceCategory] = []
    
    private let userDefaults = UserDefaults.standard
    private let categoriesKey = "device_categories"
    private let deviceCategoryMappingKey = "device_category_mapping"
    
    private init() {
        loadCategories()
        createDefaultCategoriesIfNeeded()
    }
    
    // MARK: - Default Categories
    private func createDefaultCategoriesIfNeeded() {
        if categories.isEmpty {
            let defaultCategories = [
                DeviceCategory(name: "Living Room", icon: "sofa.fill", color: .blue, sortOrder: 0),
                DeviceCategory(name: "Bedroom", icon: "bed.double.fill", color: .purple, sortOrder: 1),
                DeviceCategory(name: "Basement", icon: "house.lodge.fill", color: .orange, sortOrder: 2),
                DeviceCategory(name: "Office", icon: "desktopcomputer", color: .green, sortOrder: 3),
                DeviceCategory(name: "Kitchen", icon: "fork.knife", color: .red, sortOrder: 4)
            ]
            
            categories = defaultCategories
            saveCategories()
        }
    }
    
    // MARK: - Category Management
    func addCategory(_ category: DeviceCategory) {
        var newCategory = category
        newCategory.sortOrder = categories.count
        categories.append(newCategory)
        saveCategories()
    }
    
    func updateCategory(_ category: DeviceCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: DeviceCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func moveCategory(from sourceIndex: Int, to destinationIndex: Int) {
        let category = categories.remove(at: sourceIndex)
        categories.insert(category, at: destinationIndex)
        
        // Update sort orders
        for (index, var cat) in categories.enumerated() {
            cat.sortOrder = index
            categories[index] = cat
        }
        
        saveCategories()
    }
    
    // MARK: - Device Assignment
    func assignDevice(_ device: NORScannedPeripheral, to category: DeviceCategory) {
        let deviceMac = getDeviceMacAddress(device)
        
        // Remove device from all other categories
        for i in categories.indices {
            categories[i].deviceMacAddresses.remove(deviceMac)
        }
        
        // Add device to the specified category
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].deviceMacAddresses.insert(deviceMac)
        }
        
        saveCategories()
    }
    
    func removeDeviceFromCategory(_ device: NORScannedPeripheral) {
        let deviceMac = getDeviceMacAddress(device)
        
        for i in categories.indices {
            categories[i].deviceMacAddresses.remove(deviceMac)
        }
        
        saveCategories()
    }
    
    func getCategoryForDevice(_ device: NORScannedPeripheral) -> DeviceCategory? {
        let deviceMac = getDeviceMacAddress(device)
        return categories.first { $0.deviceMacAddresses.contains(deviceMac) }
    }
    
    func getDevicesInCategory(_ category: DeviceCategory, from allDevices: [NORScannedPeripheral]) -> [NORScannedPeripheral] {
        return allDevices.filter { device in
            let deviceMac = getDeviceMacAddress(device)
            return category.deviceMacAddresses.contains(deviceMac)
        }
    }
    
    func getUncategorizedDevices(from allDevices: [NORScannedPeripheral]) -> [NORScannedPeripheral] {
        return allDevices.filter { device in
            getCategoryForDevice(device) == nil
        }
    }
    
    // MARK: - Helper Methods
    private func getDeviceMacAddress(_ device: NORScannedPeripheral) -> String {
        // Use the device's identifier as a unique key since MAC address isn't directly accessible
        return device.peripheral.identifier.uuidString
    }
    
    // MARK: - Persistence
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            userDefaults.set(data, forKey: categoriesKey)
            MyUtil.printProcess(inMsg: "DeviceCategoryManager - Categories saved successfully")
        } catch {
            MyUtil.printProcess(inMsg: "DeviceCategoryManager - Failed to save categories: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let data = userDefaults.data(forKey: categoriesKey) else {
            MyUtil.printProcess(inMsg: "DeviceCategoryManager - No saved categories found")
            return
        }
        
        do {
            categories = try JSONDecoder().decode([DeviceCategory].self, from: data)
            MyUtil.printProcess(inMsg: "DeviceCategoryManager - Loaded \(categories.count) categories")
        } catch {
            MyUtil.printProcess(inMsg: "DeviceCategoryManager - Failed to load categories: \(error)")
            categories = []
        }
    }
}

// MARK: - Category Icons
extension DeviceCategory {
    static let availableIcons = [
        "house.fill", "sofa.fill", "bed.double.fill", "house.lodge.fill",
        "desktopcomputer", "fork.knife", "shower.fill", "car.garage.closed",
        "building.2.fill", "building.fill", "storefront.fill", "graduationcap.fill",
        "cross.case.fill", "gym.bag.fill", "leaf.fill", "tree.fill"
    ]
    
    static let iconDisplayNames: [String: String] = [
        "house.fill": "Home",
        "sofa.fill": "Living Room",
        "bed.double.fill": "Bedroom",
        "house.lodge.fill": "Basement",
        "desktopcomputer": "Office",
        "fork.knife": "Kitchen",
        "shower.fill": "Bathroom",
        "car.garage.closed": "Garage",
        "building.2.fill": "Apartment",
        "building.fill": "Office Building",
        "storefront.fill": "Store",
        "graduationcap.fill": "School",
        "cross.case.fill": "Hospital",
        "gym.bag.fill": "Gym",
        "leaf.fill": "Garden",
        "tree.fill": "Outdoor"
    ]
}
