//
//  BalloonMarker.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/06.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation
import DGCharts
import SwiftUI
open class BalloonMarker: MarkerImage
{
    open var color: UIColor
    open var arrowSize = CGSize(width: 12, height: 8)
    open var font: UIFont
    open var textColor: UIColor
    open var insets: UIEdgeInsets
    open var minimumSize = CGSize()
    var inUint = Int(0)
    
    fileprivate var label: String?
    fileprivate var _labelSize: CGSize = CGSize()
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var _drawAttributes = [NSAttributedString.Key : AnyObject]()
    
    
    //public init(unit:Int, color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets)
    public init(unit:Int, color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets)
    {
        self.inUint = unit
        self.color = color
        self.font = font
        self.textColor = textColor
        self.insets = insets
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = .center
        super.init()
    }
    
    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint
    {
        var offset = self.offset
        var size = self.size
        
        if size.width == 0.0 && image != nil
        {
            size.width = image!.size.width
        }
        if size.height == 0.0 && image != nil
        {
            size.height = image!.size.height
        }
        
        let width = size.width
        let height = size.height
        let padding: CGFloat = 8.0
        
        var origin = point
        origin.x -= width / 2
        origin.y -= height
        
        if origin.x + offset.x < 0.0
        {
            offset.x = -origin.x + padding
        }
        else if let chart = chartView,
            origin.x + width + offset.x > chart.bounds.size.width
        {
            offset.x = chart.bounds.size.width - origin.x - width - padding
        }
        
        if origin.y + offset.y < 0
        {
            offset.y = height + padding;
        }
        else if let chart = chartView,
            origin.y + height + offset.y > chart.bounds.size.height
        {
            offset.y = chart.bounds.size.height - origin.y - height - padding
        }
        
        //V1.5.0 - 20240728
        offset.x = 0
        offset.y = 0
        
        return offset
    }
    
    open override func draw(context: CGContext, point: CGPoint)
    {
        guard let label = label else { return }
        
        let offset = self.offsetForDrawing(atPoint: point)
        let size = self.size
        
        /*var rect = CGRect(
            origin: CGPoint(
                x: point.x + offset.x,
                y: point.y + offset.y),
            size: size)*/
        
        var rect = CGRect(
        origin: CGPoint(
            x: point.x + offset.x,
            y: 80),
        size: size)
        
        rect.origin.x -= size.width / 2.0
        rect.origin.y -= size.height
        
        context.saveGState()
        
        // Modern marker styling with rounded corners and shadow - smaller size
        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 6.0)
        
        // Add subtle shadow
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.1).cgColor)
        
        context.setFillColor(color.cgColor)
        context.addPath(roundedRect.cgPath)
        context.fillPath()
        
        // Modern border
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(1.0)
        context.addPath(roundedRect.cgPath)
        context.strokePath()
        
        /*if offset.y > 0
        {
            context.beginPath()
            context.move(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                y: rect.origin.y + arrowSize.height))
            //arrow vertex
            context.addLine(to: CGPoint(
                x: point.x,
                y: point.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + rect.size.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + rect.size.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + arrowSize.height))
            context.fillPath()
        }
        else
        {
            context.beginPath()
            context.move(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y))
            
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            
            //arrow vertex
            context.addLine(to: CGPoint(
                x: point.x,
                y: point.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y))
            context.fillPath()
        }*/
        
        if offset.y > 0 {
            rect.origin.y += self.insets.top + arrowSize.height
        } else {
            rect.origin.y += self.insets.top
        }
        
        rect.size.height -= self.insets.top + self.insets.bottom
        
        UIGraphicsPushContext(context)
        
        label.draw(in: rect, withAttributes: _drawAttributes)
        /*label.draw(with: rect, options: .usesLineFragmentOrigin, attributes: _drawAttributes, context: nil)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
            ctx.cgContext.setLineWidth(10)

            let rectangle = CGRect(x: 0, y: 0, width: 512, height: 512)
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
        }*/
        
        
        UIGraphicsPopContext()
        
        context.restoreGState()
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        var yStrValue = String("")
        let flagCheck = Bool(false)
        
        if flagCheck == false{
            if inUint == 0{
                if BLEData.Flag.V3_New && entry.y >= 100{
                    yStrValue = "Exceeds maximum\ndetectable radon"
                }
                else{
                    yStrValue = String(format: "%.2f pCi/ℓ", entry.y)
                }
                
            }
            else{
                if BLEData.Flag.V3_New && entry.y >= 3700{
                    yStrValue = "Exceeds maximum\ndetectable radon"
                }
                else{
                    yStrValue = String(format: "%.0f Bq/m³", entry.y)
                }
            }
        }
        
        // Calculate date/time for this data point using same logic as DateTimeSelectionView
        let dataPointIndex = Int(entry.x)
        let totalMinutes = BLEData.Status.measTime
        let totalDataPoints = BLEData.Log.radonValue.count
        
        var timeString = ""
        if totalDataPoints > 0 && totalMinutes > 0 {
            // Use same calculation logic as DateTimeSelectionView for consistency
            let measurementStartTime = Date().addingTimeInterval(-Double(totalMinutes * 60))
            
            // Calculate time for this data point index
            let minutesPerDataPoint = Double(totalMinutes) / Double(totalDataPoints)
            let dataPointTime = measurementStartTime.addingTimeInterval(Double(dataPointIndex) * minutesPerDataPoint * 60)
            
            // Ensure the calculated time doesn't exceed current time
            let currentTime = Date()
            let finalTime = min(dataPointTime, currentTime)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, HH:mm"
            timeString = dateFormatter.string(from: finalTime)
            
            print("BalloonMarker - Data point \(dataPointIndex): calculated time \(finalTime), total points \(totalDataPoints), measurement time \(totalMinutes) min")
        }
        
        setLabel(xValue: entry.x, yValue: yStrValue, timeValue: timeString)
    }
    
    //open func setLabel(_ newLabel: String)
    open func setLabel(xValue: Double, yValue: String, timeValue: String = "")
    {
        // Display radon value with date/time below it
        if !timeValue.isEmpty {
            label = yValue + "\n" + timeValue
        } else {
            label = yValue
        }
        
        _drawAttributes.removeAll()
        _drawAttributes[.font] = self.font
        _drawAttributes[.paragraphStyle] = _paragraphStyle
        _drawAttributes[.foregroundColor] = self.textColor
        
        _labelSize = label?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        
        var size = CGSize()
        // Make the tooltip smaller by reducing padding
        size.width = _labelSize.width + self.insets.left + self.insets.right
        size.height = _labelSize.height + self.insets.top + self.insets.bottom
        size.width = max(minimumSize.width, size.width)
        size.height = max(minimumSize.height, size.height)
        
        // Reduce overall size by 20%
        size.width *= 0.8
        size.height *= 0.8
        
        self.size = size
    }
}



