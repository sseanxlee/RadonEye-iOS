import SwiftUI
import CoreBluetooth
import Combine

// MARK: - SwiftUI Device List View
struct DeviceListView: View {
    let onBack: () -> Void
    let onDeviceSelected: (NORScannedPeripheral, BLEControl) -> Void
    let showInlineHeader: Bool
    let onSettingsPressed: (() -> Void)?
    
    init(onBack: @escaping () -> Void, 
         onDeviceSelected: @escaping (NORScannedPeripheral, BLEControl) -> Void,
         showInlineHeader: Bool = false,
         onSettingsPressed: (() -> Void)? = nil) {
        self.onBack = onBack
        self.onDeviceSelected = onDeviceSelected
        self.showInlineHeader = showInlineHeader
        self.onSettingsPressed = onSettingsPressed
    }
    
    @StateObject private var bluetoothManager = BluetoothScanManager()
    @StateObject private var deviceNameManager = DeviceNameManager.shared
    @StateObject private var categoryManager = DeviceCategoryManager.shared
    @State private var showingBluetoothAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedDevice: (NORScannedPeripheral, BLEControl)?
    @State private var navigateToMonitoring = false
    @State private var showingRenameAlert = false
    @State private var deviceToRename: NORScannedPeripheral?
    @State private var newDeviceName = ""
    @State private var showingCategoryManagement = false
    @State private var showingDeviceAssignment = false
    @State private var deviceToAssign: NORScannedPeripheral?
    @State private var selectedFilter: FilterOption = .allDevices
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum FilterOption: Equatable {
        case allDevices
        case category(DeviceCategory)
        
        var displayName: String {
            switch self {
            case .allDevices:
                return "All Devices"
            case .category(let category):
                return category.name
            }
        }
        
        var icon: String {
            switch self {
            case .allDevices:
                return "square.grid.2x2"
            case .category(let category):
                return category.icon
            }
        }
        
        var color: Color {
            switch self {
            case .allDevices:
                return Color(red: 0.156, green: 0.459, blue: 0.737)
            case .category(let category):
                return category.color.swiftUIColor
            }
        }
    }
    
    private func getFilteredDevices() -> [NORScannedPeripheral] {
        switch selectedFilter {
        case .allDevices:
            // Show all devices, categorized first then uncategorized
            let categorizedDevices = categoryManager.categories
                .sorted(by: { $0.sortOrder < $1.sortOrder })
                .flatMap { category in
                    categoryManager.getDevicesInCategory(category, from: bluetoothManager.peripherals)
                        .sorted(by: { deviceNameManager.getDisplayName(for: $0) < deviceNameManager.getDisplayName(for: $1) })
                }
            
            let uncategorizedDevices = categoryManager.getUncategorizedDevices(from: bluetoothManager.peripherals)
                .sorted(by: { deviceNameManager.getDisplayName(for: $0) < deviceNameManager.getDisplayName(for: $1) })
            
            return categorizedDevices + uncategorizedDevices
            
        case .category(let category):
            // Show only devices in the selected category
            return categoryManager.getDevicesInCategory(category, from: bluetoothManager.peripherals)
                .sorted(by: { deviceNameManager.getDisplayName(for: $0) < deviceNameManager.getDisplayName(for: $1) })
        }
    }
    
    private var availableFilters: [FilterOption] {
        var filters: [FilterOption] = [.allDevices]
        
        // Add category filters for categories that have devices
        for category in categoryManager.categories.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let devicesInCategory = categoryManager.getDevicesInCategory(category, from: bluetoothManager.peripherals)
            if !devicesInCategory.isEmpty {
                filters.append(.category(category))
            }
        }
        
