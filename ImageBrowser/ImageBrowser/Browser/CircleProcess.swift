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
    var centerPoint = CGPoint.zero
    //圆的半径
    var radius:CGFloat = 0
    //基调颜色
    var circleTintColor = UIColor.red
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        centerPoint = CGPoint(x: frame.size.width/2.0, y: frame.size.height/2.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        //外圆
        context?.setStrokeColor(circleTintColor.cgColor)
        context?.setLineWidth(2)
//        CGContextAddArc(context, centerPoint.x, centerPoint.y, centerPoint.x - 2, 0, 2*CGFloat(M_PI), 0)
        context?.addArc(center: CGPoint.init(x: centerPoint.x, y: centerPoint.y), radius: centerPoint.x - 2, startAngle: 0, endAngle: 2*CGFloat(M_PI), clockwise: false)
        context?.drawPath(using: .stroke);
    
        
        //内圆
        context?.setFillColor(circleTintColor.cgColor)
        context?.move(to: CGPoint(x: centerPoint.x, y: centerPoint.y))
//        CGContextAddArc(context, centerPoint.x, centerPoint.y, centerPoint.x - 4, 0 * CGFloat(M_PI)/180.0, 360 * process * CGFloat(M_PI)/180.0, 0)
         
        context?.addArc(center: CGPoint.init(x: centerPoint.x, y: centerPoint.y), radius: centerPoint.x - 4, startAngle: 0 * CGFloat(M_PI)/180.0, endAngle: 360 * process * CGFloat(M_PI)/180.0, clockwise: false)
        context?.drawPath(using: .fill)
    }
 
    //更新进度
    func loading(){
        self.setNeedsDisplay()
    }

    var timer:Timer? 
    //测试圆
    func testLoading(){
        self.process = 0.0
        self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(SimulationTest), userInfo: nil, repeats: true)
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
