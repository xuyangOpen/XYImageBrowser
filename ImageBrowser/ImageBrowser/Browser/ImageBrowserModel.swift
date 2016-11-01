//
//  ImageBrowserModel.swift
//  ImageBrowser
//
//  Created by King on 16/10/26.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit

class ImageBrowserModel: NSObject {

    static var itemSpace:CGFloat = 20.0          //图片浏览器中每个图片之间的间隔
    static let itemHalfSpace = ImageBrowserModel.itemSpace / 2.0
    static var beginOrFinishAnimationDuration = 0.4     //图片出现或消失的动画时间
    /*
        如果为true，当前预览的图片原控件位置为白色占位
        如果为false，则不变
     */
    static var isNeedPlaceholder = true                 //是否需要白色占位
    
    //资源文件路径
    static let bundlePath = NSBundle.mainBundle().resourcePath?.stringByAppendingString("/XYImageBrowserBundle.bundle/Contents/Resources")
}
