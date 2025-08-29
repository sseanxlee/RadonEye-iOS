//
//  SavedDataChartView.swift
//  RadonEye V2
//
//  Chart viewer for saved log data - displays saved charts without redownloading
//

import SwiftUI
import DGCharts

// MARK: - Saved Data Chart View
struct SavedDataChartView: View {
    let logData: SavedLogData
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var selectedTab = 1 // Start on Data tab to show chart
    @State private var selectedDataPoint: SelectedDataPoint? = nil
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingExportAlert = false
    @State private var showingExportSuccess = false
    @State private var csvFileName = ""
    @State private var showingCSVNamingAlert = false
    
    var body: some View {
        NavigationView {
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
                    // Header with saved data info
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text(logData.name)
                                .font(.custom("AeonikPro-Bold", size: 24))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            Text(logData.deviceName)
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Saved: \(logData.formattedSavedDate)")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("Period: \(logData.formattedMeasurementPeriod)")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    
                    // Tab Picker
                    Picker("Section", selection: $selectedTab) {
                        Text("Summary").tag(0)
                        Text("Chart").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        SavedDataSummaryView(logData: logData)
                    } else {
                        SavedDataChartSectionView(
                            logData: logData,
                            selectedDataPoint: $selectedDataPoint,
                            selectedDate: $selectedDate,
                            showingDatePicker: $showingDatePicker,
                            csvFileName: $csvFileName,
                            showingCSVNamingAlert: $showingCSVNamingAlert,
                            showingExportSuccess: $showingExportSuccess
                        )
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { 
                    dismiss() 
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            // Initialize selected date to the end of measurement period
            selectedDate = logData.measurementEndDate
        }
        .alert("Export CSV", isPresented: $showingCSVNamingAlert) {
            TextField("File Name", text: $csvFileName)
            Button("Export") {
                exportSavedData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for the CSV file")
        }
        .alert("Export Complete", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            Text("Data has been exported successfully")
        }
    }
    
    private func exportSavedData() {
        let csvData = SavedDataManager.shared.exportLogData(logData)
        
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let customFileName = csvFileName.trimmingCharacters(in: .whitespacesAndNewlines)
            let fileName = customFileName.isEmpty ? 
                "\(logData.name)_\(DateFormatter.dateFormatted(logData.savedDate)).csv" :
                "\(customFileName).csv"
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            do {
                try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
                csvFileName = "" // Reset for next use
                showingExportSuccess = true
                MyUtil.printProcess(inMsg: "SavedDataChartView - Exported saved data to: \(fileURL.path)")
            } catch {
                MyUtil.printProcess(inMsg: "SavedDataChartView - Export error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Saved Data Summary View (Professional Uniform Layout)
struct SavedDataSummaryView: View {
    let logData: SavedLogData
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Calculate additional statistics
    private var standardDeviation: Float {
        guard logData.dataPointCount > 1 else { return 0 }
        let mean = logData.averageValue
        let variance = logData.radonValues.reduce(0) { sum, value in
            sum + pow(value - mean, 2)
        } / Float(logData.dataPointCount - 1)
        return sqrt(variance)
    }
    
    private var median: Float {
        let sortedValues = logData.radonValues.sorted()
        let count = sortedValues.count
        if count % 2 == 0 {
            return (sortedValues[count/2 - 1] + sortedValues[count/2]) / 2
        } else {
            return sortedValues[count/2]
        }
    }
    
    private var variabilityRating: String {
        let cv = standardDeviation / logData.averageValue // Coefficient of variation
        if cv < 0.2 { return "Low" }
        else if cv < 0.5 { return "Moderate" }
        else { return "High" }
    }
    
    private var dataQualityScore: Int {
        // Score based on measurement duration and data points
        let durationScore = min(50, Int(logData.totalMeasurementMinutes) / 60) // Up to 50 points for hours
        let densityScore = min(50, logData.dataPointCount / 10) // Up to 50 points for data density
        return durationScore + densityScore
    }
    
    private var samplingInterval: String {
        guard logData.dataPointCount > 1 else { return "N/A" }
        let intervalMinutes = Double(logData.totalMeasurementMinutes) / Double(logData.dataPointCount)
        if intervalMinutes < 1 {
            return "\(Int(intervalMinutes * 60))s"
        } else if intervalMinutes < 60 {
            return "\(Int(intervalMinutes))m"
        } else {
            return String(format: "%.1fh", intervalMinutes / 60)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Metrics Grid - 2x2 uniform layout
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        UniformMetricCard(
                            title: "Average",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, logData.averageValue).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "chart.bar.fill",
                            color: Color(red: 0.156, green: 0.459, blue: 0.737),
                            isPrimary: true
                        )
                        
                        UniformMetricCard(
                            title: "Maximum",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, logData.maxValue).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "arrow.up.circle.fill",
                            color: Color.red
                        )
                    }
                    
                    HStack(spacing: 12) {
                        UniformMetricCard(
                            title: "Minimum",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, logData.minValue).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "arrow.down.circle.fill",
                            color: Color.blue
                        )
                        
                        UniformMetricCard(
                            title: "Median",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, median).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "chart.line.uptrend.xyaxis",
                            color: Color.purple
                        )
                    }
                }
                
                // Statistical Analysis Grid - 2x2 uniform layout
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        UniformMetricCard(
                            title: "Std Deviation",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, standardDeviation).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "waveform.path",
                            color: Color.orange
                        )
                        
                        UniformMetricCard(
                            title: "Variability",
                            value: variabilityRating,
                            unit: "rating",
                            icon: "chart.line.flattrend.xyaxis",
                            color: variabilityRating == "Low" ? Color.green : variabilityRating == "Moderate" ? Color.orange : Color.red
                        )
                    }
                    
                    HStack(spacing: 12) {
                        UniformMetricCard(
                            title: "Data Points",
                            value: "\(logData.dataPointCount)",
                            unit: "readings",
                            icon: "chart.dots.scatter",
                            color: Color.green
                        )
                        
                        UniformMetricCard(
                            title: "Duration",
                            value: logData.measurementDuration,
                            unit: "",
                            icon: "clock.fill",
                            color: Color.indigo
                        )
                    }
                }
                
