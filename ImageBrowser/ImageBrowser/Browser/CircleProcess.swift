//
//  CircleProcess.swift
//  ImageBrowser
//
//  Created by King on 16/10/28.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit

class CircleProcess: UIView {

    //当前进度
    var process:CGFloat = 0.0{
        didSet{
            self.loading()
        }
    }
    //圆的中心点
    var centerPoint = CGPointZero
    //圆的半径
    var radius:CGFloat = 0
    //基调颜色
    var circleTintColor = UIColor.redColor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        centerPoint = CGPointMake(frame.size.width/2.0, frame.size.height/2.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        //外圆
        CGContextSetStrokeColorWithColor(context, circleTintColor.CGColor)
        CGContextSetLineWidth(context, 2)
        CGContextAddArc(context, centerPoint.x, centerPoint.y, centerPoint.x - 2, 0, 2*CGFloat(M_PI), 0)
        CGContextDrawPath(context, .Stroke)
        
        //内圆
        CGContextSetFillColorWithColor(context, circleTintColor.CGColor)
        CGContextMoveToPoint(context, centerPoint.x, centerPoint.y)
        CGContextAddArc(context, centerPoint.x, centerPoint.y, centerPoint.x - 4, 0 * CGFloat(M_PI)/180.0, 360 * process * CGFloat(M_PI)/180.0, 0)
        CGContextDrawPath(context, .Fill)
    }
 
    //更新进度
    func loading(){
        self.setNeedsDisplay()
    }

    var timer:NSTimer? 
    //测试圆
    func testLoading(){
        self.process = 0.0
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(SimulationTest), userInfo: nil, repeats: true)
    }
    
    func SimulationTest(){
        self.process += 0.01
        self.loading()
        if self.process >= 1.0 {
            self.timer?.invalidate()
            self.timer = nil
        }
        
    }
    
}
