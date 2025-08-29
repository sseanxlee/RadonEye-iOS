//
//  SavedDataManager.swift
//  RadonEye V2
//
//  Data storage manager for saved log data
//

import Foundation
import SwiftUI

// MARK: - Data Models
struct SavedLogData: Codable, Identifiable {
    let id = UUID()
    let name: String
    let deviceName: String
    let savedDate: Date
    let measurementStartDate: Date
    let measurementEndDate: Date
    let totalMeasurementMinutes: UInt32
    let unit: String
    let radonValues: [Float]
    let maxValue: Float
    let minValue: Float
    let averageValue: Float
    let dataPointCount: Int
    
    var formattedSavedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: savedDate)
    }
    
    var formattedMeasurementPeriod: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        let startString = formatter.string(from: measurementStartDate)
        let endString = formatter.string(from: measurementEndDate)
        return "\(startString) - \(endString)"
    }
    
    var measurementDuration: String {
        let timeArray = MyUtil.measTimeConvertStringArray(totalMeasurementMinutes)
        var result = ""
        
        if !timeArray[0].isEmpty {
            result += "\(timeArray[0])d "
        }
        result += "\(timeArray[1])h \(timeArray[2])m"
        
        return result
    }
}

// MARK: - Saved Data Manager
class SavedDataManager: ObservableObject {
    static let shared = SavedDataManager()
    
    @Published var savedData: [SavedLogData] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedDataKey = "SavedRadonLogData"
    
    private init() {
        loadSavedData()
    }
    
    // MARK: - Save Data
    func saveLogData(
        name: String,
        deviceName: String,
        connectionManager: BLEConnectionManager
    ) -> Bool {
        guard connectionManager.chartDataAvailable,
              !connectionManager.chartData.isEmpty else {
            return false
        }
        
        // Calculate measurement dates
        let currentTime = Date()
        let measurementSeconds = TimeInterval(connectionManager.measurementTime * 60)
        let measurementStartDate = currentTime.addingTimeInterval(-measurementSeconds)
        
        // Apply the same unit conversion as the original chart for display values
        let convertedValues = connectionManager.chartData.map { rawValue in
            let convertedValue = MyUtil.radonValueReturn(MyStruct.v2Mode, rawValue, BLEData.Config.unit)
            return BLEData.Flag.V3_New && BLEData.Config.unit == 0 ? 
                MyUtil.newFwMinValue(inValue: convertedValue) : convertedValue
        }
        
        let logData = SavedLogData(
            name: name,
            deviceName: deviceName,
            savedDate: currentTime,
            measurementStartDate: measurementStartDate,
            measurementEndDate: currentTime,
            totalMeasurementMinutes: connectionManager.measurementTime,
            unit: connectionManager.unitString,
            radonValues: convertedValues, // Use converted values for consistent display
            maxValue: connectionManager.chartMaxValue,
            minValue: connectionManager.chartMinValue,
            averageValue: connectionManager.chartAverage,
            dataPointCount: connectionManager.chartDataCount
        )
        
        savedData.append(logData)
        persistSavedData()
        
        MyUtil.printProcess(inMsg: "SavedDataManager - Saved log data: \(name) with \(logData.dataPointCount) points")
        return true
    }
    
    // MARK: - Delete Data
    func deleteLogData(_ logData: SavedLogData) {
        if let index = savedData.firstIndex(where: { $0.id == logData.id }) {
            savedData.remove(at: index)
            persistSavedData()
            MyUtil.printProcess(inMsg: "SavedDataManager - Deleted log data: \(logData.name)")
        }
    }
    
    func deleteLogData(at offsets: IndexSet) {
        savedData.remove(atOffsets: offsets)
        persistSavedData()
    }
    
    // MARK: - Export Data
    func exportLogData(_ logData: SavedLogData) -> String {
        var csv = "Index,Date,Time,Timestamp,Radon Value,Unit\n"
        
        // Calculate measurement period
        let totalMinutes = logData.totalMeasurementMinutes
        let dataPointCount = logData.radonValues.count
        
        // Calculate minutes per data point (assuming evenly spaced measurements)
        let minutesPerDataPoint = dataPointCount > 0 ? Double(totalMinutes) / Double(dataPointCount) : 0
        
        for (index, value) in logData.radonValues.enumerated() {
            // Calculate timestamp for this data point
            let dataPointTime = logData.measurementStartDate.addingTimeInterval(Double(index) * minutesPerDataPoint * 60)
            
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
            
            // Values are already converted and ready for display (no additional conversion needed)
            let finalValue = value
            
            csv += "\(index),\(dateString),\(timeString),\(timestampString),\(finalValue),\(logData.unit)\n"
        }
        
        return csv
    }
    
    // MARK: - Persistence
    private func loadSavedData() {
        guard let data = userDefaults.data(forKey: savedDataKey) else {
            savedData = []
            return
        }
        
        do {
            savedData = try JSONDecoder().decode([SavedLogData].self, from: data)
            MyUtil.printProcess(inMsg: "SavedDataManager - Loaded \(savedData.count) saved log entries")
        } catch {
            MyUtil.printProcess(inMsg: "SavedDataManager - Failed to decode saved data: \(error)")
            savedData = []
        }
    }
    
    private func persistSavedData() {
        do {
            let data = try JSONEncoder().encode(savedData)
            userDefaults.set(data, forKey: savedDataKey)
            MyUtil.printProcess(inMsg: "SavedDataManager - Persisted \(savedData.count) saved log entries")
        } catch {
            MyUtil.printProcess(inMsg: "SavedDataManager - Failed to encode saved data: \(error)")
        }
    }
}