                // Data Quality and Sampling Grid - 2x1 uniform layout
                HStack(spacing: 12) {
                    UniformMetricCard(
                        title: "Quality Score",
                        value: "\(dataQualityScore)",
                        unit: "/100",
                        icon: "checkmark.seal.fill",
                        color: dataQualityScore >= 80 ? Color.green : dataQualityScore >= 60 ? Color.orange : Color.red
                    )
                    
                    UniformMetricCard(
                        title: "Sample Rate",
                        value: samplingInterval,
                        unit: "avg",
                        icon: "timer",
                        color: Color.teal
                    )
                }
                
                // Measurement Information Section
                VStack(spacing: 0) {
                    // Section Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Measurement Details")
                                .font(.custom("AeonikPro-Bold", size: 20))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text("Session information and metadata")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(red: 0.576, green: 0.576, blue: 0.576))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Details Grid
                    VStack(spacing: 0) {
                        EnhancedDetailRow(
                            title: "Saved",
                            value: logData.formattedSavedDate,
                            icon: "square.and.arrow.down.fill",
                            isFirst: true
                        )
                        
                        EnhancedDetailRow(
                            title: "Started",
                            value: formatDate(logData.measurementStartDate),
                            icon: "play.fill"
                        )
                        
                        EnhancedDetailRow(
                            title: "Ended",
                            value: formatDate(logData.measurementEndDate),
                            icon: "stop.fill"
                        )
                        
                        EnhancedDetailRow(
                            title: "Device",
                            value: logData.deviceName,
                            icon: "sensor.fill"
                        )
                        
                        EnhancedDetailRow(
                            title: "Units",
                            value: logData.unit,
                            icon: "ruler.fill",
                            isLast: true
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Saved Data Chart Section View
struct SavedDataChartSectionView: View {
    let logData: SavedLogData
    @Binding var selectedDataPoint: SelectedDataPoint?
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    @Binding var csvFileName: String
    @Binding var showingCSVNamingAlert: Bool
    @Binding var showingExportSuccess: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Chart area - using the same structure as MonitoringView
                    ZStack {
                        SavedDataChartWithSliderView(
                            logData: logData,
                            selectedDataPoint: selectedDataPoint,
                            onPointSelected: { index in
                                updateSelectedDateFromChartIndex(index)
                            }
                        )
                        .frame(height: 520)
                    }
                    
                    // Date/Time Selector Section
                    SavedDataTimeSelectionView(
                        logData: logData,
                        selectedDate: $selectedDate,
                        showingDatePicker: $showingDatePicker,
                        selectedDataPoint: $selectedDataPoint
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Export button
                    VStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 12) {
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
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        }
    }
    
    private func updateSelectedDateFromChartIndex(_ index: Int) {
        guard index >= 0,
              index < logData.radonValues.count,
              logData.totalMeasurementMinutes > 0 else { 
            return 
        }
        
        // Calculate the time for this data point
        let totalMinutes = logData.totalMeasurementMinutes
        let dataPointCount = logData.radonValues.count
        let minutesPerDataPoint = Double(totalMinutes) / Double(dataPointCount)
        let timeOffsetMinutes = Double(index) * minutesPerDataPoint
        let pointTime = logData.measurementStartDate.addingTimeInterval(timeOffsetMinutes * 60)
        
        // Get the value (no conversion needed since it's already saved in display format)
        let value = logData.radonValues[index]
        
        // Format the time string
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, h:mm a"
        let timeString = timeFormatter.string(from: pointTime)
        
        // Update both selected date and data point
        DispatchQueue.main.async {
            self.selectedDate = pointTime
            self.selectedDataPoint = SelectedDataPoint(index: index, value: value, time: timeString)
        }
    }
}

// MARK: - Saved Data Chart With Slider View (similar to ChartWithSliderView in MonitoringView)
struct SavedDataChartWithSliderView: View {
    let logData: SavedLogData
    var selectedDataPoint: SelectedDataPoint? = nil
    var onPointSelected: ((Int) -> Void)? = nil
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var sliderValue: Double = 100.0
    @State private var maxDataPoints: Double = 100.0
    @State private var horizontalOffset: Double = 0.0
    @State private var isInitialized: Bool = false
    @State private var previousUISliderValue: Double = 10.0
    @State private var oldSliderValue: Double = 10.0
    @State private var showChartSettings = false
    @State private var selectedChartType: ChartDisplayType = .smooth
    @State private var selectedXAxisInterval: XAxisInterval = .all
    @State private var customMaxY: Double = 4.0
    @State private var customMinY: Double = -1.0
    @State private var useCustomYAxis: Bool = false
    @State private var useCustomXAxis: Bool = false
    @State private var chartRefreshTrigger: Int = 0
    @State private var showGestureHint: Bool = false
    @State private var gestureHintTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart area with settings button overlay
            ZStack {
                // Main chart area - load instantly since data is already available
                Group {
                    if maxDataPoints >= 20 && sliderValue >= 10 && sliderValue <= maxDataPoints && horizontalOffset >= 0 && horizontalOffset <= (maxDataPoints - sliderValue) {
                        SavedDataSwiftUIChartView(
                            logData: logData,
                            chartType: selectedChartType,
                            xAxisInterval: selectedXAxisInterval,
                            customMaxY: useCustomYAxis ? customMaxY : nil,
                            customMinY: useCustomYAxis ? customMinY : nil,
                            customMaxX: sliderValue,
                            customMinX: horizontalOffset,
                            refreshTrigger: chartRefreshTrigger,
                            selectedDataPoint: selectedDataPoint,
                            sliderValue: $sliderValue,
                            horizontalOffset: $horizontalOffset,
                            maxDataPoints: $maxDataPoints,
                            onPointSelected: onPointSelected
                        )
                    } else {
                        // Fallback chart without sliders if values are unsafe
                        SavedDataSwiftUIChartView(
                            logData: logData,
                            chartType: selectedChartType,
                            xAxisInterval: selectedXAxisInterval,
                            customMaxY: useCustomYAxis ? customMaxY : nil,
                            customMinY: useCustomYAxis ? customMinY : nil,
                            customMaxX: nil,
                            customMinX: nil,
                            refreshTrigger: chartRefreshTrigger,
                            selectedDataPoint: selectedDataPoint,
                            sliderValue: $sliderValue,
                            horizontalOffset: $horizontalOffset,
                            maxDataPoints: $maxDataPoints,
                            onPointSelected: onPointSelected
                        )
                    }
                }
                .padding(.bottom, 5)
                .onAppear {
                    updateMaxDataPoints()
                    showGestureHintWithDelay()
                }
                
                // Chart Settings Button - Top Right Corner (same as MonitoringView)
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
                
                // Gesture hint overlay (same as MonitoringView)
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
            
            // Slider controls (same as MonitoringView but simplified for saved data)
            VStack(spacing: 6) {
                Rectangle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 0.5)
                
                if maxDataPoints >= 20 {
                    VStack(spacing: 8) {
                        // Scroll control
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
                            .scaleEffect(0.8)
                        }
                        .padding(.horizontal, 20)
                        
                        // Zoom control
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
                            .scaleEffect(0.8)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17).opacity(0.95) : Color.white.opacity(0.95))
            .onChange(of: sliderValue) { newValue in
                // Same slider logic as MonitoringView
                guard maxDataPoints >= 20 else { return }
                
                let currentUISliderValue = maxDataPoints - newValue + 10
                let oldUISliderValue = previousUISliderValue
                
                let safeSliderValue = max(10, min(maxDataPoints, newValue))
                if safeSliderValue != newValue {
                    sliderValue = safeSliderValue
                }
                
                let maxValidOffset = max(0, maxDataPoints - safeSliderValue)
                
                let delta = oldSliderValue - safeSliderValue
                horizontalOffset += delta / 2
                
                horizontalOffset = max(0, min(horizontalOffset, maxValidOffset))
                
                oldSliderValue = safeSliderValue
                previousUISliderValue = currentUISliderValue
                
                let finalMaxOffset = max(0, maxDataPoints - safeSliderValue)
                if finalMaxOffset < 0 {
                    horizontalOffset = 0
                    sliderValue = maxDataPoints
                }
            }
        }
        .sheet(isPresented: $showChartSettings) {
            SavedDataChartSettingsView(
                selectedChartType: $selectedChartType,
                selectedXAxisInterval: $selectedXAxisInterval,
                customMaxY: $customMaxY,
                customMinY: $customMinY,
                useCustomYAxis: $useCustomYAxis,
                useCustomXAxis: $useCustomXAxis,
                onSettingsChange: {
                    chartRefreshTrigger += 1
                }
            )
        }
        .onDisappear {
            gestureHintTimer?.invalidate()
        }
    }
    
