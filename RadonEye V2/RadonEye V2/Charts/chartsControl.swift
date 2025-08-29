//
//  chartsControl.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/06.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import DGCharts
import SwiftUI
import Charts
import ObjectiveC

// MARK: - Chart Configuration Enums
enum ChartDisplayType {
    case smooth      // Smooth line with curves
    case linear      // Simple linear line
    case stepped     // Stepped line chart
    case bar         // Bar chart representation
}

enum XAxisInterval {
    case all         // Show all data points
    case every5      // Every 5th point
    case every10     // Every 10th point
    case every30     // Every 30th point
    case hourly      // Group by hour (if time-based)
    case daily       // Group by day (if time-based)
    
    var factor: Int {
        switch self {
        case .all: return 1
        case .every5: return 5
        case .every10: return 10
        case .every30: return 30
        case .hourly: return 60    // Assuming 1-minute intervals
        case .daily: return 1440   // 24 hours * 60 minutes
        }
    }
    
    var displayName: String {
        switch self {
        case .all: return "All Points"
        case .every5: return "Every 5th"
        case .every10: return "Every 10th"
        case .every30: return "Every 30th"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        }
    }
}

class chartsControl: NSObject, ChartViewDelegate{
    
    // MARK: - Shared Instance for Delegate
    static let shared = chartsControl()
    
