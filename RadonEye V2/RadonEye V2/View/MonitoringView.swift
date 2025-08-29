import SwiftUI
import CoreBluetooth
import Charts
import DGCharts

// MARK: - Data Models
struct SelectedDataPoint: Equatable {
    let index: Int
    let value: Float
    let time: String
}

// MARK: - Connection Manager
class BLEConnectionManager: ObservableObject, MonitorTabDelegate {
    @Published var isConnecting = false
    @Published var isConnected = false
    @Published var connectionError: String?
    
    // Radon measurement data (always available, matches old implementation)
    @Published var currentRadonValue: Float = 0.0
    @Published var peakRadonValue: Float = 0.0
    @Published var dailyAverage: Float = 0.0
    @Published var monthlyAverage: Float = 0.0
    @Published var measurementTime: UInt32 = 0
    @Published var vibrationStatus: UInt8 = 0
    @Published var radonUnit: UInt8 = 0
    @Published var unitString: String = "pCi/ℓ"
    @Published var connectionStatus: String = "Disconnected"
    
    // Radon level thresholds (same as old implementation)
    @Published var radonLevel: [Float] = [4, 2.7]
    
    // Chart data properties (same as old implementation)
    @Published var chartDataAvailable = false
    @Published var chartData: [Float] = []
    @Published var lastSyncTime: Date?
    @Published var chartMaxValue: Float = 0
    @Published var chartMinValue: Float = 0
    @Published var chartAverage: Float = 0
    @Published var chartDataCount: Int = 0
    @Published var isLoadingChart = false
    @Published var isInitializingDownload = false
    @Published var chartError: String?
    @Published var downloadPercent: Float = 0.0
    @Published var showRefreshLabel = true
    @Published var flagChartView = false
    
    private var bleController: BLEControl
    private let peripheral: NORScannedPeripheral
    private var dataTimer: Timer?
    private var downloadTimer: Timer? // Same as old implementation
    
    deinit {
        stopDataTimer()
        stopDownloadTimer()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.logDownStart), object: nil)
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Deinitializing and cleaning up")
    }
    
    init(peripheral: NORScannedPeripheral, bleController: BLEControl) {
        self.peripheral = peripheral
        self.bleController = bleController
        
        // Initialize chart states to default values (same as old implementation)
        self.showRefreshLabel = true  // Start with empty state
        self.flagChartView = false
        self.chartDataAvailable = false
        self.downloadPercent = 0.0
        self.isLoadingChart = false
        
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Initializing with device: \(peripheral.realName)")
        // Set this manager as the delegate for BLE events
        bleController.delegateMonitorTabInit(delegate: self)
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Delegate set successfully")
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Chart states initialized: showRefreshLabel=\(self.showRefreshLabel), flagChartView=\(self.flagChartView)")
        
        // Listen for logDownStart notification (same as old implementation)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(MyStruct.notiName.logDownStart),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLogDownStartNotification()
        }
    }
    
    func connect() {
        isConnecting = true
        connectionError = nil
        
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Attempting to connect to \(peripheral.realName)")
        
        // Set up V3 mode based on device type (same as old implementation)
        MyStruct.v3Mode = peripheral.V3
        
        // CRITICAL: Set BLEData.Init.enable = true like the old implementation  
        BLEData.Init.enable = true
        BLEData.Flag.dataClear = false  // Ensure this doesn't interfere
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Set BLEData.Init.enable = true, dataClear = false")
        
        // Use real BLE connection (same as old implementation)
        bleController.setPeripheral()
        
        // Set up connection timeout handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isConnecting {
                self.isConnecting = false
                self.connectionError = "Connection timeout. Please make sure the device is nearby and try again."
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Connection timeout for \(self.peripheral.realName)")
            }
        }
    }
    
    // MARK: - MonitorTabDelegate
    func dInitFinish() {
        DispatchQueue.main.async {
            self.isConnecting = false
            self.isConnected = true
            self.connectionError = nil
            self.connectionStatus = "Connected"
            MyUtil.printProcess(inMsg: "BLEConnectionManager - dInitFinish() called - Connected successfully to \(self.peripheral.realName)")
            
            // CRITICAL: Request data immediately and start timer (same as old implementation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Requesting immediate measurement data")
                if MyStruct.v2Mode {
                    self.bleController.bleSendData(cmd: BLECommnad.cmd_BLEV2_QUERY_ALL)
                } else {
                    self.bleController.bleSendData(cmd: BLECommnad.cmd_MEAS_QUERY)
                }
            }
            
            // Start the data request timer
            self.startDataTimer()
        }
    }
    
    func didDisconnectPeripheral() {
        DispatchQueue.main.async {
            // Stop the data timer
            self.stopDataTimer()
            
            if self.isConnecting {
                self.isConnecting = false
                self.isConnected = false
                self.connectionError = "Failed to connect to device. Please make sure the device is nearby and try again."
                self.connectionStatus = "Connection Failed"
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Failed to connect to \(self.peripheral.realName)")
            } else {
                self.isConnecting = false
                self.isConnected = false
                self.connectionError = "Device disconnected"
                self.connectionStatus = "Disconnected"
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Device disconnected: \(self.peripheral.realName)")
            }
        }
    }
    
    func dTabRadonUiUpdate(_ cmd: UInt8) {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - dTabRadonUiUpdate() CALLED with cmd: \(cmd)")
        // Update radon data from BLEData (same logic as old implementation)
        DispatchQueue.main.async {
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Updating radon data, cmd: \(cmd)")
            MyUtil.printProcess(inMsg: "BLEConnectionManager - BLEData.Status.measTime: \(BLEData.Status.measTime)")
            MyUtil.printProcess(inMsg: "BLEConnectionManager - BLEData.Meas.radonValue: \(BLEData.Meas.radonValue)")
            MyUtil.printProcess(inMsg: "BLEConnectionManager - BLEData.Config.unit: \(BLEData.Config.unit)")
            
            // Always update these values (same as old implementation)
            self.measurementTime = BLEData.Status.measTime
            self.vibrationStatus = BLEData.Status.vibStatus
            self.radonUnit = BLEData.Config.unit
            self.unitString = BLEData.Config.unitStr
            self.connectionStatus = "Connected"
            
            // Set radon level thresholds based on unit (same as old implementation)
            if BLEData.Config.unit == 1 {
                self.radonLevel[0] = 148
                self.radonLevel[1] = 100
            } else {
                self.radonLevel[0] = 4
                self.radonLevel[1] = 2.7
            }
            
            // ALWAYS process radon values (same as old implementation)
            // Convert values using the same utility functions as old implementation
            var radonValue = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonValue, BLEData.Config.unit)
            var radonDValue = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonDValue, BLEData.Config.unit)
            var radonMValue = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonMValue, BLEData.Config.unit)
            var radonPeakValue = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonPeakValue, BLEData.Config.unit)
            
            // V1.5.0 - Apply minimum value constraint for V3 devices
            if BLEData.Flag.V3_New && BLEData.Config.unit == 0 {
                radonValue = MyUtil.newFwMinValue(inValue: radonValue)
                radonDValue = MyUtil.newFwMinValue(inValue: radonDValue)
                radonMValue = MyUtil.newFwMinValue(inValue: radonMValue)
                radonPeakValue = MyUtil.newFwMinValue(inValue: radonPeakValue)
            }
            
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Converted radonValue: \(radonValue)")
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Converted radonDValue: \(radonDValue)")
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Converted radonPeakValue: \(radonPeakValue)")
            
            // IDENTICAL logic to old implementation:
            if BLEData.Status.measTime < 10 {
                // Show 0 when insufficient measurement time (same as old implementation)
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Insufficient measurement time, showing 0 values")
                self.currentRadonValue = 0
                self.peakRadonValue = 0
                self.dailyAverage = 0
                self.monthlyAverage = 0
            } else {
                // Show actual values when sufficient measurement time
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Sufficient measurement time, showing actual values")
                self.currentRadonValue = radonValue
                
                // Peak value (after 60 minutes)
                if BLEData.Status.measTime >= 60 {
                    self.peakRadonValue = radonPeakValue
                } else {
                    self.peakRadonValue = 0
                }
                
                // Daily average (after 1 day = 1440 minutes)
                if BLEData.Status.measTime >= 1440 {
                    self.dailyAverage = radonDValue
                } else {
                    self.dailyAverage = 0
                }
                
                // Monthly average (after 30 days = 43200 minutes)
                if BLEData.Status.measTime >= 43200 {
                    self.monthlyAverage = radonMValue
                } else {
                    self.monthlyAverage = 0
                }
            }
            
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Final UI values - current: \(self.currentRadonValue), peak: \(self.peakRadonValue), daily: \(self.dailyAverage), time: \(self.measurementTime)")
        }
    }
    
    func recLogDataStart() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - recLogDataStart() called - Log data reception started")
        DispatchQueue.main.async {
            // Start percentage timer (same as old implementation)
            self.startDownloadTimer()
        }
    }
    
    // MARK: - Download Timer Management (same as old implementation)
    private func startDownloadTimer() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Starting download timer")
        stopDownloadTimer()
        
        BLEData.Log.recPercent = 0
        downloadPercent = 0.0
        isInitializingDownload = false  // End initialization state
        isLoadingChart = true          // Start loading state
        chartError = nil
        
        // Timer to update percentage every 0.5 seconds (same as old implementation)
        downloadTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.downloadPercent = BLEData.Log.recPercent
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Download progress: \(self.downloadPercent)%")
            }
        }
    }
    
    private func stopDownloadTimer() {
        downloadTimer?.invalidate()
        downloadTimer = nil
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Download timer stopped")
    }
    
    func rawLogDataReturn(_ inData: [UInt8]) {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - rawLogDataReturn() called - Raw log data received: \(inData.count) bytes")
        
        // Process raw data EXACTLY like old implementation in viewTabTop.rawLogDataReturn
        BLEData.Log.radonValue.removeAll()
        var add = Int(0)
        
        for _ in 0..<BLEData.Log.dataNo {
            var array = [UInt8]()
            for _ in 0..<2 {
                array.append(inData[add])
                add += 1
            }
            
            // Same logic as old implementation
            var logValue = Float(MyUtil.byteConvertUInt16(inArrayData: array))
            if !MyStruct.v2Mode {
                logValue = logValue / 100.0
                
                if logValue >= 99.9 {
                    logValue = 99.9
                }
            }
            
            BLEData.Log.radonValue.append(logValue)
        }
        
        BLEData.Flag.chartDraw = true
        
        // Stop download timer with delay (same as old implementation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stopDownloadTimer()
            self.isLoadingChart = false
            self.isInitializingDownload = false
            
            // Process chart data (same as old implementation)
            if BLEData.Log.dataNo > 0 && !BLEData.Log.radonValue.isEmpty {
                self.chartData = BLEData.Log.radonValue
                self.chartDataCount = BLEData.Log.radonValue.count
                self.lastSyncTime = Date()
                
                // Calculate statistics on RAW VALUES (before unit conversion - same as old implementation)
                if !self.chartData.isEmpty {
                    self.chartMaxValue = self.chartData.max() ?? 0
                    self.chartMinValue = self.chartData.min() ?? 0
                    let sum = self.chartData.reduce(0, +)
                    self.chartAverage = sum / Float(self.chartData.count)
                    
                    // Apply unit conversion for DISPLAY statistics only (same as old implementation)
                    let displayMaxValue = MyUtil.radonValueReturn(MyStruct.v2Mode, self.chartMaxValue, BLEData.Config.unit)
                    let displayMinValue = MyUtil.radonValueReturn(MyStruct.v2Mode, self.chartMinValue, BLEData.Config.unit)
                    let displayAverage = MyUtil.radonValueReturn(MyStruct.v2Mode, self.chartAverage, BLEData.Config.unit)
                    
                    // Apply V3 minimum constraints for display (same as old implementation)
                    if BLEData.Flag.V3_New && BLEData.Config.unit == 0 {
                        self.chartMaxValue = MyUtil.newFwMinValue(inValue: displayMaxValue)
                        self.chartMinValue = MyUtil.newFwMinValue(inValue: displayMinValue)
                        self.chartAverage = MyUtil.newFwMinValue(inValue: displayAverage)
                    } else {
                        self.chartMaxValue = displayMaxValue
                        self.chartMinValue = displayMinValue
                        self.chartAverage = displayAverage
                    }
                    
                    // Update UI states (same as old implementation)
                    self.chartDataAvailable = true
                    self.flagChartView = true
                    self.showRefreshLabel = false
                    
                    MyUtil.printProcess(inMsg: "BLEConnectionManager - Chart update successful: \(self.chartData.count) points, max: \(self.chartMaxValue), min: \(self.chartMinValue)")
                    
                    // Post notification for chart update (same as old implementation)
                    NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorChartUpdate), object: nil)
                } else {
                    self.isInitializingDownload = false
                    self.chartError = "No chart data available"
                    self.showRefreshLabel = true
                }
            } else {
                self.isInitializingDownload = false
                self.chartError = "No chart data received from device"
                self.showRefreshLabel = true
            }
        }
    }
    
    func DfuFinishProcess() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - DfuFinishProcess() called - DFU finished")
    }
    
    // MARK: - Timer Management (same as old implementation)
    func startDataTimer() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Starting data request timer")
        
        // Stop any existing timer
        stopDataTimer()
        
        // Start timer to request data every 30 seconds (reduced frequency to prevent excessive refreshing)
        dataTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Timer requesting measurement data")
            
            // Request measurement data (same command as old implementation)
            if MyStruct.v2Mode {
                self.bleController.bleSendData(cmd: BLECommnad.cmd_BLEV2_QUERY_ALL)
            } else {
                self.bleController.bleSendData(cmd: BLECommnad.cmd_MEAS_QUERY)
            }
        }
    }
    
    // MARK: - Chart Data Management (same as old implementation)
    func requestChartData() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - requestChartData() called")
        if isConnected {
            // Show initialization state immediately
            DispatchQueue.main.async {
                self.isInitializingDownload = true
                self.isLoadingChart = false
                self.chartError = nil
                self.showRefreshLabel = false
            }
            
            // Post notification for log download start (same as old implementation)
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Posting logDownStart notification")
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.logDownStart), object: nil)
        } else {
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Device not connected, cannot request chart data")
            DispatchQueue.main.async {
                self.chartError = "Device not connected"
                self.showRefreshLabel = true
            }
        }
    }
    
    func stopDataTimer() {
        dataTimer?.invalidate()
        dataTimer = nil
        MyUtil.printProcess(inMsg: "BLEConnectionManager - Data request timer stopped")
    }
    
    func clearError() {
        print("🔧 BLEConnectionManager: Clearing error")
        connectionError = nil
    }
    
    // MARK: - Chart Initialization (same as old implementation)
    private func chartInitProcess() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - chartInitProcess() called")
        DispatchQueue.main.async {
            self.isInitializingDownload = false
            self.isLoadingChart = false
            self.showRefreshLabel = true
            self.flagChartView = false
            self.chartDataAvailable = false
            self.chartError = nil
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Chart initialized to default state")
        }
    }
    
    // MARK: - Notification Handlers (same as old implementation)
    private func handleLogDownStartNotification() {
        MyUtil.printProcess(inMsg: "BLEConnectionManager - handleLogDownStartNotification() called")
        
        if isConnected {
            // Same logic as old implementation in viewTabTop.notificationLogDownStart
            BLEData.Log.recPercent = 0
            BLEData.Log.rawData.removeAll()
            
            if MyStruct.v2Mode {
                // New model - check if data is available
                if BLEData.Log.dataNo == 0 {
                    DispatchQueue.main.async {
                        self.isInitializingDownload = false
                        self.isLoadingChart = false
                        self.chartError = "No data available on device"
                        self.showRefreshLabel = true
                        MyUtil.printProcess(inMsg: "BLEConnectionManager - No data available on V2 device")
                    }
                } else {
                    MyUtil.printProcess(inMsg: "BLEConnectionManager - Starting V2 log download, dataNo: \(BLEData.Log.dataNo)")
                    bleController.bleSendData(cmd: BLECommnad.cmd_BLEV2_LOG_SEND)
                }
            } else {
                // Old model
                MyUtil.printProcess(inMsg: "BLEConnectionManager - Starting V1 log download")
                bleController.bleSendData(cmd: BLECommnad.cmd_EEPROM_LOG_INFO_QUERY)
            }
        } else {
            MyUtil.printProcess(inMsg: "BLEConnectionManager - Device not connected, cannot start download")
            DispatchQueue.main.async {
                self.chartError = "Device not connected"
                self.showRefreshLabel = true
            }
        }
    }
}