        return filters
    }
    
    var body: some View {
        ZStack {
                // Background gradient with dark mode support
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
                    // Header - inline version with title and buttons, or just category button
                    HStack {
                        if showInlineHeader {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Devices")
                                    .font(.custom("AeonikPro-Bold", size: 18))
                                    .foregroundColor(.primary)
                                
                                Text("Available RadonEye devices")
                                    .font(.custom("AeonikPro-Regular", size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Settings button (only for inline header)
                        if showInlineHeader, let settingsAction = onSettingsPressed {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                settingsAction()
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                            }
                        }
                        
                        // Three-line menu button (category management)
                        Button(action: {
                            showingCategoryManagement = true
                        }) {
                            VStack(spacing: 3) {
                                Rectangle()
                                    .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(width: 18, height: 2)
                                Rectangle()
                                    .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(width: 18, height: 2)
                                Rectangle()
                                    .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(width: 18, height: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white.opacity(0.8))
                    
                    // Horizontal scrollable filter bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableFilters.indices, id: \.self) { index in
                                let filter = availableFilters[index]
                                
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    selectedFilter = filter
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: filter.icon)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedFilter == filter ? .white : filter.color)
                                        
                                        Text(filter.displayName)
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(selectedFilter == filter ? .white : filter.color)
                                        
                                        // Show device count for categories
                                        if case .category(let category) = filter {
                                            let deviceCount = categoryManager.getDevicesInCategory(category, from: bluetoothManager.peripherals).count
                                            Text("\(deviceCount)")
                                                .font(.custom("AeonikPro-Bold", size: 12))
                                                .foregroundColor(selectedFilter == filter ? .white : filter.color.opacity(0.7))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(selectedFilter == filter ? Color.white.opacity(0.2) : filter.color.opacity(0.1))
                                                )
                                        } else {
                                            // Show total device count for "All Devices"
                                            Text("\(bluetoothManager.peripherals.count)")
                                                .font(.custom("AeonikPro-Bold", size: 12))
                                                .foregroundColor(selectedFilter == filter ? .white : filter.color.opacity(0.7))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(selectedFilter == filter ? Color.white.opacity(0.2) : filter.color.opacity(0.1))
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedFilter == filter ? filter.color : filter.color.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white.opacity(0.8))
                    
                    Divider()
                        .opacity(0.3)
                    
                    // Device list content
                    if bluetoothManager.peripherals.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.secondary)
                            
                            Text("Searching for devices...")
                                .font(.custom("AeonikPro-Medium", size: 18))
                                .foregroundColor(.secondary)
                            
                            Text("Make sure your RadonEye device is powered on and nearby")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Get filtered devices based on selected filter
                                let filteredDevices = getFilteredDevices()
                                
                                ForEach(filteredDevices.indices, id: \.self) { index in
                                    let device = filteredDevices[index]
                                    if let originalIndex = bluetoothManager.peripherals.firstIndex(of: device) {
                                        EnhancedDeviceRow(
                                            device: device,
                                            deviceNameManager: deviceNameManager,
                                            categoryManager: categoryManager,
                                            onTap: {
                                                let cbPeripheral = bluetoothManager.cbPeripherals[originalIndex]
                                                let bleController = BLEControl(
                                                    withCBCentralManager: bluetoothManager.centralManager,
                                                    withPeripheral: cbPeripheral
                                                )
                                                selectedDevice = (device, bleController)
                                                navigateToMonitoring = true
                                            },
                                            onLongPress: {
                                                deviceToRename = device
                                                newDeviceName = deviceNameManager.getCustomName(for: device) ?? ""
                                                showingRenameAlert = true
                                            },
                                            onAssignCategory: {
                                                deviceToAssign = device
                                                showingDeviceAssignment = true
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        }
                    }
                }
            }
        .navigationTitle("Device List")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onBack()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.custom("AeonikPro-Medium", size: 16))
                    }
                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            bluetoothManager.startScanning()
            bluetoothManager.onBluetoothError = { title, message in
                alertTitle = title
                alertMessage = message
                showingBluetoothAlert = true
            }
        }
        .onDisappear {
            // Keep scanning running like old implementation - only stop when really leaving the app
            // bluetoothManager.stopScanning()
        }
        .alert(alertTitle, isPresented: $showingBluetoothAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Rename Device", isPresented: $showingRenameAlert) {
            TextField("Device Name", text: $newDeviceName)
                .textInputAutocapitalization(.words)
            
            Button("Save") {
                if let device = deviceToRename {
                    deviceNameManager.setCustomName(newDeviceName, for: device)
                }
                deviceToRename = nil
                newDeviceName = ""
            }
            .disabled(newDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Button("Remove Custom Name", role: .destructive) {
                if let device = deviceToRename {
                    deviceNameManager.removeCustomName(for: device)
                }
                deviceToRename = nil
                newDeviceName = ""
            }
            
            Button("Cancel", role: .cancel) {
                deviceToRename = nil
                newDeviceName = ""
            }
        } message: {
            if let device = deviceToRename {
                Text("Enter a custom name for \(device.realName)")
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let (peripheral, bleController) = selectedDevice {
                        MonitoringView(
                            peripheral: peripheral,
                            bleController: bleController
                        )
                    } else {
                        EmptyView()
                    }
                },
                isActive: $navigateToMonitoring
            ) {
                EmptyView()
            }
        )
        .onChange(of: navigateToMonitoring) { newValue in
            if !newValue {
                selectedDevice = nil
            }
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
        }
        .sheet(isPresented: $showingDeviceAssignment) {
            if let device = deviceToAssign {
                DeviceAssignmentView(device: device) { category in
                    if let category = category {
                        categoryManager.assignDevice(device, to: category)
                    } else {
                        categoryManager.removeDeviceFromCategory(device)
                    }
                    deviceToAssign = nil
                }
            }
        }
    }
}