    static func chartInit(_ inChart: LineChartView, _ inUnit: Int, _ inMaxVlue: Double, inAlarmValue: Double){
        var maxValue = inMaxVlue
        inChart.chartDescription.enabled = false
        
        // PERFORMANCE OPTIMIZATION: Check if we have a large dataset
        let dataCount = inChart.data?.entryCount ?? 0
        let isLargeDataset = dataCount > 500
        
        // HORIZONTAL PANNING: Enable dragging for panning, disable scaling
        inChart.scaleXEnabled = false  // Disable X scaling/stretching
        inChart.scaleYEnabled = false  // Disable vertical scaling completely
        inChart.pinchZoomEnabled = false  // Disable pinch zoom
        inChart.doubleTapToZoomEnabled = false  // Disable double tap zoom
        
        // ENABLE HORIZONTAL PANNING: Allow dragging to shift view left/right
        inChart.dragEnabled = true
        inChart.dragDecelerationEnabled = true
        inChart.dragDecelerationFrictionCoef = 0.9  // Smooth deceleration
        
        // CRITICAL: Always enable highlighting for value selection (needed for date/time selector)
        inChart.highlightPerTapEnabled = true
        inChart.highlightPerDragEnabled = true
        
        // Set delegate to handle chart events
        inChart.delegate = chartsControl.shared
        
        // Set reasonable zoom limits (this will be overridden by our custom behavior)
        inChart.setScaleMinima(1.0, scaleY: 1.0)
        inChart.setScaleEnabled(false)  // Disable all built-in scaling
        
        // Always show from origin (0,0)
        inChart.xAxis.axisMinimum = 0
        
        // Optimize performance for large datasets but preserve highlighting
        if isLargeDataset {
            // Disable expensive rendering features for large datasets but keep highlighting
            inChart.setViewPortOffsets(left: 20, top: 20, right: 20, bottom: 20)
            
            // Keep highlighting enabled even for very large datasets since it's needed for date/time selector
            // (Previous optimization that disabled highlighting is removed)
        }
        
        // Modern grid styling - optimize for large datasets
        if isLargeDataset {
            // Simpler grid for better performance
            inChart.xAxis.gridLineDashLengths = nil
            inChart.xAxis.gridLineWidth = 0.5
        } else {
            // Detailed grid for smaller datasets
            inChart.xAxis.gridLineDashLengths = [4, 4]
            inChart.xAxis.gridLineWidth = 0.8
        }
        inChart.xAxis.gridLineDashPhase = 0
        inChart.xAxis.gridColor = UIColor.systemGray4
        
        inChart.rightAxis.enabled = false
        inChart.backgroundColor = UIColor.systemBackground
        
        // INCREASED MARGINS: More space for x-axis labels (especially bottom)
        inChart.extraLeftOffset = 20
        inChart.extraRightOffset = 20
        inChart.extraTopOffset = 20
        inChart.extraBottomOffset = 40  // Increased from 10 to 40 for label space
        
        var flagLimitLine = Bool(false)
        var limitValue = Double(inAlarmValue)
        
        if inUnit == 0{
            if MyStruct.v2Mode{
                limitValue = inAlarmValue / 37
            }

            if maxValue >= limitValue{
                flagLimitLine = true
            }
            maxValue = ceil(maxValue)
        }
        else{
            if !MyStruct.v2Mode{
                limitValue = inAlarmValue * 37
            }
           
            if maxValue >= limitValue{
                flagLimitLine = true
            }
            maxValue = maxValue * 1.1
        }
        
        // Modern limit line styling
        let ll1 = ChartLimitLine(limit: limitValue, label: "Alarm Level")
        ll1.lineWidth = 2
        ll1.lineDashLengths = [8, 4]
        ll1.labelPosition = .rightTop
        ll1.valueFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        ll1.valueTextColor = UIColor.systemRed
        ll1.lineColor = UIColor.systemRed.withAlphaComponent(0.7)
    
        // Modern X-axis styling with more space
        let xAxis = inChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        xAxis.labelTextColor = UIColor.label
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineColor = UIColor.systemGray3
        xAxis.axisLineWidth = 1.2
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = false
        
        // Dynamic X-axis labeling
        let xAxisDataCount = inChart.data?.entryCount ?? 0
        if xAxisDataCount > 0 {
            let optimalLabelCount = min(8, max(4, xAxisDataCount / 10))
            xAxis.labelCount = optimalLabelCount
            xAxis.granularityEnabled = true
            xAxis.granularity = max(1.0, Double(xAxisDataCount) / Double(optimalLabelCount))
        }
        
        // Modern Y-axis styling
        let leftAxis = inChart.leftAxis
        leftAxis.removeAllLimitLines()
        if flagLimitLine{
            leftAxis.addLimitLine(ll1)
        }
        leftAxis.labelFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        leftAxis.labelTextColor = UIColor.label
        leftAxis.axisMaximum = maxValue
        // Remove hardcoded minimum - allow negative values
        // leftAxis.axisMinimum = 0.0  // This will be set in chartDraw based on customMinY
        
        // Optimize Y-axis grid for large datasets
        if isLargeDataset {
            // Simpler Y-axis grid for better performance
            leftAxis.gridLineDashLengths = nil
            leftAxis.gridLineWidth = 0.5
        } else {
            // Detailed Y-axis grid for smaller datasets
            leftAxis.gridLineDashLengths = [4, 4]
            leftAxis.gridLineWidth = 0.8
        }
        leftAxis.gridColor = UIColor.systemGray4
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.axisLineColor = UIColor.systemGray3
        leftAxis.axisLineWidth = 1.2
        
        // Dynamic Y-axis labeling with proper intervals
        leftAxis.granularityEnabled = true
        let yRange = maxValue - 0.0 // This will be updated in chartDraw
        let optimalYSteps = 6
        let stepSize = yRange / Double(optimalYSteps)
        
        // Round step size to nice numbers
        let magnitude = pow(10.0, floor(log10(stepSize)))
        let normalizedStep = stepSize / magnitude
        let niceStep: Double
        
        if normalizedStep <= 1.0 {
            niceStep = 1.0
        } else if normalizedStep <= 2.0 {
            niceStep = 2.0
        } else if normalizedStep <= 5.0 {
            niceStep = 5.0
        } else {
            niceStep = 10.0
        }
        
        leftAxis.granularity = niceStep * magnitude
        leftAxis.labelCount = Int(ceil(maxValue / leftAxis.granularity)) + 1
        
        // ENHANCED MARKER: Always enable marker for value selection with time display
        let marker = BalloonMarker(
            unit: inUnit, 
            color: UIColor.systemBackground, 
            font: UIFont.systemFont(ofSize: 13, weight: .medium), 
            textColor: UIColor.label, 
            insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )
        
        marker.chartView = inChart
        marker.minimumSize = CGSize(width: 120, height: 50) // Larger size to accommodate time info
        inChart.marker = marker
        
        // ALWAYS show marker - critical for date/time selection functionality
        
        inChart.legend.form = .none
        
        // Remove automatic animation to prevent constant refreshing
    }
    