// MARK: - Main Monitoring View
struct MonitoringView: View {
    let peripheral: NORScannedPeripheral
    let bleController: BLEControl
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var connectionManager: BLEConnectionManager
    @StateObject private var deviceNameManager = DeviceNameManager.shared
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var showingRenameAlert = false
    @State private var newDeviceName = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init(peripheral: NORScannedPeripheral, bleController: BLEControl) {
        self.peripheral = peripheral
        self.bleController = bleController
        self._connectionManager = StateObject(wrappedValue: BLEConnectionManager(peripheral: peripheral, bleController: bleController))
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
                // Header
                VStack(spacing: 16) {
                    // Device name (with rename functionality) - moved to top, no logo above
                    GeometryReader { geometry in
                        VStack(spacing: 4) {
                            Button(action: {
                                // Tap to rename device
                                newDeviceName = deviceNameManager.getCustomName(for: peripheral) ?? ""
                                showingRenameAlert = true
                            }) {
                                VStack(spacing: 2) {
                                    HStack(spacing: 2) { // Minimal spacing between name and edit button
                                        Text(deviceNameManager.getDisplayName(for: peripheral))
                                            .font(.custom("AeonikPro-Bold", size: 24))
                                            .foregroundColor(.primary)
                                        
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: geometry.size.width)
                                    .offset(x: geometry.size.width * 0.02) // Slight right shift (2% of width)
                                    
                                    // Show original name if custom name exists
                                    if deviceNameManager.hasCustomName(for: peripheral) {
                                        Text(peripheral.realName)
                                            .font(.custom("AeonikPro-Regular", size: 14))
                                            .foregroundColor(.secondary)
                                            .frame(width: geometry.size.width)
                                            .offset(x: geometry.size.width * 0.02) // Match name offset
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(height: 60) // Fixed height for GeometryReader
                    
                    Text(connectionManager.connectionStatus)
                        .font(.custom("AeonikPro-Medium", size: 14))
                        .foregroundColor(connectionManager.isConnected ? .green : .red)
                }
                .padding(.top, 10) // Reduced top padding since no logo
                .padding(.bottom, 12) // Reduced bottom padding
                
                // Connection Alert
                if let error = connectionManager.connectionError {
                    ErrorBanner(message: error)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12) // Reduced padding
                }
                
                // Tab Picker (matches old implementation structure)
                Picker("Section", selection: $selectedTab) {
                    Text("Radon").tag(0)
                    Text("Data").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12) // Reduced padding
                
                // Content based on selected tab
                if selectedTab == 0 {
                    RadonSectionView(connectionManager: connectionManager)
                } else {
                    DataSectionView(connectionManager: connectionManager, peripheral: peripheral)
                }
                
                Spacer()
                
                // Connection Action (only when disconnected)
                if !connectionManager.isConnected && !connectionManager.isConnecting {
                    Button(action: {
                        connectionManager.connect()
                    }) {
                        HStack(spacing: 12) {
                            Text("Connect to Device")
                                .font(.custom("AeonikPro-Bold", size: 18))
                            Image(systemName: "wifi")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.156, green: 0.459, blue: 0.737),
                                    Color(red: 0.098, green: 0.329, blue: 0.557)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    })
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            
            // Loading overlay (similar to old implementation)
            if connectionManager.isConnecting {
                LoadingOverlay(
                    deviceName: deviceNameManager.getDisplayName(for: peripheral),
                    message: "Connecting to device...",
                    isError: false
                )
            }
            
            // Error overlay for connection failures
            if let error = connectionManager.connectionError, !connectionManager.isConnected && !connectionManager.isConnecting {
                LoadingOverlay(
                    deviceName: deviceNameManager.getDisplayName(for: peripheral),
                    message: error,
                    isError: true
                )
                .onTapGesture {
                    // Tap to dismiss error
                    connectionManager.clearError()
                }
                .onAppear {
                    // Auto-dismiss after 4 seconds like old implementation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        connectionManager.clearError()
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    dismiss()
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
            // Auto-connect when the view appears
            connectionManager.connect()
        }
        .onDisappear {
            // Stop data timer when view disappears
            connectionManager.stopDataTimer()
            if connectionManager.isConnected {
                connectionManager.didDisconnectPeripheral()
            }
        }
        .alert("Connection Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(connectionManager.connectionError ?? "Unknown error occurred")
        }
        .alert("Rename Device", isPresented: $showingRenameAlert) {
            TextField("Device Name", text: $newDeviceName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !newDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    deviceNameManager.setCustomName(newDeviceName.trimmingCharacters(in: .whitespacesAndNewlines), for: peripheral)
                }
            }
        } message: {
            Text("Enter a custom name for this device")
        }
    }
}

// MARK: - Radon Section View (matches viewMonitorRadon.swift)
struct RadonSectionView: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    
    // Radon status calculation (same thresholds as old implementation)
    private var radonStatus: (title: String, color: Color, backgroundColor: Color) {
        let value = connectionManager.currentRadonValue
        let thresholds = connectionManager.radonLevel
        
        if value >= thresholds[0] {
            return ("High Risk", Color.red, Color.red.opacity(0.1))
        } else if value >= thresholds[1] {
            return ("Moderate Risk", Color.orange, Color.orange.opacity(0.1))
        } else if value > 0 {
            return ("Low Risk", Color.green, Color.green.opacity(0.1))
        } else {
            return ("Good", Color.blue, Color.blue.opacity(0.1))
        }
    }
    
    // Format measurement time (same as old implementation)
    private var measurementTimeString: String {
        let timeArray = MyUtil.measTimeConvertStringArray(connectionManager.measurementTime)
        var result = ""
        
        if !timeArray[0].isEmpty {
            result += "\(timeArray[0])d "
        }
        result += "\(timeArray[1])h \(timeArray[2])m"
        
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main Radon Display (ALWAYS VISIBLE - same as old implementation)
                CurrentRadonCard(
                    value: connectionManager.currentRadonValue,
                    unit: connectionManager.unitString,
                    status: radonStatus,
                    vibrationOn: connectionManager.vibrationStatus != 0,
                    measurementTime: connectionManager.measurementTime
                )
                
                // Measurement Time Card (ALWAYS VISIBLE)
                MeasurementTimeCard(
                    timeString: measurementTimeString,
                    totalMinutes: connectionManager.measurementTime
                )
                
                // Metrics Section (conditional display - same logic as old implementation)
                VStack(spacing: 16) {
                    // Peak Value (after 60 minutes - same as old implementation)
                    MetricCard(
                        title: "Peak Value",
                        value: connectionManager.peakRadonValue,
                        unit: connectionManager.unitString,
                        icon: "arrow.up.circle.fill",
                        color: Color.red,
                        showValue: connectionManager.measurementTime >= 60
                    )
                    
                    // Daily Average (after 1 day - same as old implementation)
                    MetricCard(
                        title: "24-Hour Average",
                        value: connectionManager.dailyAverage,
                        unit: connectionManager.unitString,
                        icon: "calendar.circle.fill",
                        color: Color.blue,
                        showValue: connectionManager.measurementTime >= 1440
                    )
                    
                    // Monthly Average (after 30 days - same as old implementation)
                    if connectionManager.measurementTime >= 43200 {
                        MetricCard(
                            title: "30-Day Average",
                            value: connectionManager.monthlyAverage,
                            unit: connectionManager.unitString,
                            icon: "calendar.badge.clock",
                            color: Color.purple,
                            showValue: true
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 5) // Add 5px top spacing
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Data Section View (matches viewMonitorData.swift)
struct DataSectionView: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    let peripheral: NORScannedPeripheral
    @StateObject private var deviceNameManager = DeviceNameManager.shared
    @State private var showingChartInfo = false
    @State private var downloadButtonClicked = false // Track if download was clicked
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var selectedDataPoint: SelectedDataPoint? = nil
    @State private var showingExportAlert = false
    @State private var showingExportSuccess = false
    @State private var showingTimestampInfo = false
    @State private var showingSaveAlert = false
    @State private var showingSaveSuccess = false
    @State private var saveDataName = ""
    @State private var csvFileName = ""
    @State private var showingCSVNamingAlert = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Chart area with centered download button (LARGER HEIGHT)
                    ZStack {
                        // Chart (always present as background) - EVEN LARGER
                        ChartContainerView(
                            connectionManager: connectionManager,
                            selectedDataPoint: selectedDataPoint,
                            onPointSelected: { index in
                                // Convert chart index to date and update selectedDate
                                updateSelectedDateFromChartIndex(index)
                            }
                        )
                        .frame(height: connectionManager.chartDataAvailable ? 520 : geometry.size.height * 0.68) // Reduced by 30px total
                        
                        // Show loading overlay if loading or initializing
                        if connectionManager.isInitializingDownload || connectionManager.isLoadingChart {
                            VStack(spacing: 20) {
                                CircularProgressView(progress: Double(connectionManager.downloadPercent) / 100.0)
                                    .frame(width: 120, height: 120)
                                VStack(spacing: 8) {
                                    Text(connectionManager.isInitializingDownload ? "Download Initialized" : "Downloading chart data...")
                                        .font(.custom("AeonikPro-Bold", size: 16))
                                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                                    if connectionManager.isInitializingDownload {
                                        Text("Preparing data transfer...")
                                            .font(.custom("AeonikPro-Regular", size: 14))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white.opacity(0.9))
                        } else if connectionManager.isConnected && !connectionManager.chartDataAvailable {
                            // Combined empty state and download button overlay (only when not loading)
                            VStack(spacing: 32) {
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                                    
                                    Text("Use the download button below to get data")
                                        .font(.custom("AeonikPro-Regular", size: 16))
                                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                Button(action: {
                                    downloadButtonClicked = true // Hide button immediately
                                    connectionManager.requestChartData()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Download Chart Data")
                                            .font(.custom("AeonikPro-Medium", size: 16))
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 280, height: 44)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.156, green: 0.459, blue: 0.737),
                                                Color(red: 0.098, green: 0.329, blue: 0.557)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.clear)
                        }
                    }
                    
                    // Date/Time Selector Section (MOVED BELOW CHART)
                    if connectionManager.chartDataAvailable && !connectionManager.chartData.isEmpty {
                        DateTimeSelectionView(
                            connectionManager: connectionManager,
                            selectedDate: $selectedDate,
                            showingDatePicker: $showingDatePicker,
                            selectedDataPoint: $selectedDataPoint
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 20) // Add top padding since it's now below chart
                        .padding(.bottom, 16)
                    }
                    
                    // Export button at the very bottom (when data is available)
                    if connectionManager.chartDataAvailable {
                        VStack(spacing: 16) {
                            // Separator line
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    showingSaveAlert = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Save Data")
                                            .font(.custom("AeonikPro-Medium", size: 16))
                                    }
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 0.156, green: 0.459, blue: 0.737), lineWidth: 1)
                                    )
                                }
                                
                                Button(action: {
                                    showingCSVNamingAlert = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Export CSV")
                                            .font(.custom("AeonikPro-Medium", size: 16))
                                    }
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 0.156, green: 0.459, blue: 0.737), lineWidth: 1)
                                    )
                                }
                                
                                Button(action: {
                                    showingTimestampInfo = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 0.576, green: 0.576, blue: 0.576))
                                }
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.576, green: 0.576, blue: 0.576).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Bottom padding for scroll
                    Spacer()
                        .frame(height: 50)
                }
            }
        }
        .onAppear {
            // Reset download button state when view appears
            downloadButtonClicked = false
            // Initialize selected date to current time
            selectedDate = Date()
        }
        .onChange(of: connectionManager.chartDataAvailable) { available in
            if available {
                downloadButtonClicked = false // Reset for next time
                // Set initial date to the end of measurement period
                selectedDate = calculateDateFromMeasurementTime()
            }
        }
        .sheet(isPresented: $showingChartInfo) {
            ChartInfoView(connectionManager: connectionManager)
        }
        .alert("Save Data", isPresented: $showingSaveAlert) {
            TextField("Data Name", text: $saveDataName)
            Button("Save") {
                saveLogData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save this chart data for easy access later")
        }
        .alert("Data Saved", isPresented: $showingSaveSuccess) {
            Button("OK") { }
        } message: {
            Text("Chart data has been saved successfully")
        }
        .alert("Export CSV", isPresented: $showingCSVNamingAlert) {
            TextField("File Name", text: $csvFileName)
            Button("Export") {
                exportData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the CSV file")
        }
        .alert("Export Complete", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            Text("Chart data has been exported successfully")
        }
        .alert("Timestamp Information", isPresented: $showingTimestampInfo) {
            Button("OK") { }
        } message: {
            Text("Timestamps in exported data are estimated based on measurement duration and even spacing. They provide good accuracy for recent data (±5-15 minutes) but may be less precise for older measurements due to potential clock drift.")
        }
    }
    
    private func calculateDateFromMeasurementTime() -> Date {
        // Calculate the current end time based on measurement duration
        let measurementMinutes = TimeInterval(connectionManager.measurementTime * 60) // Convert minutes to seconds
        return Date() // Default to current time, will be refined in DateTimeSelectionView
    }
    
    private func updateSelectedDateFromChartIndex(_ index: Int) {
        guard !connectionManager.chartData.isEmpty,
              index >= 0,
              index < connectionManager.chartData.count,
              connectionManager.measurementTime > 0 else { 
            MyUtil.printProcess(inMsg: "DataSectionView - Invalid chart index for date conversion: \(index)")
            return 
        }
        
        // Calculate measurement start time
        let measurementStartTime = Date().addingTimeInterval(-TimeInterval(connectionManager.measurementTime * 60))
        let totalMinutes = connectionManager.measurementTime
        let dataPointCount = connectionManager.chartData.count
        
        // Calculate minutes per data point (assuming evenly spaced measurements)
        let minutesPerDataPoint = Double(totalMinutes) / Double(dataPointCount)
        
        // Calculate the time for this data point
        let timeOffsetMinutes = Double(index) * minutesPerDataPoint
        let pointTime = measurementStartTime.addingTimeInterval(timeOffsetMinutes * 60)
        
        // Get the value and apply same conversions as the chart for selectedDataPoint
        let rawValue = connectionManager.chartData[index]
        let convertedValue = MyUtil.radonValueReturn(MyStruct.v2Mode, rawValue, BLEData.Config.unit)
        let finalValue = BLEData.Flag.V3_New && BLEData.Config.unit == 0 ? 
            MyUtil.newFwMinValue(inValue: convertedValue) : convertedValue
        
        // Format the time string
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, h:mm a"
        let timeString = timeFormatter.string(from: pointTime)
        
        // Update both selected date and data point atomically to ensure sync
        DispatchQueue.main.async {
            // Update selected date to match the chart selection
            self.selectedDate = pointTime
            
            // Update selected data point with calculated values
            self.selectedDataPoint = SelectedDataPoint(index: index, value: finalValue, time: timeString)
            
            MyUtil.printProcess(inMsg: "DataSectionView - Chart point selected: index \(index), time \(timeString), value \(finalValue)")
        }
    }
    
    private func saveLogData() {
        guard !saveDataName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let success = SavedDataManager.shared.saveLogData(
            name: saveDataName.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceName: deviceNameManager.getDisplayName(for: peripheral),
            connectionManager: connectionManager
        )
        
        if success {
            saveDataName = "" // Reset for next use
            showingSaveSuccess = true
        }
    }
    
    private func exportData() {
        // Export implementation with custom file name
        let csvData = generateCSVData()
        saveCSVFile(csvData)
        csvFileName = "" // Reset for next use
        showingExportSuccess = true
    }
    
    private func generateCSVData() -> String {
        var csv = "Index,Date,Time,Timestamp,Radon Value,Unit\n"
        
        // Calculate measurement start time (same logic as DateTimeSelectionView)
        let measurementStartTime = Date().addingTimeInterval(-TimeInterval(connectionManager.measurementTime * 60))
        let totalMinutes = connectionManager.measurementTime
        let dataPointCount = connectionManager.chartData.count
        
        // Calculate minutes per data point (assuming evenly spaced measurements)
        let minutesPerDataPoint = dataPointCount > 0 ? Double(totalMinutes) / Double(dataPointCount) : 0
        
        for (index, value) in connectionManager.chartData.enumerated() {
            // Apply same conversion as old implementation
            let convertedValue = MyUtil.radonValueReturn(MyStruct.v2Mode, value, BLEData.Config.unit)
            let finalValue = BLEData.Flag.V3_New && BLEData.Config.unit == 0 ? 
                MyUtil.newFwMinValue(inValue: convertedValue) : convertedValue
            
            // Calculate timestamp for this data point (same logic as DateTimeSelectionView)
            let dataPointTime = measurementStartTime.addingTimeInterval(Double(index) * minutesPerDataPoint * 60)
            
            // Format date and time components
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: dataPointTime)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let timeString = timeFormatter.string(from: dataPointTime)
            
            let timestampFormatter = DateFormatter()
            timestampFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampString = timestampFormatter.string(from: dataPointTime)
            
            csv += "\(index),\(dateString),\(timeString),\(timestampString),\(finalValue),\(connectionManager.unitString)\n"
        }
        
        return csv
    }
    
    private func saveCSVFile(_ csvString: String) {
        // File save implementation with custom file name
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let customFileName = csvFileName.trimmingCharacters(in: .whitespacesAndNewlines)
            let fileName = customFileName.isEmpty ? 
                "RadonEye_Data_\(DateFormatter.dateFormatted(Date())).csv" :
                "\(customFileName).csv"
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                MyUtil.printProcess(inMsg: "DataSectionView - CSV exported to: \(fileURL.path)")
            } catch {
                MyUtil.printProcess(inMsg: "DataSectionView - Export error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Date/Time Selection View
struct DateTimeSelectionView: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    @Binding var selectedDataPoint: SelectedDataPoint?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Calculate measurement start and end times
    private var measurementStartTime: Date {
        let measurementSeconds = TimeInterval(connectionManager.measurementTime * 60)
        return Date().addingTimeInterval(-measurementSeconds)
    }
    
    private var measurementEndTime: Date {
        return Date()
    }
    
    // Calculate which data point corresponds to the selected date
    private var correspondingDataPoint: SelectedDataPoint? {
        guard !connectionManager.chartData.isEmpty,
              connectionManager.measurementTime > 0 else { return nil }
        
        let totalMinutes = connectionManager.measurementTime
        let dataPointCount = connectionManager.chartData.count
        
        // Calculate minutes per data point (assuming hourly measurements)
        let minutesPerDataPoint = Double(totalMinutes) / Double(dataPointCount)
        
        // Calculate time offset from start
        let timeOffsetSeconds = selectedDate.timeIntervalSince(measurementStartTime)
        let timeOffsetMinutes = timeOffsetSeconds / 60.0
        
        // Clamp to valid range
        let clampedOffsetMinutes = max(0, min(timeOffsetMinutes, Double(totalMinutes)))
        
        // Calculate data point index
        let index = Int(clampedOffsetMinutes / minutesPerDataPoint)
        let clampedIndex = max(0, min(index, dataPointCount - 1))
        
        // Get the value and apply same conversions as the chart
        let rawValue = connectionManager.chartData[clampedIndex]
        let convertedValue = MyUtil.radonValueReturn(MyStruct.v2Mode, rawValue, BLEData.Config.unit)
        let finalValue = BLEData.Flag.V3_New && BLEData.Config.unit == 0 ? 
            MyUtil.newFwMinValue(inValue: convertedValue) : convertedValue
        
        // Format the exact time for this data point
        let exactDataPointTime = measurementStartTime.addingTimeInterval(Double(clampedIndex) * minutesPerDataPoint * 60)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, h:mm a"
        let timeString = timeFormatter.string(from: exactDataPointTime)
        
        return SelectedDataPoint(index: clampedIndex, value: finalValue, time: timeString)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Compact header
            HStack {
                Text("Time Lookup")
                    .font(.custom("AeonikPro-Bold", size: 18))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                
                Spacer()
                
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .medium))
                        Text("Select")
                            .font(.custom("AeonikPro-Medium", size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                    )
                }
            }
            
            // Compact result display
            if let dataPoint = correspondingDataPoint {
                HStack(spacing: 16) {
                    // Time info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatSelectedDate())
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        Text("Point #\(dataPoint.index + 1)")
                            .font(.custom("AeonikPro-Regular", size: 12))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                    }
                    
                    Spacer()
                    
                    // Radon value
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(MyUtil.valueReturnString(BLEData.Config.unit, dataPoint.value))
                            .font(.custom("AeonikPro-Bold", size: 24))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.156, green: 0.459, blue: 0.737))
                        
                        Text(connectionManager.unitString)
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                )
            } else {
                // Compact empty state
                HStack {
                    Text(formatSelectedDate())
                        .font(.custom("AeonikPro-Medium", size: 14))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    Spacer()
                    
                    Text("No data")
                        .font(.custom("AeonikPro-Regular", size: 14))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color(red: 0.98, green: 0.98, blue: 0.98))
                )
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(
                selectedDate: $selectedDate,
                startDate: measurementStartTime,
                endDate: measurementEndTime,
                onDismiss: {
                    showingDatePicker = false
                    // Update selected data point when date changes
                    selectedDataPoint = correspondingDataPoint
                }
            )
        }
        .onChange(of: selectedDate) { _ in
            // Update selected data point when date changes manually via date picker
            selectedDataPoint = correspondingDataPoint
        }
        .onChange(of: selectedDataPoint) { newValue in
            // Ensure UI updates when selectedDataPoint changes from chart selection
            // This triggers any dependent views to refresh
            if let dataPoint = newValue {
                MyUtil.printProcess(inMsg: "DateTimeSelectionView - selectedDataPoint updated: index \(dataPoint.index), time \(dataPoint.time)")
            }
        }
        .onAppear {
            // Initialize with current time and set initial data point
            selectedDate = measurementEndTime
            selectedDataPoint = correspondingDataPoint
        }
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Date Picker View
struct DatePickerView: View {
    @Binding var selectedDate: Date
    let startDate: Date
    let endDate: Date
    let onDismiss: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact info section (no title)
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Measurement Period:")
                                .font(.custom("AeonikPro-Medium", size: 14))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                            Spacer()
                        }
                        
                        VStack(spacing: 4) {
                            HStack {
                                Text("From:")
                                    .font(.custom("AeonikPro-Regular", size: 12))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                
                                Spacer()
                                
                                Text(formatDate(startDate))
                                    .font(.custom("AeonikPro-Medium", size: 12))
                                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            }
                            
                            HStack {
                                Text("To:")
                                    .font(.custom("AeonikPro-Regular", size: 12))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                
                                Spacer()
                                
                                Text(formatDate(endDate))
                                    .font(.custom("AeonikPro-Medium", size: 12))
                                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color(red: 0.976, green: 0.984, blue: 0.996))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Date picker (more prominent)
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: startDate...endDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10) // Reduced spacing
                
                Spacer()
            }
            .navigationTitle("") // Removed title
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                },
                trailing: Button("Done") {
                    onDismiss()
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Chart Container View (same as old implementation)
struct ChartContainerView: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    var selectedDataPoint: SelectedDataPoint? = nil
    var onPointSelected: ((Int) -> Void)? = nil // Add callback parameter
    @State private var selectedChartType: ChartDisplayType = .smooth
    @State private var selectedXAxisInterval: XAxisInterval = .all
    @State private var showChartSettings = false
    @State private var customMaxY: Double = 4.0
    @State private var customMinY: Double = -1.0 // Allow negative default
    @State private var useCustomYAxis: Bool = false
    @State private var customMaxX: Double? = nil
    @State private var customMinX: Double? = nil
    @State private var useCustomXAxis: Bool = false
    @State private var chartRefreshTrigger: Int = 0
    @State private var showGestureHint: Bool = false
    @State private var gestureHintTimer: Timer?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        // Full-screen chart area (edge-to-edge like old implementation)
        ZStack {
            Color(isDarkMode ? UIColor.systemBackground : UIColor.white) // Dynamic background
            
            if connectionManager.isLoadingChart {
                // Loading state with custom circular progress - LARGER AND CLEANER
                    VStack(spacing: 20) {
                        CircularProgressView(progress: Double(connectionManager.downloadPercent) / 100.0)
                            .frame(width: 120, height: 120) // Increased from 80 to 120
                        
                        VStack(spacing: 8) {
                            Text("Downloading chart data...")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            // REMOVED: Percentage text below the circle - it's now only inside the circle
                        }
                    }
                } else if connectionManager.showRefreshLabel {
                    // Empty state - encourage manual download
                    VStack(spacing: 76) {
                     
                        
                        VStack(spacing: 18) {
                            Text(" ")
                                .font(.custom("AeonikPro-Bold", size: 18))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                        }
                        
                        if !connectionManager.isConnected {
                            Text("Connect to device first")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Remove tap gesture - user must use download button
                } else if let error = connectionManager.chartError {
                    // Error state
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.red)
                        
                        VStack(spacing: 8) {
                            Text("Download Failed")
                                .font(.custom("AeonikPro-Bold", size: 18))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text(error)
                                .font(.custom("AeonikPro-Regular", size: 16))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            if connectionManager.isConnected {
                                Text("Try downloading again using the button below")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                                    .padding(.top, 8)
                            }
                        }
                    }
                } else if connectionManager.flagChartView && !connectionManager.chartData.isEmpty && connectionManager.chartData.count >= 10 {
                    // Chart with data - edge to edge (like old implementation)
                    // SAFETY: Only show chart if we have sufficient data points
                    ZStack {
                        ChartWithSliderView(
                            connectionManager: connectionManager,
                            chartType: selectedChartType,
                            xAxisInterval: selectedXAxisInterval,
                            customMaxY: useCustomYAxis ? customMaxY : nil,
                            customMinY: useCustomYAxis ? customMinY : nil,
                            refreshTrigger: chartRefreshTrigger,
                            selectedDataPoint: selectedDataPoint,
                            onPointSelected: onPointSelected
                        )
                        
                        // Gesture hint overlay
                        if showGestureHint {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    
                                    VStack(spacing: 8) {
                                        HStack(spacing: 12) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "hand.draw")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                Text("Drag")
                                                    .font(.custom("AeonikPro-Medium", size: 12))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Rectangle()
                                                .fill(.white.opacity(0.3))
                                                .frame(width: 1, height: 16)
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "hand.pinch")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                Text("Pinch")
                                                    .font(.custom("AeonikPro-Medium", size: 12))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Rectangle()
                                                .fill(.white.opacity(0.3))
                                                .frame(width: 1, height: 16)
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "hand.tap")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                Text("Tap")
                                                    .font(.custom("AeonikPro-Medium", size: 12))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Text("Tap points for time lookup")
                                            .font(.custom("AeonikPro-Regular", size: 10))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.black.opacity(0.75))
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 120) // Position above sliders
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            .zIndex(1)
                        }
                    }
                } else if !connectionManager.isInitializingDownload {
                    // Empty state - only show when not initializing download
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                        
                        VStack(spacing: 8) {
                            Text("No chart data available")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.376, green: 0.376, blue: 0.376))
                            
                            if !connectionManager.isConnected {
                                Text("Connect to device first")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                            } else {
                                Text("Use the download button below to get data")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                            }
                        }
                    }
                }
            
            // Chart Settings Button - Top Right Corner
            if connectionManager.flagChartView && !connectionManager.chartData.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            showChartSettings = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.156, green: 0.459, blue: 0.737))
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showChartSettings) {
            ChartSettingsView(
                selectedChartType: $selectedChartType,
                selectedXAxisInterval: $selectedXAxisInterval,
                customMaxY: $customMaxY,
                customMinY: $customMinY,
                useCustomYAxis: $useCustomYAxis,
                customMaxX: $customMaxX,
                customMinX: $customMinX,
                useCustomXAxis: $useCustomXAxis,
                onSettingsChange: {
                    chartRefreshTrigger += 1
                }
            )
        }
        .onAppear {
            // Load saved Y-axis settings from UserDefaults
            customMaxY = UserDefaults.standard.object(forKey: "ChartCustomMaxY") as? Double ?? 4.0
            customMinY = UserDefaults.standard.object(forKey: "ChartCustomMinY") as? Double ?? -1.0
            useCustomYAxis = UserDefaults.standard.bool(forKey: "ChartUseCustomYAxis")
            
            // Load saved X-axis settings from UserDefaults
            customMaxX = UserDefaults.standard.object(forKey: "ChartCustomMaxX") as? Double
            customMinX = UserDefaults.standard.object(forKey: "ChartCustomMinX") as? Double
            useCustomXAxis = UserDefaults.standard.bool(forKey: "ChartUseCustomXAxis")
        }
        .onChange(of: customMaxY) { newValue in
            UserDefaults.standard.set(newValue, forKey: "ChartCustomMaxY")
        }
        .onChange(of: customMinY) { newValue in
            UserDefaults.standard.set(newValue, forKey: "ChartCustomMinY")
        }
        .onChange(of: useCustomYAxis) { newValue in
            UserDefaults.standard.set(newValue, forKey: "ChartUseCustomYAxis")
        }
        .onChange(of: customMaxX) { newValue in
            UserDefaults.standard.set(newValue, forKey: "ChartCustomMaxX")
        }
        .onChange(of: customMinX) { newValue in
            UserDefaults.standard.set(newValue, forKey: "ChartCustomMinX")
        }
        .onChange(of: useCustomXAxis) { newValue in
            UserDefaults.standard.set(newValue, forKey: "ChartUseCustomXAxis")
        }
        .onChange(of: connectionManager.flagChartView) { flagChartView in
            // Show gesture hint when chart becomes available
            if flagChartView && !connectionManager.chartData.isEmpty {
                showGestureHintWithDelay()
            }
        }
        .onDisappear {
            gestureHintTimer?.invalidate()
        }
    }
    
    private func showGestureHintWithDelay() {
        // Cancel any existing timer
        gestureHintTimer?.invalidate()
        
        // Show hint after a brief delay to let chart load
        gestureHintTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showGestureHint = true
            }
            
            // Hide hint after 3 seconds
            gestureHintTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGestureHint = false
                }
            }
        }
    }
}

