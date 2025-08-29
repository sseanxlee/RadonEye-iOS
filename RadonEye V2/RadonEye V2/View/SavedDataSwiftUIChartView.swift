//
//  SavedDataSwiftUIChartView.swift
//  RadonEye V2
//
//  SwiftUI chart implementation for saved data display
//

import SwiftUI
import DGCharts

// MARK: - Saved Data Chart View (enhanced to match MonitoringView)
struct SavedDataSwiftUIChartView: UIViewRepresentable {
    let logData: SavedLogData
    let chartType: ChartDisplayType
    let xAxisInterval: XAxisInterval
    let customMaxY: Double?
    let customMinY: Double?
    let customMaxX: Double?
    let customMinX: Double?
    let refreshTrigger: Int
    var selectedDataPoint: SelectedDataPoint? = nil
    
    // Gesture state bindings to sync with sliders
    @Binding var sliderValue: Double
    @Binding var horizontalOffset: Double
    @Binding var maxDataPoints: Double
    
    // Chart point selection callback
    var onPointSelected: ((Int) -> Void)?
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    class Coordinator: NSObject {
        var parent: SavedDataSwiftUIChartView
        var initialPanOffset: Double = 0
        var initialPinchRange: Double = 0
        var initialPinchOffset: Double = 0
        var pinchCenterPoint: Double = 0
        
        init(_ parent: SavedDataSwiftUIChartView) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let chartView = gesture.view as? LineChartView else { return }
            
            let translation = gesture.translation(in: chartView)
            let chartWidth = chartView.bounds.width
            
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
                }
                
            case .ended, .cancelled:
                let snappedOffset = round(parent.horizontalOffset)
                let maxValidOffset = max(0, parent.maxDataPoints - parent.sliderValue)
                let finalOffset = max(0, min(maxValidOffset, snappedOffset))
                
                DispatchQueue.main.async {
                    self.parent.horizontalOffset = finalOffset
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
                initialPinchRange = parent.sliderValue
                initialPinchOffset = parent.horizontalOffset
                pinchCenterPoint = initialPinchOffset + (initialPinchRange / 2.0)
                
            case .changed:
                let invertedScale = 1.0 / Double(scale)
                let newRange = initialPinchRange * invertedScale
                let clampedRange = max(10, min(parent.maxDataPoints, newRange))
                
                let newOffset = pinchCenterPoint - (clampedRange / 2.0)
                let maxValidOffset = max(0, parent.maxDataPoints - clampedRange)
                let clampedOffset = max(0, min(maxValidOffset, newOffset))
                
                DispatchQueue.main.async {
                    self.parent.sliderValue = clampedRange
                    self.parent.horizontalOffset = clampedOffset
                }
                
            case .ended, .cancelled:
                let snappedRange = round(parent.sliderValue)
                let clampedRange = max(10, min(parent.maxDataPoints, snappedRange))
                
                let targetOffset = pinchCenterPoint - (clampedRange / 2.0)
                let maxValidOffset = max(0, parent.maxDataPoints - clampedRange)
                let clampedOffset = max(0, min(maxValidOffset, round(targetOffset)))
                
                DispatchQueue.main.async {
                    self.parent.sliderValue = clampedRange
                    self.parent.horizontalOffset = clampedOffset
                }
                
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
        
        // Add custom gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = false
        chartView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.cancelsTouchesInView = false
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
        if !logData.radonValues.isEmpty {
            updateChart(uiView, forceUpdate: false)
            
            // Highlight selected data point if provided
            if let selectedPoint = selectedDataPoint {
                DispatchQueue.main.async {
                    self.highlightDataPoint(uiView, index: selectedPoint.index)
                }
            } else {
                uiView.highlightValue(nil)
            }
        }
    }
    
    // Chart appearance is now handled by chartsControl.chartDraw - no need for separate setup
    
    private func updateChart(_ chartView: LineChartView, forceUpdate: Bool) {
        guard !logData.radonValues.isEmpty else {
            chartView.data = nil
            return
        }
        
        // Check if we need to update by comparing data count OR settings change
        let currentDataCount = logData.radonValues.count
        let chartDataCount = chartView.data?.entryCount ?? 0
        
        // Always update when forced or when data/settings change
        if forceUpdate || currentDataCount != chartDataCount || chartView.data == nil || refreshTrigger > 0 {
            // Use the same chart drawing logic as MonitoringView with chartsControl.chartDraw
            let effectiveMaxY = customMaxY ?? 4.0
            let effectiveMinY = customMinY ?? -1.0
            
            // Convert saved unit to display unit (same as monitoring)
            let displayUnit = logData.unit.contains("Bq") ? 1 : 0
            
            chartsControl.chartDraw(
                chartView,
                logData.radonValues, // Use saved values directly (already converted)
                0, // inValueUnit - saved values are already in correct format
                displayUnit, // inSelectUnit
                4.0, // Default alarm value for display
                false, // V3 flag - not relevant for saved data
                chartType: chartType,
                xAxisInterval: xAxisInterval,
                customMaxY: effectiveMaxY,
                customMinY: effectiveMinY,
                customMaxX: customMaxX,
                customMinX: customMinX,
                isDarkMode: isDarkMode
            )
            
            // No animation for instant loading
            MyUtil.printProcess(inMsg: "SavedDataChart - Chart updated instantly with \(logData.radonValues.count) data points")
        }
    }
    
    // Dataset configuration is now handled by chartsControl.chartDraw
    
    // Y-axis range configuration is now handled by chartsControl.chartDraw
    
    // X-axis range configuration is now handled by chartsControl.chartDraw
    
    // Time-based X-axis setup is now handled by chartsControl.chartDraw
    
    private func highlightDataPoint(_ chartView: LineChartView, index: Int) {
        guard let chartData = chartView.data,
              let dataSet = chartData.dataSets.first as? LineChartDataSet,
              index < dataSet.entryCount else {
            return
        }
        
        guard let entry = dataSet.entryForIndex(index) else {
            return
        }
        
        let highlight = Highlight(x: entry.x, y: entry.y, dataSetIndex: 0)
        chartView.highlightValue(highlight)
    }
}

// MARK: - UIGestureRecognizerDelegate extension for Coordinator
extension SavedDataSwiftUIChartView.Coordinator: UIGestureRecognizerDelegate {
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
extension SavedDataSwiftUIChartView.Coordinator: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // Convert chart entry X value to data point index
        let selectedIndex = Int(entry.x)
        
        // Validate index is within bounds
        guard selectedIndex >= 0 && selectedIndex < parent.logData.radonValues.count else {
            return
        }
        
        // Call the point selection callback immediately to update the time lookup
        DispatchQueue.main.async {
            self.parent.onPointSelected?(selectedIndex)
        }
        
        MyUtil.printProcess(inMsg: "SavedDataSwiftUIChartView - Point selected: index \(selectedIndex), value \(entry.y) - Time lookup will update")
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Optional: Handle deselection if needed
        MyUtil.printProcess(inMsg: "SavedDataSwiftUIChartView - No point selected")
    }
}

// Note: Time axis formatting is now handled by chartsControl.chartDraw and its internal time formatter