    // MARK: - Custom Horizontal Scaling Methods
    static func setHorizontalRange(_ inChart: LineChartView, maxX: Double, totalDataPoints: Int) {
        let dataCount = Double(totalDataPoints)
        let clampedMaxX = min(dataCount, max(10.0, maxX))
        
        // Always keep minimum at 0
        inChart.xAxis.axisMinimum = 0
        inChart.xAxis.axisMaximum = clampedMaxX
        
        // Update X-axis labeling
        let visibleRange = clampedMaxX
        let optimalLabelCount = min(8, max(4, Int(visibleRange / 10)))
        inChart.xAxis.labelCount = optimalLabelCount
        inChart.xAxis.granularity = max(1.0, visibleRange / Double(optimalLabelCount))
        
        // UPDATE ADAPTIVE TIME FORMATTER when slider changes range
        if let formatter = inChart.xAxis.valueFormatter as? AdaptiveTimeAxisValueFormatter {
            formatter.updateVisibleRange(visibleRange, labelCount: optimalLabelCount)
            
            // Update label rotation based on new density
            let chartWidth = inChart.frame.width
            let labelDensity = Double(optimalLabelCount) / visibleRange
            
            if labelDensity > 0.15 || chartWidth < 300 {
                inChart.xAxis.labelRotationAngle = -45
            } else {
                inChart.xAxis.labelRotationAngle = 0
            }
        }
        
        // Refresh the chart
        inChart.notifyDataSetChanged()
        
        print("Charts - Horizontal range set: maxX = \(clampedMaxX), dataPoints = \(totalDataPoints)")
    }
    