// MARK: - Current Radon Card (ALWAYS VISIBLE)
struct CurrentRadonCard: View {
    let value: Float
    let unit: String
    let status: (title: String, color: Color, backgroundColor: Color)
    let vibrationOn: Bool
    let measurementTime: UInt32
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingRadonInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Level")
                        .font(.custom("AeonikPro-Medium", size: 14))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                    
                    Text(status.title)
                        .font(.custom("AeonikPro-Bold", size: 18))
                        .foregroundColor(status.color)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: vibrationOn ? "wave.3.right" : "wave.3.right.slash")
                        .foregroundColor(vibrationOn ? Color.green : Color.gray)
                    
                    Text(vibrationOn ? "Vibration On" : "Vibration Off")
                        .font(.custom("AeonikPro-Regular", size: 12))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                    
                    // Info button
                    Button(action: {
                        showingRadonInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(red: 0.576, green: 0.576, blue: 0.576))
                    }
                }
            }
            
            // Large value display - IDENTICAL to old implementation logic
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    // Use same logic as old implementation: show 0 with unit 2 when measTime < 10
                    let displayUnit: UInt8 = measurementTime < 10 ? 2 : (unit.contains("Bq") ? 1 : 0)
                    let displayValue = measurementTime < 10 ? 0 : value
                    
                    Text(MyUtil.valueReturnString(displayUnit, displayValue).trimmingCharacters(in: .whitespaces))
                        .font(.custom("AeonikPro-Bold", size: 48))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    Text(measurementTime < 10 ? "--" : unit)
                        .font(.custom("AeonikPro-Medium", size: 20))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                }
                
                // Progress bar showing risk level
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(status.color)
                            .frame(width: min(geometry.size.width * CGFloat(min(value / 6.0, 1.0)), geometry.size.width), height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.8), value: value)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(24)
        .padding(.top, 8) // Add extra top padding to prevent border cutoff
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(status.color.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .fullScreenCover(isPresented: $showingRadonInfo) {
            RadonLevelsInfoView()
        }
    }
}