    private func updateMaxDataPoints() {
        let dataCount = Double(logData.radonValues.count)
        if dataCount > 0 {
            maxDataPoints = max(20, dataCount)
            
            if !isInitialized {
                sliderValue = maxDataPoints
                previousUISliderValue = maxDataPoints - sliderValue + 10
                horizontalOffset = 0
                isInitialized = true
            }
            
            if sliderValue < maxDataPoints {
                sliderValue = maxDataPoints
            }
            
            sliderValue = max(10, min(maxDataPoints, sliderValue))
            let maxValidOffset = max(0, maxDataPoints - sliderValue)
            horizontalOffset = max(0, min(maxValidOffset, horizontalOffset))
        }
    }
    
    private func showGestureHintWithDelay() {
        gestureHintTimer?.invalidate()
        
        gestureHintTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showGestureHint = true
            }
            
            gestureHintTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGestureHint = false
                }
            }
        }
    }
}

// MARK: - Saved Data Time Selection View
struct SavedDataTimeSelectionView: View {
    let logData: SavedLogData
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    @Binding var selectedDataPoint: SelectedDataPoint?
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Calculate which data point corresponds to the selected date
    private var correspondingDataPoint: SelectedDataPoint? {
        guard !logData.radonValues.isEmpty,
              logData.totalMeasurementMinutes > 0 else { return nil }
        
        let totalMinutes = logData.totalMeasurementMinutes
        let dataPointCount = logData.radonValues.count
        
        // Calculate minutes per data point
        let minutesPerDataPoint = Double(totalMinutes) / Double(dataPointCount)
        
        // Calculate time offset from start
        let timeOffsetSeconds = selectedDate.timeIntervalSince(logData.measurementStartDate)
        let timeOffsetMinutes = timeOffsetSeconds / 60.0
        
        // Clamp to valid range
        let clampedOffsetMinutes = max(0, min(timeOffsetMinutes, Double(totalMinutes)))
        
        // Calculate data point index
        let index = Int(clampedOffsetMinutes / minutesPerDataPoint)
        let clampedIndex = max(0, min(index, dataPointCount - 1))
        
        // Get the value (already in display format)
        let value = logData.radonValues[clampedIndex]
        
        // Format the exact time for this data point
        let exactDataPointTime = logData.measurementStartDate.addingTimeInterval(Double(clampedIndex) * minutesPerDataPoint * 60)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, h:mm a"
        let timeString = timeFormatter.string(from: exactDataPointTime)
        
        return SelectedDataPoint(index: clampedIndex, value: value, time: timeString)
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
            
            // Result display
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
                        Text(MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, dataPoint.value))
                            .font(.custom("AeonikPro-Bold", size: 24))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.156, green: 0.459, blue: 0.737))
                        
                        Text(logData.unit)
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
                // Empty state
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
            SavedDataDatePickerView(
                selectedDate: $selectedDate,
                startDate: logData.measurementStartDate,
                endDate: logData.measurementEndDate,
                onDismiss: {
                    showingDatePicker = false
                    selectedDataPoint = correspondingDataPoint
                }
            )
        }
        .onChange(of: selectedDate) { _ in
            selectedDataPoint = correspondingDataPoint
        }
        .onAppear {
            selectedDate = logData.measurementEndDate
            selectedDataPoint = correspondingDataPoint
        }
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Enhanced Professional Summary Components