    static func chartDraw(_ inChart: LineChartView, _ inRadonValue: [Float], _ inValueUnit: Int, _ inSelectUnit: Int, _ inAlarmValue: Double, _ newFlag: Bool, chartType: ChartDisplayType = .smooth, xAxisInterval: XAxisInterval = .all, customMaxY: Double? = nil, customMinY: Double? = nil, customMaxX: Double? = nil, customMinX: Double? = nil, isDarkMode: Bool = false) {
        
        let dataNo = inRadonValue.count
        
        // SAFETY CHECK: Prevent crashes with invalid data
        guard dataNo > 0 else {
            print("Charts - ERROR: No data to draw chart")
            return
        }
        
        var chartRadonValue = [Double]()
    
        if inValueUnit == 0{
            chartRadonValue = inRadonValue.map { Double($0) }
            
            if inSelectUnit == 1{
                chartRadonValue = inRadonValue.map { Double($0 * 37) }
            }
        }
        else{
            chartRadonValue = inRadonValue.map { Double($0) }
            
            if inSelectUnit == 0{
                chartRadonValue = inRadonValue.map { Double($0 / 37) }
                
                //V1.5.0 - V3는 Bq 단위로 로그 데이터 저장됨
                if newFlag{
                    chartRadonValue = chartRadonValue.map { Double(MyUtil.newFwMinValue(inValue: Float($0))) }
                }
            }
        }
        
        let maxValue = chartRadonValue.max()
        
        print("Charts - Input data: \(dataNo) points, max value: \(String(describing: maxValue))")
        print("Charts - Chart type: \(chartType), X-axis interval: \(xAxisInterval.displayName)")
        print("Charts - Custom Y range: \(customMinY ?? 0) to \(customMaxY ?? 0)")
        print("Charts - Measurement time: \(BLEData.Status.measTime) minutes")
        
        // Apply X-axis interval filtering first - now preserves original indices
        // This reduces point density while maintaining full timeline coverage
        let intervalFilteredResult = applyXAxisInterval(chartRadonValue, interval: xAxisInterval)
        print("Charts - After interval filtering: \(intervalFilteredResult.data.count) points (interval: \(xAxisInterval.displayName))")
        print("Charts - Timeline preserved: indices \(intervalFilteredResult.originalIndices.first ?? 0) to \(intervalFilteredResult.originalIndices.last ?? 0)")
        
        // PERFORMANCE OPTIMIZATION: Decimate data for large datasets to reduce lag
        let optimizedResult = decimateDataForPerformance(intervalFilteredResult.data, existingIndices: intervalFilteredResult.originalIndices)
        let optimizedData = optimizedResult.data
        let originalIndices = optimizedResult.originalIndices
        
        // CRITICAL FIX: Use preserved original indices for accurate time mapping
        let values = zip(originalIndices, optimizedData).map { (originalIndex, yValue) -> ChartDataEntry in
            return ChartDataEntry(x: Double(originalIndex), y: yValue)
        }
        
        print("Charts - Data mapping: \(optimizedData.count) optimized points, last X: \(values.last?.x ?? 0), original data count: \(inRadonValue.count)")
        print("Charts - Time mapping: first X=\(values.first?.x ?? 0), last X=\(values.last?.x ?? 0), should span 0 to \(inRadonValue.count - 1)")
  
        // Modern line chart dataset
        let set1 = LineChartDataSet(entries: values, label: "")
        set1.drawIconsEnabled = false

        // Apply chart type configuration BEFORE setting colors
        configureChartType(set1, chartType: chartType, isLargeDataset: dataNo > 500)
        
        // Apply line color and width (may be overridden by chart type)
        let lineColor = isDarkMode ? UIColor.white : UIColor.black
        set1.setColor(lineColor)
        
        // Only set line width if not overridden by chart type
        if chartType != .bar {
            set1.lineWidth = 1.0 // Thin line as requested
        }
        
        // Modern highlight styling with appropriate color for dark mode
        let highlightColor = isDarkMode ? UIColor.white.withAlphaComponent(0.8) : UIColor.black.withAlphaComponent(0.8)
        set1.highlightColor = highlightColor
        set1.highlightLineWidth = 1.5
        set1.highlightLineDashLengths = [4, 2]
        
        // Circle styling for data points (shown on highlight)
        set1.drawCirclesEnabled = false // Hidden by default, shown on highlight
        set1.circleRadius = 4.0
        set1.circleHoleRadius = 2.0
        set1.setCircleColor(isDarkMode ? UIColor.white : UIColor.black)
        set1.circleHoleColor = UIColor.systemBackground
        
        // Enable value highlighting
        set1.drawHorizontalHighlightIndicatorEnabled = true
        set1.drawVerticalHighlightIndicatorEnabled = true
        
        // Clean value display
        set1.drawValuesEnabled = false
        
        let data = LineChartData(dataSet: set1)
        
        // Use custom max Y if provided and valid, otherwise use calculated max
        let calculatedMaxY = Double(maxValue ?? 0)
        let finalMaxY: Double
        if let customMaxY = customMaxY, customMaxY.isFinite && !customMaxY.isNaN && customMaxY > 0 {
            finalMaxY = customMaxY
        } else {
            finalMaxY = calculatedMaxY > 0 ? calculatedMaxY : 10.0 // Default fallback
        }
        
        // Determine minimum Y value (can be negative)
        let finalMinY: Double
        if let customMinY = customMinY, customMinY.isFinite && !customMinY.isNaN {
            finalMinY = customMinY
        } else {
            finalMinY = 0.0 // Default to 0 if not specified
        }
        
        chartsControl.chartInit(inChart, inSelectUnit, finalMaxY, inAlarmValue: inAlarmValue)
        
        // Apply custom axis ranges if provided and valid
        inChart.leftAxis.axisMinimum = finalMinY
        inChart.leftAxis.axisMaximum = finalMaxY
        
        // X-axis minimum will be set below based on scroll position
        
        // Handle scroll (customMinX) and zoom (customMaxX) independently
        let dataMaxX = Double(inRadonValue.count - 1)
        let windowSize = customMaxX ?? dataMaxX  // How many points to show (zoom)
        let requestedScrollPosition = customMinX ?? 0.0  // Where user wants to start viewing
        
        // CRITICAL: Prevent scroll beyond available data
        let maxAllowedScroll = max(0, dataMaxX - windowSize + 1)  // Latest position where full window fits
        let clampedScrollPosition = min(maxAllowedScroll, max(0, requestedScrollPosition))
        
        // Calculate the actual viewing window - no stretching allowed
        let viewStart = clampedScrollPosition
        let viewEnd = min(dataMaxX, viewStart + windowSize)
        
        // Apply the viewing window to the chart
        inChart.xAxis.axisMinimum = viewStart
        inChart.xAxis.axisMaximum = viewEnd
        
        print("Charts - Scroll control: requested=\(requestedScrollPosition), max_allowed=\(maxAllowedScroll), clamped=\(clampedScrollPosition)")
        print("Charts - View window: \(viewStart) to \(viewEnd) (size: \(viewEnd - viewStart)), data: 0 to \(dataMaxX)")
        
        // SET UP TIME-BASED X-AXIS FORMATTING
        setupTimeBasedXAxis(inChart, dataCount: dataNo, originalDataCount: inRadonValue.count)
        
        // Recalculate Y-axis labeling with proper range
        let yRange = finalMaxY - finalMinY
        if yRange > 0 {
            let optimalYSteps = 6
            let stepSize = yRange / Double(optimalYSteps)
            
            // Round step size to nice numbers
            let magnitude = pow(10.0, floor(log10(stepSize)))
            let normalizedStep = stepSize / magnitude
            let niceStep: Double
            
            if normalizedStep <= 1.0 {
                niceStep = 1.0
            } else if normalizedStep <= 2.0 {
                niceStep = 2.0
            } else if normalizedStep <= 5.0 {
                niceStep = 5.0
            } else {
                niceStep = 10.0
            }
            
            inChart.leftAxis.granularity = niceStep * magnitude
            
            // Calculate proper label count for the range
            let rangeCovered = yRange / (niceStep * magnitude)
            inChart.leftAxis.labelCount = Int(ceil(rangeCovered)) + 1
        }
        
        inChart.data = data
        
        // Final verification of chart setup
        print("Charts - FINAL SETUP: X-axis range 0 to \(inChart.xAxis.axisMaximum), Y-axis range \(inChart.leftAxis.axisMinimum) to \(inChart.leftAxis.axisMaximum)")
        print("Charts - FINAL SETUP: Data points in chart: \(values.count), last data point X: \(values.last?.x ?? -1)")
        print("Charts - FINAL SETUP: Chart should show from measurement start to current time")
    }
    