// MARK: - Measurement Time Card (ALWAYS VISIBLE)
struct MeasurementTimeCard: View {
    let timeString: String
    let totalMinutes: UInt32
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Measurement Time")
                    .font(.custom("AeonikPro-Bold", size: 16))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                
                Text(timeString)
                    .font(.custom("AeonikPro-Bold", size: 24))
                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalMinutes)")
                    .font(.custom("AeonikPro-Bold", size: 20))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                
                Text("total minutes")
                    .font(.custom("AeonikPro-Regular", size: 12))
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Metric Card (conditional display based on measurement time)
struct MetricCard: View {
    let title: String
    let value: Float
    let unit: String
    let icon: String
    let color: Color
    let showValue: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AeonikPro-Medium", size: 14))
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    // Same logic as old implementation: show 0 with unit 2 when not enough time
                    let displayUnit: UInt8 = showValue ? (unit.contains("Bq") ? 1 : 0) : 2
                    let displayValue = showValue ? value : 0
                    
                    Text(MyUtil.valueReturnString(displayUnit, displayValue).trimmingCharacters(in: .whitespaces))
                        .font(.custom("AeonikPro-Bold", size: 20))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    Text(showValue ? unit : "--")
                        .font(.custom("AeonikPro-Medium", size: 14))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Alarm Interval Enum
enum AlarmInterval: String, CaseIterable {
    case tenMinutes = "10 Minutes"
    case oneHour = "1 Hour"  
    case sixHours = "6 Hours"
    case custom = "Custom"
    
