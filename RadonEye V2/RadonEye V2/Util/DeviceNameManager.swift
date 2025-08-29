import Foundation

// MARK: - Device Name Manager
class DeviceNameManager: ObservableObject {
    static let shared = DeviceNameManager()
    
    private let userDefaults = UserDefaults.standard
    private let deviceNamesKey = "CustomDeviceNames"
    
    @Published private var customNames: [String: String] = [:]
    
    private init() {
        loadCustomNames()
    }
    
    // MARK: - Private Methods
    
    private func loadCustomNames() {
        if let savedNames = userDefaults.dictionary(forKey: deviceNamesKey) as? [String: String] {
            customNames = savedNames
        }
    }
    
    private func saveCustomNames() {
        userDefaults.set(customNames, forKey: deviceNamesKey)
        userDefaults.synchronize()
    }
    
    // MARK: - Public Methods
    
    func getDisplayName(for device: NORScannedPeripheral) -> String {
        let deviceId = getDeviceIdentifier(for: device)
        return customNames[deviceId] ?? device.realName
    }
    
    func getCustomName(for device: NORScannedPeripheral) -> String? {
        let deviceId = getDeviceIdentifier(for: device)
        return customNames[deviceId]
    }
    
    func setCustomName(_ name: String, for device: NORScannedPeripheral) {
        let deviceId = getDeviceIdentifier(for: device)
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Remove custom name if empty
            customNames.removeValue(forKey: deviceId)
        } else {
            customNames[deviceId] = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        saveCustomNames()
        objectWillChange.send()
    }
    
    func removeCustomName(for device: NORScannedPeripheral) {
        let deviceId = getDeviceIdentifier(for: device)
        customNames.removeValue(forKey: deviceId)
        saveCustomNames()
        objectWillChange.send()
    }
    
    func hasCustomName(for device: NORScannedPeripheral) -> Bool {
        let deviceId = getDeviceIdentifier(for: device)
        return customNames[deviceId] != nil
    }
    
    private func getDeviceIdentifier(for device: NORScannedPeripheral) -> String {
        // Use the original real name as the unique identifier
        // This ensures the custom name persists even if RSSI changes
        return device.realName
    }
    
    // MARK: - Debug Methods
    
    func getAllCustomNames() -> [String: String] {
        return customNames
    }
    
    func clearAllCustomNames() {
        customNames.removeAll()
        saveCustomNames()
        objectWillChange.send()
    }
} 