    // MARK: - Performance Optimization Helper
    private static func decimateDataForPerformance(_ data: [Double], existingIndices: [Int]) -> (data: [Double], originalIndices: [Int]) {
        let maxOptimalPoints = 1000 // Maximum points for optimal performance
        
        guard data.count > maxOptimalPoints else {
            // Return original data with existing indices
            return (data: data, originalIndices: existingIndices)
        }
        
        // Calculate decimation factor with safety check
        let decimationFactor = max(1, data.count / maxOptimalPoints)
        var decimatedData: [Double] = []
        var originalIndices: [Int] = []
        
        // Safety check to prevent stride errors
        guard decimationFactor > 0 && data.count > 0 && existingIndices.count == data.count else {
            print("Charts - ERROR: Invalid decimation parameters: factor=\(decimationFactor), count=\(data.count), indices=\(existingIndices.count)")
            return (data: data, originalIndices: existingIndices)
        }
        
        // Decimate by taking every nth point, preserving original indices from existingIndices
        for i in stride(from: 0, to: data.count, by: decimationFactor) {
            decimatedData.append(data[i])
            originalIndices.append(existingIndices[i])
        }
        
        // CRITICAL: Always include the final data point to show up to current time
        let lastDataIndex = data.count - 1
        if data.count > 1 && (originalIndices.isEmpty || originalIndices.last != existingIndices[lastDataIndex]) {
            decimatedData.append(data.last!)
            originalIndices.append(existingIndices[lastDataIndex])
        }
        
        print("Charts - Decimated from \(data.count) to \(decimatedData.count) points (factor: \(decimationFactor))")
        print("Charts - Original timeline range: \(originalIndices.first ?? 0) to \(originalIndices.last ?? 0)")
        print("Charts - Last original value: \(data.last ?? 0), last decimated value: \(decimatedData.last ?? 0)")
        
        return (data: decimatedData, originalIndices: originalIndices)
    }
    