// Uniform Metric Card - Consistent size and professional formatting
struct UniformMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var isPrimary: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with icon and title
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                Text(title)
                    .font(.custom("AeonikPro-Medium", size: 14))
                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(red: 0.376, green: 0.376, blue: 0.376))
                    .lineLimit(1)
            }
            
            // Value section
            VStack(spacing: 4) {
                Text(value)
                    .font(.custom("AeonikPro-Bold", size: isPrimary ? 24 : 20))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.custom("AeonikPro-Regular", size: 12))
                        .foregroundColor(isDarkMode ? .white.opacity(0.6) : Color(red: 0.576, green: 0.576, blue: 0.576))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100) // Fixed height for consistency
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isPrimary ? color.opacity(0.3) : Color.clear, lineWidth: isPrimary ? 1.5 : 0)
                )
                .shadow(color: .black.opacity(isPrimary ? 0.1 : 0.06), radius: isPrimary ? 12 : 8, x: 0, y: isPrimary ? 6 : 4)
        )
    }
}

// Primary Metric Card - Featured metric with emphasis (Legacy - keeping for reference)
// Legacy Primary Metric Card (replaced by UniformMetricCard)
// Keeping for reference but not used in current layout

// Legacy Compact Metric Card (replaced by UniformMetricCard)