    var minutes: Int {
        switch self {
        case .tenMinutes: return 10
        case .oneHour: return 60
        case .sixHours: return 360
        case .custom: return 60 // Default, will be overridden
        }
    }
}

// MARK: - Chart Settings View
struct ChartSettingsView: View {
    @Binding var selectedChartType: ChartDisplayType
    @Binding var selectedXAxisInterval: XAxisInterval
    @Binding var customMaxY: Double
    @Binding var customMinY: Double
    @Binding var useCustomYAxis: Bool
    @Binding var customMaxX: Double?
    @Binding var customMinX: Double?
    @Binding var useCustomXAxis: Bool
    let onSettingsChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var maxYString: String = ""
    @State private var minYString: String = ""
    @State private var maxXString: String = ""
    @State private var minXString: String = ""
    
    // Unit and Alarm Settings
    @State private var selectedUnit: Int = 0 // 0 = pCi/L, 1 = Bq/m³
    @State private var alarmEnabled: Bool = false
    @State private var alarmValue: Double = 4.0
    @State private var alarmValueString: String = ""
    @State private var selectedAlarmInterval: AlarmInterval = .oneHour
    @State private var customAlarmMinutes: Int = 60
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart Type Section - Simplified to show only the current chart type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chart Display")
                            .font(.custom("AeonikPro-Bold", size: 16))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                .font(.system(size: 18))
                            
                            Text("Smooth Line Chart")
                                .font(.custom("AeonikPro-Medium", size: 14))
                                .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // X-Axis Interval Section
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data Intervals")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text("Reduce point density while preserving full timeline")
                                .font(.custom("AeonikPro-Regular", size: 12))
                                .foregroundColor(Color(red: 0.576, green: 0.576, blue: 0.576))
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            CompactIntervalOption(
                                title: "All",
                                subtitle: "Every point",
                                isSelected: selectedXAxisInterval == .all,
                                action: { 
                                    selectedXAxisInterval = .all
                                    onSettingsChange()
                                }
                            )
                            
                            CompactIntervalOption(
                                title: "Every 5th",
                                subtitle: "1/5 density",
                                isSelected: selectedXAxisInterval == .every5,
                                action: { 
                                    selectedXAxisInterval = .every5
                                    onSettingsChange()
                                }
                            )
                            
                            CompactIntervalOption(
                                title: "Every 10th",
                                subtitle: "1/10 density",
                                isSelected: selectedXAxisInterval == .every10,
                                action: { 
                                    selectedXAxisInterval = .every10
                                    onSettingsChange()
                                }
                            )
                            
                            CompactIntervalOption(
                                title: "Every 30th",
                                subtitle: "1/30 density",
                                isSelected: selectedXAxisInterval == .every30,
                                action: { 
                                    selectedXAxisInterval = .every30
                                    onSettingsChange()
                                }
                            )
                            
                            CompactIntervalOption(
                                title: "Hourly",
                                subtitle: "Avg/hour",
                                isSelected: selectedXAxisInterval == .hourly,
                                action: { 
                                    selectedXAxisInterval = .hourly
                                    onSettingsChange()
                                }
                            )
                            
                            CompactIntervalOption(
                                title: "Daily",
                                subtitle: "Avg/day",
                                isSelected: selectedXAxisInterval == .daily,
                                action: { 
                                    selectedXAxisInterval = .daily
                                    onSettingsChange()
                                }
                            )
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // Y-Axis Range Controls
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Y-Axis Range")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Spacer()
                            