    // MARK: - X-Axis Interval Helper
    private static func applyXAxisInterval(_ data: [Double], interval: XAxisInterval) -> (data: [Double], originalIndices: [Int]) {
        guard interval != .all && data.count > interval.factor else {
            let indices = Array(0..<data.count)
            return (data: data, originalIndices: indices)
        }
        
        var filteredData: [Double] = []
        var originalIndices: [Int] = []
        
        switch interval {
        case .all:
            let indices = Array(0..<data.count)
            return (data: data, originalIndices: indices)
        case .every5, .every10, .every30:
            // Simple interval filtering - take every nth point with safety check
            let safeInterval = max(1, interval.factor) // Ensure positive stride
            for i in stride(from: 0, to: data.count, by: safeInterval) {
                filteredData.append(data[i])
                originalIndices.append(i)
            }
        case .hourly, .daily:
            // For time-based intervals, group and average data points with safety check
            let groupSize = max(1, interval.factor) // Ensure positive stride
            for i in stride(from: 0, to: data.count, by: groupSize) {
                let endIndex = min(i + groupSize, data.count)
                let groupData = Array(data[i..<endIndex])
                let average = groupData.reduce(0, +) / Double(groupData.count)
                filteredData.append(average)
                // Use the middle index of the group for better time representation
                let middleIndex = i + (endIndex - i) / 2
                originalIndices.append(middleIndex)
            }
        }
        
        // CRITICAL: Always include the final data point to ensure timeline extends to current time
        let lastIndex = data.count - 1
        if data.count > 1 && !filteredData.isEmpty {
            // Check if the last point is already included within tolerance
            if originalIndices.isEmpty || originalIndices.last! < lastIndex {
                filteredData.append(data[lastIndex])
                originalIndices.append(lastIndex)
                print("Charts - Added final data point to preserve timeline end: index \(lastIndex), value \(data[lastIndex])")
            }
        }
        
        print("Charts - Interval filtering: \(data.count) -> \(filteredData.count) points, last original: \(data.last ?? 0), last filtered: \(filteredData.last ?? 0)")
        print("Charts - Original indices range: \(originalIndices.first ?? 0) to \(originalIndices.last ?? 0) (preserves timeline)")
        
        return (data: filteredData, originalIndices: originalIndices)
    }
    