// Legacy Data Overview Card (replaced by UniformMetricCard)

// Enhanced Detail Row - Professional information display
struct EnhancedDetailRow: View {
    let title: String
    let value: String
    let icon: String
    var isFirst: Bool = false
    var isLast: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                .frame(width: 24, height: 24)
            
            // Content
            HStack {
                Text(title)
                    .font(.custom("AeonikPro-Medium", size: 15))
                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : Color(red: 0.376, green: 0.376, blue: 0.376))
                
                Spacer()
                
                Text(value)
                    .font(.custom("AeonikPro-Semibold", size: 15))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.clear)
        )
        .overlay(
            // Separator line
            Rectangle()
                .fill(isDarkMode ? Color.white.opacity(0.1) : Color(red: 0.9, green: 0.9, blue: 0.9))
                .frame(height: isLast ? 0 : 0.5)
                .padding(.leading, 64), // Align with text
            alignment: .bottom
        )
    }
}

// Legacy Statistical Summary Card (replaced by uniform grid layout)

// MARK: - Legacy Helper Views (keeping for compatibility)
struct StatisticSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
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
                    Text(value)
                        .font(.custom("AeonikPro-Bold", size: 18))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.custom("AeonikPro-Medium", size: 12))
                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
                    }
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

struct DetailRow: View {
    let title: String
    let value: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("AeonikPro-Regular", size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(red: 0.376, green: 0.376, blue: 0.376))
            
            Spacer()
            
            Text(value)
                .font(.custom("AeonikPro-Medium", size: 14))
                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
        }
    }
}