                            Toggle("", isOn: $useCustomYAxis)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.156, green: 0.459, blue: 0.737)))
                                .onChange(of: useCustomYAxis) { _ in
                                    onSettingsChange()
                                }
                        }
                        
                        if useCustomYAxis {
                            VStack(spacing: 16) {
                                // Maximum Y Value
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Maximum")
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        Spacer()
                                        Text(String(format: "%.1f", customMaxY))
                                            .font(.custom("AeonikPro-Bold", size: 14))
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    }
                                    
                                    Slider(value: $customMaxY, in: -5...20, step: 0.1)
                                        .accentColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        .onChange(of: customMaxY) { _ in
                                            onSettingsChange()
                                        }
                                }
                                
                                // Minimum Y Value
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Minimum")
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        Spacer()
                                        Text(String(format: "%.1f", customMinY))
                                            .font(.custom("AeonikPro-Bold", size: 14))
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    }
                                    
                                    Slider(value: $customMinY, in: -5...15, step: 0.1)
                                        .accentColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        .onChange(of: customMinY) { _ in
                                            onSettingsChange()
                                        }
                                }
                                
                                // Quick preset buttons
                                HStack(spacing: 8) {
                                    Button("Auto") {
                                        useCustomYAxis = false
                                        onSettingsChange()
                                    }
                                    .buttonStyle(PresetButtonStyle(isSelected: false))
                                    
                                    Button("0-10") {
                                        customMinY = 0
                                        customMaxY = 10
                                        onSettingsChange()
                                    }
                                    .buttonStyle(PresetButtonStyle(isSelected: false))
                                    
                                    Button("-2-5") {
                                        customMinY = -2
                                        customMaxY = 5
                                        onSettingsChange()
                                    }
                                    .buttonStyle(PresetButtonStyle(isSelected: false))
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // X-Axis Range Controls
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("X-Axis Range")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Spacer()
                            
                            Toggle("", isOn: $useCustomXAxis)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.156, green: 0.459, blue: 0.737)))
                                .onChange(of: useCustomXAxis) { _ in
                                    onSettingsChange()
                                }
                        }
                        
                        if useCustomXAxis {
                            VStack(spacing: 16) {
                                // Data Point Range
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Data Points")
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        Spacer()
                                        Text("\(Int(customMaxX ?? 100))")
                                            .font(.custom("AeonikPro-Bold", size: 14))
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    }
                                    
                                    Slider(
                                        value: Binding(
                                            get: { customMaxX ?? 100.0 },
                                            set: { customMaxX = $0 }
                                        ),
                                        in: 10...1000,
                                        step: 10
                                    )
                                    .accentColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .onChange(of: customMaxX) { _ in
                                        onSettingsChange()
                                    }
                                }
                                
                                // Starting Offset
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Start Offset")
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        Spacer()
                                        Text("\(Int(customMinX ?? 0))")
                                            .font(.custom("AeonikPro-Bold", size: 14))
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    }
                                    
                                    Slider(
                                        value: Binding(
                                            get: { customMinX ?? 0.0 },
                                            set: { customMinX = $0 }
                                        ),
                                        in: 0...500,
                                        step: 5
                                    )
                                    .accentColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .onChange(of: customMinX) { _ in
                                        onSettingsChange()
                                    }
                                }
                                
                                // Quick preset buttons
                                HStack(spacing: 8) {
                                    Button("Auto") {
                                        useCustomXAxis = false
                                        onSettingsChange()
                                    }
                                    .buttonStyle(PresetButtonStyle(isSelected: false))
                                    
                                    Button("Last 100") {
                                        customMinX = nil
                                        customMaxX = 100
                                        onSettingsChange()
                                    }
                                    .buttonStyle(PresetButtonStyle(isSelected: false))
                                    
                                    Button("Last 50") {
                                        customMinX = nil
                                        customMaxX = 50
                                        onSettingsChange()
                                    }
                                    .buttonStyle(PresetButtonStyle(isSelected: false))
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // Unit Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Display Units")
                            .font(.custom("AeonikPro-Bold", size: 16))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            UnitSelectionOption(
                                title: "pCi/ℓ",
                                subtitle: "US Standard",
                                isSelected: selectedUnit == 0,
                                action: { 
                                    selectedUnit = 0
                                    updateAlarmValueForUnit()
                                    onSettingsChange()
                                }
                            )
                            
                            UnitSelectionOption(
                                title: "Bq/m³",
                                subtitle: "International",
                                isSelected: selectedUnit == 1,
                                action: { 
                                    selectedUnit = 1
                                    updateAlarmValueForUnit()
                                    onSettingsChange()
                                }
                            )
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // Alarm Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Alarm Settings")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Spacer()
                            
                                                         Toggle("Enabled", isOn: $alarmEnabled)
                                 .onChange(of: alarmEnabled) { _ in
                                     saveAlarmSettings()
                                     onSettingsChange()
                                 }
                        }
                        
                        if alarmEnabled {
                            VStack(spacing: 12) {
                                // Alarm Value
                                HStack {
                                    Text("Alarm Level:")
                                        .font(.custom("AeonikPro-Medium", size: 14))
                                        .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("Alarm Value", text: $alarmValueString)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                                                                 .onChange(of: alarmValueString) { newValue in
                                             if let doubleValue = Double(newValue), doubleValue > 0 {
                                                 alarmValue = doubleValue
                                                 saveAlarmSettings()
                                                 onSettingsChange()
                                             }
                                         }
                                    
                                    Text(selectedUnit == 0 ? "pCi/ℓ" : "Bq/m³")
                                        .font(.custom("AeonikPro-Regular", size: 14))
                                        .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        .frame(width: 50)
                                }
                                
                                // Alarm Interval
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Alarm Interval:")
                                        .font(.custom("AeonikPro-Medium", size: 14))
                                        .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 8) {
                                        ForEach(AlarmInterval.allCases, id: \.self) { interval in
                                                                                         AlarmIntervalOption(
                                                 interval: interval,
                                                 isSelected: selectedAlarmInterval == interval,
                                                 action: { 
                                                     selectedAlarmInterval = interval
                                                     saveAlarmSettings()
                                                     onSettingsChange()
                                                 }
                                             )
                                        }
                                    }
                                    
                                    // Custom interval input
                                    if selectedAlarmInterval == .custom {
                                        HStack {
                                            Text("Custom:")
                                                .font(.custom("AeonikPro-Medium", size: 14))
                                                .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                                .frame(width: 60, alignment: .leading)
                                            
                                            TextField("Minutes", value: $customAlarmMinutes, format: .number)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .keyboardType(.numberPad)
                                                                                                 .onChange(of: customAlarmMinutes) { _ in
                                                     saveAlarmSettings()
                                                     onSettingsChange()
                                                 }
                                            
                                            Text("minutes")
                                                .font(.custom("AeonikPro-Regular", size: 14))
                                                .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // Chart Navigation Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chart Navigation")
                            .font(.custom("AeonikPro-Bold", size: 16))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.and.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                
                                Text("Scroll slider: Move viewing window left/right")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.below.rectangle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                
                                Text("Range slider: Adjust how many points to show")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "hand.point.up.braille")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                
                                Text("Touch gestures: Drag to pan, pinch to zoom, tap to select")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1))
                        )
                        
                        Text("The sliders and touch gestures sync automatically. Use scroll to navigate, range to zoom in/out on data density, or touch gestures for intuitive chart interaction. Tap any data point to see its exact time and value in the lookup section below.")
                            .font(.custom("AeonikPro-Regular", size: 12))
                            .foregroundColor(Color(red: 0.576, green: 0.576, blue: 0.576))
                    }
                    
                    // Bottom spacing to prevent cut-off
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Chart Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { 
                    dismiss() 
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
            .onAppear {
                // Initialize string values from the current Double values
                maxYString = String(customMaxY)
                minYString = String(customMinY)
                maxXString = customMaxX != nil ? String(Int(customMaxX!)) : "100"
                minXString = customMinX != nil ? String(Int(customMinX!)) : "0"
                
                // Load settings from UserDefaults and BLEData
                selectedUnit = Int(BLEData.Config.unit)
                alarmEnabled = BLEData.Config.alarmStatus != 0
                alarmValue = Double(BLEData.Config.alarmValue)
                alarmValueString = String(alarmValue)
                
                // Load alarm interval from UserDefaults
                let savedInterval = UserDefaults.standard.string(forKey: "AlarmInterval") ?? "1 Hour"
                selectedAlarmInterval = AlarmInterval.allCases.first { $0.rawValue == savedInterval } ?? .oneHour
                customAlarmMinutes = UserDefaults.standard.integer(forKey: "CustomAlarmMinutes")
                if customAlarmMinutes == 0 { customAlarmMinutes = 60 }
            }
        }
    }
    
    // Helper functions for unit conversion and settings management
    private func updateAlarmValueForUnit() {
        // Convert alarm value when switching units
        if selectedUnit == 0 && BLEData.Config.unit == 1 {
            // Converting from Bq/m³ to pCi/ℓ (divide by 37)
            alarmValue = alarmValue / 37.0
        } else if selectedUnit == 1 && BLEData.Config.unit == 0 {
            // Converting from pCi/ℓ to Bq/m³ (multiply by 37)
            alarmValue = alarmValue * 37.0
        }
        
        alarmValueString = String(format: "%.1f", alarmValue)
        
        // Update BLEData settings
        BLEData.Config.unit = UInt8(selectedUnit)
        BLEData.Config.alarmValue = Float(alarmValue)
        
        // Save to UserDefaults
        UserDefaults.standard.set(selectedUnit, forKey: "DisplayUnit")
        UserDefaults.standard.set(alarmValue, forKey: "AlarmValue")
    }
    
    private func saveAlarmSettings() {
        // Update BLEData
        BLEData.Config.alarmStatus = alarmEnabled ? 1 : 0
        BLEData.Config.alarmValue = Float(alarmValue)
        
        // Save to UserDefaults
        UserDefaults.standard.set(alarmEnabled, forKey: "AlarmEnabled")
        UserDefaults.standard.set(alarmValue, forKey: "AlarmValue")
        UserDefaults.standard.set(selectedAlarmInterval.rawValue, forKey: "AlarmInterval")
        UserDefaults.standard.set(customAlarmMinutes, forKey: "CustomAlarmMinutes")
    }
}

// MARK: - Compact Chart Settings Option Views
struct CompactChartTypeOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.576, green: 0.576, blue: 0.576))
                
                Text(title)
                    .font(.custom("AeonikPro-Medium", size: 12))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.173, green: 0.173, blue: 0.173))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) : Color.gray.opacity(0.05))
                    .stroke(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactIntervalOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.custom("AeonikPro-Medium", size: 12))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.173, green: 0.173, blue: 0.173))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.custom("AeonikPro-Regular", size: 10))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.8) : Color(red: 0.576, green: 0.576, blue: 0.576))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) : Color.gray.opacity(0.05))
                    .stroke(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unit Selection Option
struct UnitSelectionOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.custom("AeonikPro-Bold", size: 16))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.173, green: 0.173, blue: 0.173))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.custom("AeonikPro-Regular", size: 12))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.8) : Color(red: 0.576, green: 0.576, blue: 0.576))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) : Color.gray.opacity(0.05))
                    .stroke(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Alarm Interval Option
struct AlarmIntervalOption: View {
    let interval: AlarmInterval
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(interval.rawValue)
                    .font(.custom("AeonikPro-Medium", size: 12))
                    .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.173, green: 0.173, blue: 0.173))
                    .multilineTextAlignment(.center)
                
                if interval != .custom {
                    Text("\(interval.minutes) min")
                        .font(.custom("AeonikPro-Regular", size: 10))
                        .foregroundColor(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.8) : Color(red: 0.576, green: 0.576, blue: 0.576))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) : Color.gray.opacity(0.05))
                    .stroke(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat = 10 // Increased from 8 to 10 for larger circle
    
    var body: some View {
        ZStack {
            // Background circle with subtle shadow
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
            
            // Progress circle with gradient effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.156, green: 0.459, blue: 0.737),
                            Color(red: 0.2, green: 0.5, blue: 0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Inner content - LARGER TEXT
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))")
                    .font(.custom("AeonikPro-Bold", size: 28)) // Increased from 20 to 28
                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                
                Text("%")
                    .font(.custom("AeonikPro-Medium", size: 16)) // Increased from 12 to 16
                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.8))
            }
        }
    }
}

// MARK: - SwiftUI Chart View (using Charts framework - with gesture support)
struct SwiftUIChartView: UIViewRepresentable {
    @ObservedObject var connectionManager: BLEConnectionManager
    let chartType: ChartDisplayType
    let xAxisInterval: XAxisInterval
    let customMaxY: Double?
    let customMinY: Double?
    @Binding var customMaxX: Double? // Changed to @Binding for gesture updates
    @Binding var customMinX: Double? // Changed to @Binding for gesture updates
    let refreshTrigger: Int
    var selectedDataPoint: SelectedDataPoint? = nil
    
    // Gesture state bindings to sync with sliders
    @Binding var sliderValue: Double
    @Binding var horizontalOffset: Double
    @Binding var maxDataPoints: Double
    
    // Chart point selection callback
    var onPointSelected: ((Int) -> Void)?
    