    // MARK: - Chart Type Configuration Helper
    private static func configureChartType(_ dataSet: LineChartDataSet, chartType: ChartDisplayType, isLargeDataset: Bool) {
        print("Charts - Configuring chart type: \(chartType)")
        
        switch chartType {
        case .smooth:
            print("Charts - Applying smooth/cubic bezier mode")
            if isLargeDataset {
                // High performance mode for large datasets
                dataSet.mode = LineChartDataSet.Mode.linear
                dataSet.drawFilledEnabled = false
            } else {
                // High quality smooth curves
                dataSet.mode = LineChartDataSet.Mode.cubicBezier
                dataSet.cubicIntensity = 0.2
                dataSet.drawFilledEnabled = true
                dataSet.fillAlpha = 0.1
                dataSet.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
            }
            
        case .linear:
            print("Charts - Applying linear mode")
            // Simple linear lines - fast performance
            dataSet.mode = LineChartDataSet.Mode.linear
            dataSet.drawFilledEnabled = false
            
        case .stepped:
            print("Charts - Applying stepped mode")
            // Stepped line chart - good for discrete data
            dataSet.mode = LineChartDataSet.Mode.stepped
            dataSet.drawFilledEnabled = true
            dataSet.fillAlpha = 0.2
            dataSet.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
            
        case .bar:
            print("Charts - Applying bar-style mode")
            // For bar chart effect, we'll use a thicker line with no curves
            dataSet.mode = LineChartDataSet.Mode.linear
            dataSet.drawFilledEnabled = true
            dataSet.fillAlpha = 0.3
            dataSet.fillColor = UIColor.systemOrange.withAlphaComponent(0.3)
            dataSet.lineWidth = 4.0 // Thicker for bar effect
            dataSet.drawCirclesEnabled = true
            dataSet.circleRadius = 3.0
        }
    }
    
    // MARK: - Time-Based X-Axis Setup
    private static func setupTimeBasedXAxis(_ chartView: LineChartView, dataCount: Int, originalDataCount: Int) {
        // Calculate measurement period (assuming current time is end of measurement)
        let currentTime = Date()
        let measurementMinutes = TimeInterval(BLEData.Status.measTime * 60) // Convert to seconds
        let startTime = currentTime.addingTimeInterval(-measurementMinutes)
        
        print("Charts - Time setup: measurement duration \(BLEData.Status.measTime) minutes, from \(startTime) to \(currentTime)")
        print("Charts - Data counts: displayed=\(dataCount), original=\(originalDataCount)")
        
        // Create adaptive formatter for time-based labels - ALWAYS use original data count for accurate time mapping
        let timeFormatter = AdaptiveTimeAxisValueFormatter(startTime: startTime, dataCount: originalDataCount)
        chartView.xAxis.valueFormatter = timeFormatter
        
        // ADAPTIVE LABEL COUNT: Based on visible range and chart width
        let visibleRange = chartView.xAxis.axisMaximum - chartView.xAxis.axisMinimum
        let chartWidth = chartView.frame.width
        
        // Calculate optimal label count based on available space
        let minLabelSpacing: CGFloat = 80 // Minimum pixels between labels
        let maxPossibleLabels = Int(chartWidth / minLabelSpacing)
        let adaptiveLabelCount = min(8, max(3, min(maxPossibleLabels, Int(visibleRange / 5))))
        
        chartView.xAxis.labelCount = adaptiveLabelCount
        chartView.xAxis.granularityEnabled = true
        chartView.xAxis.granularity = max(1.0, visibleRange / Double(adaptiveLabelCount))
        
        // Style for time labels with adaptive rotation
        chartView.xAxis.labelFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        chartView.xAxis.labelTextColor = UIColor.secondaryLabel
        
        // ADAPTIVE ROTATION: Rotate labels based on density and available space
        let labelDensity = Double(adaptiveLabelCount) / visibleRange
        if labelDensity > 0.15 || chartWidth < 300 {
            chartView.xAxis.labelRotationAngle = -45 // Rotate for dense labels or small screens
        } else {
            chartView.xAxis.labelRotationAngle = 0 // Horizontal for sparse labels
        }
        
        // Set the adaptive formatter's current visible range for dynamic formatting
        timeFormatter.updateVisibleRange(visibleRange, labelCount: adaptiveLabelCount)
    }
    
