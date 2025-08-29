//
//  five.swift
//  EcoQube
//
//  Created by jung sukhwan on 2020/02/11.
//  Copyright © 2020 jung sukhwan. All rights reserved.
//

import UIKit

class RulerHorizontalView: UIView{
    var x=0.0// inch screen
    var den=0
    var diem=0
    var dem=0
    var radonUnit = Int(0)
    
    //var r = UIScreen.main.bounds.size.width
    //var c = UIScreen.main.bounds.size.height
    
    var c = UIScreen.main.bounds.size.width
    var r = UIScreen.main.bounds.size.height
    
    var l = CGPoint()
    var f = CGPoint()
    let dataRange = Double(0.2)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            f = touch.location(in: self)
            l = f
            setNeedsDisplay()
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
         if let touch = touches.first {
            l = touch.location(in: self)
            setNeedsDisplay()
        }
    }
   
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            l = touch.location(in: self)
            setNeedsDisplay()
        }
    }
 
    override func draw(_ rect: CGRect) {
        let tcanh = r * r + c * c
        var so = x * 25.4
        so = so * so;
        let socann = Double(tcanh) / so;
        let socan = sqrt(socann)
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(0.5)
        var socanb = socan
        if den % 2 == 1{
            socanb = socan/2.54
        }
        
        let totalCount = 32
        socanb = Double(Int(c)) / Double(totalCount)
        
        var size = CGSize()
        size.width = 50
        size.height = 50
       
        var calRadonValue = Double(0)
        var strRadon = String.init(format: "%.1f", calRadonValue)
    
        //대표값 삼각형 그리기
        for i in 0..<3{
            let lineColor = UiConstants.RadonStatus.color[i]
            UiConstants.RadonStatus.color[i].set()
            context?.strokePath()
            
            context?.saveGState()
            let colorr = lineColor.cgColor
            context?.setFillColor(colorr)
            context?.strokePath()
            context?.fillPath()
            
            var areaSize = CGSize()
            areaSize.height = CGFloat(socanb*Double(1.5))
            switch i {
            case 0:
                calRadonValue = Double(0)
                strRadon = String.init(format: "%.0f", calRadonValue)
                break

            case 1:
                calRadonValue = Double(2.7)
                if radonUnit == 0{
                    strRadon = String.init(format: "%.1f", calRadonValue)
                }
                else{
                    strRadon = String.init(format: "%.0f", Float(100))
                }
                
                break
                
            case 2:
                calRadonValue = Double(4)
                if radonUnit == 0{
                    strRadon = String.init(format: "%.1f", calRadonValue)
                }
                else{
                    strRadon = String.init(format: "%.0f", Float(148))
                }
                
                break
                    
            default:
                break
            }
            

            let startY = 6
            let calY = Double(c - 25) * ((calRadonValue / 6.4))
            let valueLine = Double(startY) + calY
                   
            let path = UIBezierPath()
            
            let triangleWidth = CGFloat((valueLine))
            let triangleHeight = CGFloat(socanb*Double(1.2))
            
            areaSize.width = CGFloat(socanb*Double(20))
            let test = CGRect(origin: CGPoint(x: triangleWidth, y: 0), size: areaSize)
            context?.fill(test)
            
            path.move(to: CGPoint(x: CGFloat(triangleWidth), y: CGFloat(socanb*Double(2))))
            path.addLine(to: CGPoint(x: CGFloat(socanb*Double(0.6)) + triangleWidth, y:  CGFloat(socanb*Double(2)) + triangleHeight))
            path.addLine(to: CGPoint(x: triangleWidth - CGFloat(socanb*Double(0.6)), y: CGFloat(socanb*Double(2)) + triangleHeight))
                  
            path.close()
            UiConstants.Color.hex1F2738.setFill()
            path.fill()
                  
            // 대표값 라벨용
            if i == 0{//소수점 없음
                let rectRadonStr = CGRect(origin: CGPoint(x: triangleWidth - 4, y: CGFloat(socanb*Double(3)) + 5), size: size)
                strRadon.draw(in: rectRadonStr, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),NSAttributedString.Key.foregroundColor: UIColor.black])
            }
            else{
                let rectRadonStr = CGRect(origin: CGPoint(x: triangleWidth - 8, y: CGFloat(socanb*Double(3)) + 5), size: size)
                strRadon.draw(in: rectRadonStr, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),NSAttributedString.Key.foregroundColor: UIColor.black])
            }
       
        }
    }
    
    func round2(a:Double)->Double{
        let mu = pow(10.0,2.0)
        let r=round(a*mu)/mu
        return r
    }
}