    @State private var currentMaxX: Double = 100.0
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    class Coordinator: NSObject {
        var parent: SwiftUIChartView
        var initialPanOffset: Double = 0
        var initialPinchRange: Double = 0
        var initialPinchOffset: Double = 0
        var pinchCenterPoint: Double = 0 // Center point of the visible range when pinch began
        
        init(_ parent: SwiftUIChartView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let chartView = gesture.view as? LineChartView else { return }
            
            let translation = gesture.translation(in: chartView)
            let chartWidth = chartView.bounds.width
            
            // Convert pixel movement to data point movement
            // Negative because dragging right should move chart left (showing earlier data)
            let dataPointsPerPixel = parent.sliderValue / Double(chartWidth)
            let dataPointMovement = -Double(translation.x) * dataPointsPerPixel * 1.2
            
            switch gesture.state {
            case .began:
                initialPanOffset = parent.horizontalOffset
                
            case .changed:
                let newOffset = initialPanOffset + dataPointMovement
                let maxValidOffset = max(0, parent.maxDataPoints - parent.sliderValue)
                let clampedOffset = max(0, min(maxValidOffset, newOffset))
                
                DispatchQueue.main.async {
                    self.parent.horizontalOffset = clampedOffset
                    self.parent.customMinX = clampedOffset
                }
                
            case .ended, .cancelled:
                // Snap to nearest data point for cleaner positioning
                let snappedOffset = round(parent.horizontalOffset)
                let maxValidOffset = max(0, parent.maxDataPoints - parent.sliderValue)
                let finalOffset = max(0, min(maxValidOffset, snappedOffset))
                
                DispatchQueue.main.async {
                    self.parent.horizontalOffset = finalOffset
                    self.parent.customMinX = finalOffset
                }
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.view is LineChartView else { return }
            
            let scale = gesture.scale
            
            switch gesture.state {
            case .began:
                // Store initial state
                initialPinchRange = parent.sliderValue
                initialPinchOffset = parent.horizontalOffset
                
                // Calculate the center point of the current visible range
                // This is what we want to keep fixed during zoom
                pinchCenterPoint = initialPinchOffset + (initialPinchRange / 2.0)
                
                
            case .changed:
                // Calculate new range based on scale
                // Invert scale for intuitive behavior: pinch out = zoom in, pinch in = zoom out
                let invertedScale = 1.0 / Double(scale)
                let newRange = initialPinchRange * invertedScale
                let clampedRange = max(10, min(parent.maxDataPoints, newRange))
                
                // Calculate new offset to keep the center point fixed
                // Center point should remain at: newOffset + (newRange / 2) = pinchCenterPoint
                // Therefore: newOffset = pinchCenterPoint - (newRange / 2)
                let newOffset = pinchCenterPoint - (clampedRange / 2.0)
                
                // Ensure offset is within valid bounds
                let maxValidOffset = max(0, parent.maxDataPoints - clampedRange)
                let clampedOffset = max(0, min(maxValidOffset, newOffset))
                
                DispatchQueue.main.async {
                    self.parent.sliderValue = clampedRange
                    self.parent.horizontalOffset = clampedOffset
                    self.parent.customMaxX = clampedRange
                    self.parent.customMinX = clampedOffset
                }
                
            case .ended, .cancelled:
                // Snap to reasonable values while maintaining the center as much as possible
                let snappedRange = round(parent.sliderValue)
                let clampedRange = max(10, min(parent.maxDataPoints, snappedRange))
                
                // Try to maintain the center point
                let targetOffset = pinchCenterPoint - (clampedRange / 2.0)
                let maxValidOffset = max(0, parent.maxDataPoints - clampedRange)
                let clampedOffset = max(0, min(maxValidOffset, round(targetOffset)))
                
                DispatchQueue.main.async {
                    self.parent.sliderValue = clampedRange
                    self.parent.horizontalOffset = clampedOffset
                    self.parent.customMaxX = clampedRange
                    self.parent.customMinX = clampedOffset
                }
                
                // Reset gesture scale for next interaction
                gesture.scale = 1.0
                
            default:
                break
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        
        // Disable chart's built-in pan/zoom gestures to prevent conflicts
        chartView.dragEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.highlightPerTapEnabled = true // Re-enable point selection
        
        // Set up highlight delegate for point selection
        chartView.delegate = context.coordinator
        
        // Add custom gesture recognizers with improved configuration
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1 // Only single finger pan
        panGesture.cancelsTouchesInView = false // Allow chart selection to work
        chartView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.cancelsTouchesInView = false // Allow chart selection to work
        chartView.addGestureRecognizer(pinchGesture)
        
        // Set up gesture delegates for proper interaction
        panGesture.delegate = context.coordinator
        pinchGesture.delegate = context.coordinator
        
        // Set up the chart
        updateChart(chartView, forceUpdate: true)
        
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        // Update when data changes OR when settings change (refreshTrigger)
        if connectionManager.chartDataAvailable && !connectionManager.chartData.isEmpty {
            updateChart(uiView, forceUpdate: false)
            
            // Highlight selected data point if provided
            if let selectedPoint = selectedDataPoint {
                // Ensure the highlight is visible and correctly positioned
                DispatchQueue.main.async {
                    self.highlightDataPoint(uiView, index: selectedPoint.index)
                }
            } else {
                // Clear any existing highlights when no point is selected
                uiView.highlightValue(nil)
            }
        }
    }
    
    private func updateChart(_ chartView: LineChartView, forceUpdate: Bool) {
        // Check if we need to update by comparing data count OR settings change
        let currentDataCount = connectionManager.chartData.count
        let chartDataCount = chartView.data?.entryCount ?? 0
        
        // Always update when forced or when data/settings change
        if forceUpdate || currentDataCount != chartDataCount || chartView.data == nil || refreshTrigger > 0 {
            // Use the chart drawing logic with new configuration options
            // Apply default Y range (-1 to 4) when custom Y-axis is not enabled
            let effectiveMaxY = customMaxY ?? 4.0
            let effectiveMinY = customMinY ?? -1.0
            
            chartsControl.chartDraw(
                chartView,
                connectionManager.chartData,
                MyUtil.refUnit(inMove: MyStruct.v2Mode),
                Int(BLEData.Config.unit),
                Double(BLEData.Config.alarmValue),
                BLEData.Flag.V3_New,
                chartType: chartType,
                xAxisInterval: xAxisInterval,
                customMaxY: effectiveMaxY,
                customMinY: effectiveMinY,
                customMaxX: customMaxX ?? currentMaxX,
                customMinX: customMinX,
                isDarkMode: isDarkMode
            )
            
            // Initialize currentMaxX if needed
            if currentMaxX == 100.0 && currentDataCount > 0 {
                currentMaxX = Double(min(currentDataCount, 100))
            }
        }
    }
    
    private func highlightDataPoint(_ chartView: LineChartView, index: Int) {
        // Get the chart data
        guard let chartData = chartView.data,
              let dataSet = chartData.dataSets.first as? LineChartDataSet,
              index < dataSet.entryCount else {
            return
        }
        
        // Get the entry at the specified index and safely unwrap it
        guard let entry = dataSet.entryForIndex(index) else {
            return
        }
        
        // Create highlight for the specific data point
        let highlight = Highlight(x: entry.x, y: entry.y, dataSetIndex: 0)
        
        // Apply the highlight to the chart
        chartView.highlightValue(highlight)
    }
}

// MARK: - UIGestureRecognizerDelegate extension for Coordinator
extension SwiftUIChartView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Prevent simultaneous pan and pinch for cleaner center-fixed zoom behavior
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return false
        }
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        
        // Allow gestures to work with chart's built-in tap selection
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Always allow our custom gestures to receive touches
        return true
    }
}

// MARK: - ChartViewDelegate extension for Coordinator
extension SwiftUIChartView.Coordinator: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // Convert chart entry X value to data point index
        let selectedIndex = Int(entry.x)
        
        // Validate index is within bounds
        guard selectedIndex >= 0 && selectedIndex < parent.connectionManager.chartData.count else {
            return
        }
        
        // Call the point selection callback immediately to update the time lookup
        DispatchQueue.main.async {
            self.parent.onPointSelected?(selectedIndex)
        }
        
        MyUtil.printProcess(inMsg: "SwiftUIChartView - Point selected: index \(selectedIndex), value \(entry.y) - Time lookup will update")
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Optional: Handle deselection if needed
        MyUtil.printProcess(inMsg: "SwiftUIChartView - No point selected")
    }
}