    // MARK: - ChartViewDelegate Methods
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        // Disable all scaling - we handle this through slider control
        // This prevents any built-in scaling behavior
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        // Handle horizontal panning - update time formatter when view shifts
        if let lineChart = chartView as? LineChartView {
            updateTimeFormatterForVisibleRange(lineChart)
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // Allow value selection to work normally and notify time lookup
        let selectedIndex = Int(entry.x)
        MyUtil.printProcess(inMsg: "Charts - Value selected at index: \(selectedIndex), value: \(entry.y)")
        
        // Post notification to update time lookup section
        NotificationCenter.default.post(
            name: NSNotification.Name("ChartValueSelected"),
            object: nil,
            userInfo: ["index": selectedIndex, "value": entry.y]
        )
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Allow deselection to work normally
    }
    
    // MARK: - Helper Methods
    private func updateTimeFormatterForVisibleRange(_ chartView: LineChartView) {
        // Update the time formatter when the visible range changes due to panning
        if let formatter = chartView.xAxis.valueFormatter as? AdaptiveTimeAxisValueFormatter {
            let visibleRange = chartView.xAxis.axisMaximum - chartView.xAxis.axisMinimum
            let labelCount = chartView.xAxis.labelCount
            
            // Update formatter with new visible range
            formatter.updateVisibleRange(visibleRange, labelCount: labelCount)
            
            // Update label rotation based on new density
            let chartWidth = chartView.frame.width
            let labelDensity = Double(labelCount) / visibleRange
            
            if labelDensity > 0.15 || chartWidth < 300 {
                chartView.xAxis.labelRotationAngle = -45
            } else {
                chartView.xAxis.labelRotationAngle = 0
            }
            
            // Refresh the chart to apply new labels
            chartView.notifyDataSetChanged()
        }
    }
}



// MARK: - Adaptive Time Axis Formatter
class AdaptiveTimeAxisValueFormatter: NSObject, AxisValueFormatter {
    private let startTime: Date
    private let dataCount: Int
    private var currentVisibleRange: Double = 100.0
    private var currentLabelCount: Int = 5
    
    init(startTime: Date, dataCount: Int) {
        self.startTime = startTime
        self.dataCount = dataCount
        super.init()
    }
    
    func updateVisibleRange(_ range: Double, labelCount: Int) {
        self.currentVisibleRange = range
        self.currentLabelCount = labelCount
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        // Convert data point index to actual time
        let dataIndex = Int(value)
        guard dataIndex >= 0 && dataCount > 0 else { return "" }
        
        // Calculate time for this data point
        let totalDuration = abs(startTime.timeIntervalSinceNow)
        let timePerPoint = totalDuration / Double(dataCount)
        let pointTime = startTime.addingTimeInterval(Double(dataIndex) * timePerPoint)
        
        // ADAPTIVE FORMATTING: Choose format based on visible range and available space
        let formatter = DateFormatter()
        
        // Determine format based on visible range and label density
        let pointsPerLabel = currentVisibleRange / Double(max(1, currentLabelCount))
        let timeSpanPerLabel = timePerPoint * pointsPerLabel
        let hoursPerLabel = timeSpanPerLabel / 3600
        
        if hoursPerLabel < 1 {
            // Very zoomed in - show minutes only
            formatter.dateFormat = "HH:mm"
        } else if hoursPerLabel < 6 {
            // Moderately zoomed in - show hour and minute
            formatter.dateFormat = "HH:mm"
        } else if hoursPerLabel < 24 {
            // Medium zoom - show date and time
            if currentLabelCount <= 4 {
                formatter.dateFormat = "MM/dd HH:mm"
            } else {
                formatter.dateFormat = "HH:mm"
            }
        } else {
            // Zoomed out - show dates only
            let daysPerLabel = hoursPerLabel / 24
            if daysPerLabel > 7 {
                formatter.dateFormat = "MM/dd" // Just date for very long periods
            } else {
                formatter.dateFormat = "MM/dd" // Date for week+ periods
            }
        }
        
        return formatter.string(from: pointTime)
    }
}




