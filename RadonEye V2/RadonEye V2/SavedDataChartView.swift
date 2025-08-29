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

// MARK: - Saved Data Summary View
struct SavedDataSummaryView: View {
    let logData: SavedLogData
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Statistics Cards
                VStack(spacing: 16) {
                    // Data Points and Duration
                    HStack(spacing: 16) {
                        StatisticSummaryCard(
                            title: "Data Points",
                            value: "\(logData.dataPointCount)",
                            unit: "readings",
                            icon: "chart.dots.scatter",
                            color: Color(red: 0.156, green: 0.459, blue: 0.737)
                        )
                        
                        StatisticSummaryCard(
                            title: "Duration",
                            value: logData.measurementDuration,
                            unit: "",
                            icon: "clock",
                            color: Color.green
                        )
                    }
                    
                    // Min, Max, Average
                    VStack(spacing: 12) {
                        StatisticSummaryCard(
                            title: "Maximum Value",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, logData.maxValue).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "arrow.up.circle.fill",
                            color: Color.red
                        )
                        
                        StatisticSummaryCard(
                            title: "Minimum Value", 
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, logData.minValue).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "arrow.down.circle.fill",
                            color: Color.blue
                        )
                        
                        StatisticSummaryCard(
                            title: "Average Value",
                            value: MyUtil.valueReturnString(logData.unit.contains("Bq") ? 1 : 0, logData.averageValue).trimmingCharacters(in: .whitespaces),
                            unit: logData.unit,
                            icon: "chart.bar.fill",
                            color: Color.orange
                        )
                    }
                }
                
                // Measurement Period Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Measurement Details")
                        .font(.custom("AeonikPro-Bold", size: 18))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        DetailRow(title: "Saved Date", value: logData.formattedSavedDate)
                        DetailRow(title: "Measurement Start", value: formatDate(logData.measurementStartDate))
                        DetailRow(title: "Measurement End", value: formatDate(logData.measurementEndDate))
                        DetailRow(title: "Total Duration", value: "\(logData.totalMeasurementMinutes) minutes")
                        DetailRow(title: "Device", value: logData.deviceName)
                        DetailRow(title: "Unit", value: logData.unit)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 20)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
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
                    // Chart area
                    ZStack {
                        SavedDataChartContainerView(
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

// MARK: - Saved Data Chart Container
struct SavedDataChartContainerView: View {
    let logData: SavedLogData
    var selectedDataPoint: SelectedDataPoint? = nil
    var onPointSelected: ((Int) -> Void)? = nil
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ZStack {
            Color(isDarkMode ? UIColor.systemBackground : UIColor.white)
            
            SavedDataSwiftUIChartView(
                logData: logData,
                selectedDataPoint: selectedDataPoint,
                onPointSelected: onPointSelected
            )
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

// MARK: - Helper Views
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
                    "Select Time",
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