// MARK: - Chart Info View (same as old implementation dialog)
struct ChartInfoView: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                Text("Chart Statistics")
                    .font(.custom("AeonikPro-Bold", size: 24))
                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                    .padding(.top, 20)
                
                // Statistics (same as old implementation)
                VStack(spacing: 20) {
                    StatisticInfoRow(
                        title: "Data Points",
                        value: "\(connectionManager.chartDataCount)",
                        unit: "readings"
                    )
                    
                    StatisticInfoRow(
                        title: "Max Value",
                        value: MyUtil.valueReturnString(BLEData.Config.unit, connectionManager.chartMaxValue),
                        unit: connectionManager.unitString
                    )
                    
                    StatisticInfoRow(
                        title: "Min Value", 
                        value: MyUtil.valueReturnString(BLEData.Config.unit, connectionManager.chartMinValue),
                        unit: connectionManager.unitString
                    )
                    
                    StatisticInfoRow(
                        title: "Average",
                        value: MyUtil.valueReturnString(BLEData.Config.unit, connectionManager.chartAverage),
                        unit: connectionManager.unitString
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Chart Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Data Statistics Card (same as old implementation)
struct DataStatisticsCard: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Statistics")
                .font(.custom("AeonikPro-Bold", size: 18))
                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
            
            if connectionManager.chartDataAvailable {
                VStack(spacing: 12) {
                    StatisticRow(
                        title: "Max Value",
                        value: MyUtil.valueReturnString(BLEData.Config.unit, connectionManager.chartMaxValue),
                        unit: connectionManager.unitString
                    )
                    StatisticRow(
                        title: "Min Value",
                        value: MyUtil.valueReturnString(BLEData.Config.unit, connectionManager.chartMinValue),
                        unit: connectionManager.unitString
                    )
                    StatisticRow(
                        title: "Average",
                        value: MyUtil.valueReturnString(BLEData.Config.unit, connectionManager.chartAverage),
                        unit: connectionManager.unitString
                    )
                    StatisticRow(
                        title: "Data Points",
                        value: "\(connectionManager.chartDataCount)",
                        unit: "readings"
                    )
                }
            } else {
                VStack(spacing: 12) {
                    StatisticRow(title: "Max Value", value: "--", unit: "--")
                    StatisticRow(title: "Min Value", value: "--", unit: "--")
                    StatisticRow(title: "Average", value: "--", unit: "--")
                    StatisticRow(title: "Data Points", value: "--", unit: "readings")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Data Actions Card (same as old implementation)
struct DataActionsCard: View {
    let isEnabled: Bool
    let onExport: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Data Actions")
                .font(.custom("AeonikPro-Bold", size: 18))
                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                if isEnabled {
                    onExport()
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                    Text("Export Data")
                        .font(.custom("AeonikPro-Medium", size: 16))
                }
                .foregroundColor(isEnabled ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isEnabled ? 
                    Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) :
                    Color.gray.opacity(0.1)
                )
                .cornerRadius(12)
            }
            .disabled(!isEnabled)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Statistic Row
struct StatisticRow: View {
    let title: String
    let value: String
    let unit: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("AeonikPro-Regular", size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.custom("AeonikPro-Medium", size: 14))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                
                Text(unit)
                    .font(.custom("AeonikPro-Regular", size: 12))
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
            }
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            
            Text(message)
                .font(.custom("AeonikPro-Regular", size: 14))
                .foregroundColor(.red)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Loading Overlay (similar to old implementation)
struct LoadingOverlay: View {
    let deviceName: String
    let message: String
    let isError: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var animationStarted = false
    
    var body: some View {
        ZStack {
            // Semi-transparent black background
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 24) {
                // Device icon
                Image(systemName: isError ? "exclamationmark.triangle.fill" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(isError ? .red : Color(red: 0.156, green: 0.459, blue: 0.737))
                
                // Loading indicator (only show if not error)
                if !isError {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(red: 0.156, green: 0.459, blue: 0.737))
                }
                
                // Device name
                VStack(spacing: 8) {
                    Text(deviceName)
                        .font(.custom("AeonikPro-Bold", size: 20))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.custom("AeonikPro-Regular", size: 16))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                        .multilineTextAlignment(.center)
                }
                
                // Connection status indicator (only show if not error)
                if !isError {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                                .frame(width: 8, height: 8)
                                .opacity(animationStarted ? 1.0 : 0.3)
                                .scaleEffect(animationStarted ? 1.2 : 1.0)
                                .animation(
                                    Animation
                                        .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: animationStarted
                                )
                        }
                    }
                    .onAppear {
                        animationStarted = true
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: true)
    }
}

// MARK: - Statistic Info Row (for chart info dialog)
struct StatisticInfoRow: View {
    let title: String
    let value: String
    let unit: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value.trimmingCharacters(in: .whitespaces))
                    .font(.custom("AeonikPro-Bold", size: 24))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                
                if unit != "readings" {
                    Text(unit)
                        .font(.custom("AeonikPro-Regular", size: 16))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                } else {
                    Text(unit)
                        .font(.custom("AeonikPro-Regular", size: 16))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color(red: 0.976, green: 0.984, blue: 0.996))
        )
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
// Note: Preview disabled due to CBPeripheral/CBCentralManager initialization requirements
// To test this view, run it in the simulator through the normal navigation flow 

// MARK: - Chart with Slider View
struct ChartWithSliderView: View {
    @ObservedObject var connectionManager: BLEConnectionManager
    let chartType: ChartDisplayType
    let xAxisInterval: XAxisInterval
    let customMaxY: Double?
    let customMinY: Double?
    let refreshTrigger: Int
    var selectedDataPoint: SelectedDataPoint? = nil
    var onPointSelected: ((Int) -> Void)? = nil // Add callback parameter
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var sliderValue: Double = 100.0
    @State private var maxDataPoints: Double = 100.0
    @State private var horizontalOffset: Double = 0.0
    @State private var isInitialized: Bool = false
    @State private var previousUISliderValue: Double = 10.0 // Track UI slider position
    @State private var oldSliderValue: Double = 10.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart area - with comprehensive safety checks
            Group {
                if maxDataPoints >= 20 && sliderValue >= 10 && sliderValue <= maxDataPoints && horizontalOffset >= 0 && horizontalOffset <= (maxDataPoints - sliderValue) {
                    SwiftUIChartView(
                        connectionManager: connectionManager,
                        chartType: chartType,
                        xAxisInterval: xAxisInterval,
                        customMaxY: customMaxY,
                        customMinY: customMinY,
                        customMaxX: Binding(
                            get: { sliderValue },
                            set: { newValue in 
                                if let value = newValue {
                                    sliderValue = value
                                }
                            }
                        ),
                        customMinX: Binding(
                            get: { horizontalOffset },
                            set: { newValue in 
                                if let value = newValue {
                                    horizontalOffset = value
                                }
                            }
                        ),
                        refreshTrigger: refreshTrigger,
                        selectedDataPoint: selectedDataPoint,
                        sliderValue: $sliderValue,
                        horizontalOffset: $horizontalOffset,
                        maxDataPoints: Binding(
                            get: { maxDataPoints },
                            set: { newValue in maxDataPoints = newValue }
                        ),
                        onPointSelected: onPointSelected
                    )
                } else {
                    // Fallback chart without sliders if values are unsafe
                    SwiftUIChartView(
                        connectionManager: connectionManager,
                        chartType: chartType,
                        xAxisInterval: xAxisInterval,
                        customMaxY: customMaxY,
                        customMinY: customMinY,
                        customMaxX: .constant(nil), // No custom limits
                        customMinX: .constant(nil),
                        refreshTrigger: refreshTrigger,
                        selectedDataPoint: selectedDataPoint,
                        sliderValue: $sliderValue,
                        horizontalOffset: $horizontalOffset,
                        maxDataPoints: Binding(
                            get: { maxDataPoints },
                            set: { newValue in maxDataPoints = newValue }
                        ),
                        onPointSelected: onPointSelected
                    )
                }
            }
            .padding(.bottom, 5) // Add padding to ensure x-axis labels are visible
            .onAppear {
                updateMaxDataPoints()
            }
            .onChange(of: connectionManager.chartData) { _ in
                updateMaxDataPoints()
            }
            .onChange(of: refreshTrigger) { _ in
                updateMaxDataPoints()
            }
            
            // Subtle slider controls - minimalist design
            VStack(spacing: 6) {
                // Ultra-subtle divider
                Rectangle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 0.5)
                
                if connectionManager.chartDataAvailable && maxDataPoints >= 20 {
                    VStack(spacing: 8) {
                        // Scroll control - aligned with zoom control
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.and.right")
                                .font(.system(size: 10))
                                .foregroundColor(Color.gray.opacity(0.4))
                                .frame(width: 18)
                            
                            Slider(
                                value: $horizontalOffset,
                                in: 0...max(1, max(0, maxDataPoints - sliderValue)),
                                step: 1
                            )
                            .accentColor(Color.gray.opacity(0.3))
                            .frame(height: 16)
                            .scaleEffect(0.8) // Make thumb smaller
                        }
                        .padding(.horizontal, 20)
                        
                        // Zoom control - aligned with scroll control
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10))
                                .foregroundColor(Color.gray.opacity(0.4))
                                .frame(width: 18)
                            
                            Slider(
                                value: Binding(
                                    get: { 
                                        guard maxDataPoints >= 10 else { return 10 }
                                        let inverted = maxDataPoints - sliderValue + 10
                                        return max(10, min(maxDataPoints, inverted))
                                    },
                                    set: { newValue in
                                        previousUISliderValue = newValue
                                        guard maxDataPoints >= 10 && newValue >= 10 && newValue <= maxDataPoints else { return }
                                        let actualValue = maxDataPoints - newValue + 10
                                        let safeValue = max(10, min(maxDataPoints, actualValue))
                                        if safeValue >= 10 && safeValue <= maxDataPoints {
                                            sliderValue = safeValue
                                        }
                                    }
                                ),
                                in: 10...max(20, maxDataPoints),
                                step: 1
                            )
                            .accentColor(Color.gray.opacity(0.3))
                            .frame(height: 16)
                            .scaleEffect(0.8) // Make thumb smaller
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17).opacity(0.95) : Color.white.opacity(0.95))
            .opacity(connectionManager.chartDataAvailable ? 1.0 : 0.0)
            .onChange(of: sliderValue) { newValue in
                // CRITICAL: Comprehensive safety validation for all slider values
                guard maxDataPoints >= 20 else { 
                    print("MonitoringView - ERROR: maxDataPoints too small: \(maxDataPoints)")
                    return 
                }
                
                // Calculate the current UI slider position to determine direction
                let currentUISliderValue = maxDataPoints - newValue + 10
                let oldUISliderValue = previousUISliderValue
                
                // Ensure slider value is within valid bounds
                let safeSliderValue = max(10, min(maxDataPoints, newValue))
                if safeSliderValue != newValue {
                    sliderValue = safeSliderValue
                    print("MonitoringView - Corrected slider value from \(newValue) to \(safeSliderValue)")
                }
                
                // Calculate max valid offset with safety checks
                let maxValidOffset = max(0, maxDataPoints - safeSliderValue)
                
                // NEW: Standard center-fixed zoom adjustment
                let delta = oldSliderValue - safeSliderValue  // Positive when zooming in (smaller window)
                horizontalOffset += delta / 2
                
                // Clamp after adjustment
                horizontalOffset = max(0, min(horizontalOffset, maxValidOffset))
                
                // Update old values
                oldSliderValue = safeSliderValue
                previousUISliderValue = currentUISliderValue
                
                // FINAL VALIDATION: All values must be positive for stride calculations
                let finalMaxOffset = max(0, maxDataPoints - safeSliderValue)
                if finalMaxOffset < 0 {
                    print("MonitoringView - ERROR: Final offset calculation negative, resetting")
                    horizontalOffset = 0
                    sliderValue = maxDataPoints
                }
                
                print("MonitoringView - UI Direction: \(currentUISliderValue > oldUISliderValue ? "STRETCHING (zoom in)" : "COMPRESSING (zoom out)"), UISlider: \(oldUISliderValue) -> \(currentUISliderValue), offset: \(horizontalOffset)")
            }
        }
    }
    
    private func updateMaxDataPoints() {
        let dataCount = Double(connectionManager.chartData.count)
        if dataCount > 0 {
            maxDataPoints = max(20, dataCount) // Increased minimum to prevent edge cases
            
            // Initialize slider value on first data load
            if !isInitialized {
                // Show all data by default to ensure chart extends to current time
                sliderValue = maxDataPoints
                
                // Initialize UI slider position tracking
                previousUISliderValue = maxDataPoints - sliderValue + 10
                
                // Independent horizontal offset - start at beginning
                horizontalOffset = 0
                
                print("MonitoringView - Initialized INDEPENDENT sliders: range=\(sliderValue), offset=\(horizontalOffset), total=\(maxDataPoints), UISlider=\(previousUISliderValue)")
                isInitialized = true
            }
            
            // When new data arrives, extend the range slider to show all new data
            if sliderValue < maxDataPoints {
                print("MonitoringView - Extending range slider from \(sliderValue) to \(maxDataPoints) for new data")
                sliderValue = maxDataPoints
            }
            
            // CRITICAL: Comprehensive safety checks for slider ranges
            sliderValue = max(10, min(maxDataPoints, sliderValue))
            
            // Horizontal offset must respect the current range setting with safety
            let maxValidOffset = max(0, maxDataPoints - sliderValue)
            horizontalOffset = max(0, min(maxValidOffset, horizontalOffset))
            
            print("MonitoringView - Safe slider values: maxData=\(maxDataPoints), sliderValue=\(sliderValue), offset=\(horizontalOffset)")
        }
    }
}

// MARK: - Radon Levels Info View
struct RadonLevelsInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ZStack {
            // Semi-transparent black background for proper dimming
            Color.black.opacity(0.6)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            // Main content card - made smaller
            VStack(spacing: 16) {
                // Title
                Text("Radon Levels Chart")
                    .font(.custom("AeonikPro-Bold", size: 18))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                
                // Color-coded chart
                VStack(spacing: 12) {
                    // Color bar
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 16)
                    .cornerRadius(3)
                    
                    // Threshold markers
                    HStack {
                        VStack(spacing: 2) {
                            Image(systemName: "arrowtriangle.up.fill")
                                .font(.system(size: 7))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                            Text("0")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Image(systemName: "arrowtriangle.up.fill")
                                .font(.system(size: 7))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                            Text("2.7")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Image(systemName: "arrowtriangle.up.fill")
                                .font(.system(size: 7))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                            Text("4.0")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        }
                    }
                }
                
                // Legend - more compact
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text("No Action Required")
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text("Some Concern")
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        
                        Text("Action Required")
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        Spacer()
                    }
                }
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                // Confidence interval section - more compact
                VStack(spacing: 12) {
                    Text("Radon Level Confidence Interval")
                        .font(.custom("AeonikPro-Bold", size: 16))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    // Current reading display
                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("0.2")
                                .font(.custom("AeonikPro-Bold", size: 36))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text("pCi/ℓ")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                        }
                        
                        // Confidence range
                        Rectangle()
                            .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                            .frame(height: 3)
                            .cornerRadius(2)
                        
                        HStack {
                            Text("0.0~0.7")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Spacer()
                            
                            Text("pCi/ℓ")
                                .font(.custom("AeonikPro-Medium", size: 12))
                                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                        }
                    }
                    
                    // Description - more compact
                    Text("The average, lower, and upper levels of 95% confidence interval based on the last 1 hour measurement with 6 data points.")
                        .font(.custom("AeonikPro-Regular", size: 12))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.576, green: 0.576, blue: 0.576))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Close button - more compact
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.custom("AeonikPro-Medium", size: 16))
                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 32)
        }
        .presentationBackground(.clear)
    }
}

// MARK: - Custom Button Styles
struct PresetButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AeonikPro-Medium", size: 12))
            .foregroundColor(isSelected ? .white : Color(red: 0.376, green: 0.376, blue: 0.376))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