// MARK: - Saved Data Date Picker View
struct SavedDataDatePickerView: View {
    @Binding var selectedDate: Date
    let startDate: Date
    let endDate: Date
    let onDismiss: () -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: startDate...endDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            .navigationTitle("")
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

// MARK: - Saved Data Chart Settings View (simplified version of MonitoringView's settings)
struct SavedDataChartSettingsView: View {
    @Binding var selectedChartType: ChartDisplayType
    @Binding var selectedXAxisInterval: XAxisInterval
    @Binding var customMaxY: Double
    @Binding var customMinY: Double
    @Binding var useCustomYAxis: Bool
    @Binding var useCustomXAxis: Bool
    let onSettingsChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart Type Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chart Display")
                            .font(.custom("AeonikPro-Bold", size: 16))
                            .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach([ChartDisplayType.smooth, .linear, .stepped, .bar], id: \.self) { chartType in
                                Button(action: {
                                    selectedChartType = chartType
                                    onSettingsChange()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconForChartType(chartType))
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(selectedChartType == chartType ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                        
                                        Text(displayNameForChartType(chartType))
                                            .font(.custom("AeonikPro-Medium", size: 12))
                                            .foregroundColor(selectedChartType == chartType ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.173, green: 0.173, blue: 0.173))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 70)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedChartType == chartType ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) : Color.gray.opacity(0.05))
                                            .stroke(selectedChartType == chartType ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Data Intervals Section
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data Intervals")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text("Reduce point density while preserving full timeline")
                                .font(.custom("AeonikPro-Regular", size: 12))
                                .foregroundColor(Color(red: 0.576, green: 0.576, blue: 0.576))
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach([XAxisInterval.all, .every5, .every10, .every30, .hourly, .daily], id: \.self) { interval in
                                Button(action: {
                                    selectedXAxisInterval = interval
                                    onSettingsChange()
                                }) {
                                    VStack(spacing: 4) {
                                        Text(shortNameForInterval(interval))
                                            .font(.custom("AeonikPro-Medium", size: 12))
                                            .foregroundColor(selectedXAxisInterval == interval ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color(red: 0.173, green: 0.173, blue: 0.173))
                                        
                                        Text(subtitleForInterval(interval))
                                            .font(.custom("AeonikPro-Regular", size: 10))
                                            .foregroundColor(selectedXAxisInterval == interval ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.8) : Color(red: 0.576, green: 0.576, blue: 0.576))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedXAxisInterval == interval ? Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.1) : Color.gray.opacity(0.05))
                                            .stroke(selectedXAxisInterval == interval ? Color(red: 0.156, green: 0.459, blue: 0.737) : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Y-Axis Range Controls
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Y-Axis Range")
                                .font(.custom("AeonikPro-Bold", size: 16))
                                .foregroundColor(isDarkMode ? .white : Color(red: 0.173, green: 0.173, blue: 0.173))
                            
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
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
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
        }
    }
    
    private func displayNameForChartType(_ chartType: ChartDisplayType) -> String {
        switch chartType {
        case .smooth:
            return "Smooth"
        case .linear:
            return "Linear"
        case .stepped:
            return "Stepped"
        case .bar:
            return "Bar"
        }
    }
    
    private func iconForChartType(_ chartType: ChartDisplayType) -> String {
        switch chartType {
        case .smooth:
            return "chart.line.uptrend.xyaxis"
        case .linear:
            return "chart.xyaxis.line"
        case .stepped:
            return "stairs"
        case .bar:
            return "chart.bar"
        }
    }
    
    private func shortNameForInterval(_ interval: XAxisInterval) -> String {
        switch interval {
        case .all:
            return "All"
        case .every5:
            return "Every 5th"
        case .every10:
            return "Every 10th"
        case .every30:
            return "Every 30th"
        case .hourly:
            return "Hourly"
        case .daily:
            return "Daily"
        }
    }
    
    private func subtitleForInterval(_ interval: XAxisInterval) -> String {
        switch interval {
        case .all:
            return "Every point"
        case .every5:
            return "1/5 density"
        case .every10:
            return "1/10 density"
        case .every30:
            return "1/30 density"
        case .hourly:
            return "Avg/hour"
        case .daily:
            return "Avg/day"
        }
    }
}