// MARK: - Device Row Component
struct DeviceRow: View {
    let device: NORScannedPeripheral
    let deviceNameManager: DeviceNameManager
    let onTap: () -> Void
    let onLongPress: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private func signalStrengthImage(rssi: Int32) -> String {
        if rssi < -90 {
            return "Signal_0"
        } else if rssi < -70 {
            return "Signal_1"
        } else if rssi < -50 {
            return "Signal_2"
        } else {
            return "Signal_3"
        }
    }
    
    private func signalStrengthSystemImage(rssi: Int32) -> String {
        if rssi < -90 {
            return "wifi.slash"
        } else if rssi < -70 {
            return "wifi"
        } else if rssi < -50 {
            return "wifi"
        } else {
            return "wifi"
        }
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Signal strength icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if device.isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        // Try to load custom signal images, fallback to system icons
                        if let image = UIImage(named: signalStrengthImage(rssi: device.RSSI)) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: signalStrengthSystemImage(rssi: device.RSSI))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        }
                    }
                }
                
                // Device info
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        // Custom name (if exists) or original name
                        Text(deviceNameManager.getDisplayName(for: device))
                            .font(.custom("AeonikPro-Bold", size: 18))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Show original name in smaller grey font if custom name exists
                        if deviceNameManager.hasCustomName(for: device) {
                            Text(device.realName)
                                .font(.custom("AeonikPro-Regular", size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text("RSSI: \(device.RSSI) dBm")
                            .font(.custom("AeonikPro-Regular", size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if device.isConnected {
                            Text("Connected")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            Text("Available")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            onLongPress()
        }
    }
}

// MARK: - Bluetooth Scan Manager
class BluetoothScanManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    private let tag = "BluetoothScanManager - "
    
    @Published var peripherals: [NORScannedPeripheral] = []
    @Published var isScanning = false
    var cbPeripherals: [CBPeripheral] = []
    
    var centralManager: CBCentralManager!
    private var scanTimer: Timer?
    
    var onBluetoothError: ((String, String) -> Void)?
    
    override init() {
        super.init()
        // Don't initialize CBCentralManager here - wait for startScanning like old implementation
    }
    
    func startScanning() {
        MyUtil.printProcess(inMsg: tag + "startScanning requested")
        
        // Initialize CBCentralManager if not already done (like old implementation in viewWillAppear)
        if centralManager == nil {
            let centralQueue = DispatchQueue(label: "kr.ftlab.radoneye.RaonEye", attributes: [])
            centralManager = CBCentralManager(delegate: self, queue: centralQueue)
            // Clear devices when first initializing
            self.peripherals.removeAll()
            self.cbPeripherals.removeAll()
            MyUtil.printProcess(inMsg: tag + "CBCentralManager initialized")
            return // Wait for centralManagerDidUpdateState to start scanning
        }
        
        guard centralManager != nil && centralManager.state == .poweredOn else {
            MyUtil.printProcess(inMsg: tag + "Bluetooth not ready, centralManager: \(centralManager?.state.rawValue ?? -1)")
            return
        }
        
        guard !isScanning else {
            MyUtil.printProcess(inMsg: tag + "Already scanning, skipping")
            return
        }
        
        DispatchQueue.main.async {
            self.isScanning = true
            
            // Use NSDictionary format like old implementation
            let options: NSDictionary = NSDictionary(objects: [NSNumber(value: true as Bool)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying])
            self.centralManager.scanForPeripherals(withServices: nil, options: options as? [String : AnyObject])
            
            // Start update timer like old implementation - continuous UI refresh
            self.scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    // Force UI update to keep device list fresh (like old implementation)
                    self.objectWillChange.send()
                }
            }
            
            MyUtil.printProcess(inMsg: self.tag + "scanning started")
        }
    }
    
    func stopScanning() {
        MyUtil.printProcess(inMsg: tag + "stopScanning")
        centralManager?.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        
        DispatchQueue.main.async {
            self.isScanning = false
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MyUtil.printProcess(inMsg: tag + "centralManagerDidUpdateState: \(central.state.rawValue)")
        
        DispatchQueue.main.async {
            guard central.state == .poweredOn else {
                self.isScanning = false
                
                let title = "ble_off_title".localized
                let message = "ble_off_msg".localized
                self.onBluetoothError?(title, message)
                return
            }
            
            // Auto-start scanning when powered on (like old implementation)
            if !self.isScanning {
                self.startScanning()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            var viewName = ""
            var flagCheck = false
            var flagV3 = false
            
            // Check for FR:R20: pattern
            if localName.range(of: "FR:R20:") != nil {
                let tempName = localName.replacingOccurrences(of: ".", with: "")
                viewName = "RD200/" + String(tempName.dropFirst(7))
                flagCheck = true
            }
            
            // Check for DfuTarg
            if localName.range(of: "DfuTarg") != nil {
                viewName = localName
                flagCheck = true
            }
            
            // Check for V3 devices (RE pattern)
            if let range = localName.range(of: "RE") {
                if localName.count > 10 {
                    let startIndex = localName.index(localName.startIndex, offsetBy: 7)
                    let endIndex = localName.index(localName.startIndex, offsetBy: 9)
                    let findStr = String(localName[startIndex..<endIndex])
                    
                    if findStr == "RE" {
                        viewName = "RD200/SN" + String(localName.dropFirst(11))
                        flagV3 = true
                        flagCheck = true
                    }
                }
            }
            
            // Skip RadonEye Pro devices
            if localName.range(of: "FR:RP2") != nil && !flagCheck {
                return
            }
            
            // Check for other FR:R patterns
            if localName.range(of: "FR:R") != nil && !flagCheck {
                if localName.count >= 12 {
                    let index = localName.index(localName.startIndex, offsetBy: 5)
                    if localName[index] == "2" {
                        let tempName = localName.replacingOccurrences(of: ".", with: "")
                        viewName = "RD200/SN" + String(tempName.dropFirst(12))
                        flagCheck = true
                    }
                }
            }
            
            if flagCheck {
                let scannedPeripheral = NORScannedPeripheral(
                    withPeripheral: peripheral,
                    andRSSI: RSSI.int32Value,
                    andIsConnected: false,
                    advertisementData: viewName,
                    inV3: flagV3
                )
                
                if let existingIndex = self.peripherals.firstIndex(of: scannedPeripheral) {
                    // Update existing peripheral
                    self.peripherals[existingIndex].RSSI = RSSI.int32Value
                    self.peripherals[existingIndex].realName = viewName
                } else {
                    // Add new peripheral
                    self.peripherals.append(scannedPeripheral)
                    self.cbPeripherals.append(peripheral)
                }
            }
        }
    }
}

// MARK: - Categorized Device List
struct CategorizedDeviceList: View {
    let devices: [NORScannedPeripheral]
    let cbPeripherals: [CBPeripheral]
    let centralManager: CBCentralManager
    let onDeviceSelected: (NORScannedPeripheral, BLEControl) -> Void
    let onDeviceRename: (NORScannedPeripheral) -> Void
    let onDeviceAssign: (NORScannedPeripheral) -> Void
    
    @StateObject private var categoryManager = DeviceCategoryManager.shared
    @StateObject private var deviceNameManager = DeviceNameManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Categories with devices
                ForEach(categoryManager.categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { category in
                    let categoryDevices = categoryManager.getDevicesInCategory(category, from: devices)
                    
                    if !categoryDevices.isEmpty {
                        CategorySection(
                            category: category,
                            devices: categoryDevices,
                            cbPeripherals: cbPeripherals,
                            centralManager: centralManager,
                            onDeviceSelected: onDeviceSelected,
                            onDeviceRename: onDeviceRename,
                            onDeviceAssign: onDeviceAssign
                        )
                    }
                }
                
                // Uncategorized devices
                let uncategorizedDevices = categoryManager.getUncategorizedDevices(from: devices)
                if !uncategorizedDevices.isEmpty {
                    UncategorizedSection(
                        devices: uncategorizedDevices,
                        cbPeripherals: cbPeripherals,
                        centralManager: centralManager,
                        onDeviceSelected: onDeviceSelected,
                        onDeviceRename: onDeviceRename,
                        onDeviceAssign: onDeviceAssign
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: DeviceCategory
    let devices: [NORScannedPeripheral]
    let cbPeripherals: [CBPeripheral]
    let centralManager: CBCentralManager
    let onDeviceSelected: (NORScannedPeripheral, BLEControl) -> Void
    let onDeviceRename: (NORScannedPeripheral) -> Void
    let onDeviceAssign: (NORScannedPeripheral) -> Void
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.swiftUIColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(category.color.swiftUIColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.custom("AeonikPro-Bold", size: 20))
                        .foregroundColor(.primary)
                    
                    Text("\(devices.count) device\(devices.count == 1 ? "" : "s")")
                        .font(.custom("AeonikPro-Regular", size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Devices in category
            VStack(spacing: 8) {
                ForEach(devices.indices, id: \.self) { index in
                    if let deviceIndex = findDeviceIndex(device: devices[index]) {
                        EnhancedDeviceRow(
                            device: devices[index],
                            deviceNameManager: DeviceNameManager.shared,
                            categoryManager: DeviceCategoryManager.shared,
                            onTap: {
                                let cbPeripheral = cbPeripherals[deviceIndex]
                                let bleController = BLEControl(
                                    withCBCentralManager: centralManager,
                                    withPeripheral: cbPeripheral
                                )
                                onDeviceSelected(devices[index], bleController)
                            },
                            onLongPress: {
                                onDeviceRename(devices[index])
                            },
                            onAssignCategory: {
                                onDeviceAssign(devices[index])
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func findDeviceIndex(device: NORScannedPeripheral) -> Int? {
        return cbPeripherals.firstIndex { $0.identifier == device.peripheral.identifier }
    }
}

// MARK: - Uncategorized Section
struct UncategorizedSection: View {
    let devices: [NORScannedPeripheral]
    let cbPeripherals: [CBPeripheral]
    let centralManager: CBCentralManager
    let onDeviceSelected: (NORScannedPeripheral, BLEControl) -> Void
    let onDeviceRename: (NORScannedPeripheral) -> Void
    let onDeviceAssign: (NORScannedPeripheral) -> Void
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Uncategorized header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uncategorized")
                        .font(.custom("AeonikPro-Bold", size: 20))
                        .foregroundColor(.primary)
                    
                    Text("\(devices.count) device\(devices.count == 1 ? "" : "s")")
                        .font(.custom("AeonikPro-Regular", size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Uncategorized devices
            VStack(spacing: 8) {
                ForEach(devices.indices, id: \.self) { index in
                    if let deviceIndex = findDeviceIndex(device: devices[index]) {
                        EnhancedDeviceRow(
                            device: devices[index],
                            deviceNameManager: DeviceNameManager.shared,
                            categoryManager: DeviceCategoryManager.shared,
                            onTap: {
                                let cbPeripheral = cbPeripherals[deviceIndex]
                                let bleController = BLEControl(
                                    withCBCentralManager: centralManager,
                                    withPeripheral: cbPeripheral
                                )
                                onDeviceSelected(devices[index], bleController)
                            },
                            onLongPress: {
                                onDeviceRename(devices[index])
                            },
                            onAssignCategory: {
                                onDeviceAssign(devices[index])
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func findDeviceIndex(device: NORScannedPeripheral) -> Int? {
        return cbPeripherals.firstIndex { $0.identifier == device.peripheral.identifier }
    }
}

// MARK: - Enhanced Device Row
struct EnhancedDeviceRow: View {
    let device: NORScannedPeripheral
    let deviceNameManager: DeviceNameManager
    let categoryManager: DeviceCategoryManager
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onAssignCategory: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private func signalStrengthImage(rssi: Int32) -> String {
        if rssi < -90 {
            return "Signal_0"
        } else if rssi < -70 {
            return "Signal_1"
        } else if rssi < -50 {
            return "Signal_2"
        } else {
            return "Signal_3"
        }
    }
    
    private func signalStrengthSystemImage(rssi: Int32) -> String {
        if rssi < -90 {
            return "wifi.slash"
        } else if rssi < -70 {
            return "wifi"
        } else if rssi < -50 {
            return "wifi"
        } else {
            return "wifi"
        }
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Signal strength icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if device.isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        if let image = UIImage(named: signalStrengthImage(rssi: device.RSSI)) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: signalStrengthSystemImage(rssi: device.RSSI))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        }
                    }
                }
                
                // Device info
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(deviceNameManager.getDisplayName(for: device))
                                .font(.custom("AeonikPro-Bold", size: 18))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if let category = categoryManager.getCategoryForDevice(device) {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(category.color.swiftUIColor)
                                    
                                    Text(category.name)
                                        .font(.custom("AeonikPro-Medium", size: 10))
                                        .foregroundColor(category.color.swiftUIColor)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(category.color.swiftUIColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        
                        if deviceNameManager.hasCustomName(for: device) {
                            Text(device.realName)
                                .font(.custom("AeonikPro-Regular", size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text("RSSI: \(device.RSSI) dBm")
                            .font(.custom("AeonikPro-Regular", size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if device.isConnected {
                            Text("Connected")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            Text("Available")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                
                // Actions
                VStack(spacing: 8) {
                    Button(action: onAssignCategory) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            onLongPress()
        }
    }
}

// MARK: - Device Assignment View
struct DeviceAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    let device: NORScannedPeripheral
    let onAssign: (DeviceCategory?) -> Void
    
    @StateObject private var categoryManager = DeviceCategoryManager.shared
    @StateObject private var deviceNameManager = DeviceNameManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    // Device info header
                    VStack(spacing: 16) {
                        Text("Assign Category")
                            .font(.custom("AeonikPro-Bold", size: 24))
                            .foregroundColor(.primary)
                        
                        Text("Choose a category for \(deviceNameManager.getDisplayName(for: device))")
                            .font(.custom("AeonikPro-Regular", size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Categories list
                    List {
                        // Remove from category option
                        Button(action: {
                            onAssign(nil)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Remove from Category")
                                        .font(.custom("AeonikPro-Bold", size: 18))
                                        .foregroundColor(.primary)
                                    
                                    Text("Move to uncategorized")
                                        .font(.custom("AeonikPro-Regular", size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Available categories
                        ForEach(categoryManager.categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { category in
                            Button(action: {
                                onAssign(category)
                                dismiss()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.swiftUIColor.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: category.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(category.color.swiftUIColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.name)
                                            .font(.custom("AeonikPro-Bold", size: 18))
                                            .foregroundColor(.primary)
                                        
                                        Text("\(category.deviceMacAddresses.count) device\(category.deviceMacAddresses.count == 1 ? "" : "s")")
                                            .font(.custom("AeonikPro-Regular", size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if categoryManager.getCategoryForDevice(device)?.id == category.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(category.color.swiftUIColor)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(.secondary)
            )
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Preview
#Preview {
    DeviceListView(
        onBack: {},
        onDeviceSelected: { _, _ in }
    )
} 