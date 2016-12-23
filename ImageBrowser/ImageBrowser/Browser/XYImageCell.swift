//
//  XYImageCell.swift
//  ImageBrowser
//
//  Created by King on 16/10/21.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit
import SDWebImage

typealias dismissClosure = (UIImageView) -> Void
//参数1表示当前下载进度0-1   参数2表示当前cell的tag值
typealias downloadProgressClosure = (CGFloat,Int) -> Void

class XYImageCell: UICollectionViewCell,UIScrollViewDelegate {
    //cell的视图控件
    var containerView = UIScrollView()
    let imageView = UIImageView()
    let cellBounds = UIScreen.main.bounds
    
    //图片的原视图
    var originImageView = UIImageView()
    
    //手势属性
    var tapGesture:UITapGestureRecognizer?
    var doubleTapGesture:UITapGestureRecognizer?
    var pinchGesture:UIPinchGestureRecognizer?
    //当前图片放大或者缩小倍数
    var currentScale:CGFloat = 1.0
    
    //点击cell关闭图片浏览器的回调
    var closeBrowser:dismissClosure?
    //跟踪下载进度的回调
    var imageDownloadProgress:downloadProgressClosure?
    //是否是长图
    var isLongImage = false
    //图片的url地址
    var imageUrl = ""
    
    //加载视图
    let loadingView = CircleProcess.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    //占位视图
    let placeholderView = UIImageView.init()
    
    func setContentInfo(){
        //添加一个UIScrollView
        containerView.backgroundColor = UIColor.black
        containerView.delegate = self
        containerView.showsVerticalScrollIndicator = false
        containerView.showsHorizontalScrollIndicator = false
        containerView.zoomScale = 1.0//item每次加载时，缩放比例还原为1
        containerView.maximumZoomScale = 2.0//设置图片放大的最大比例为2
        containerView.frame = CGRect(x: 0, y: 0, width: cellBounds.width, height: cellBounds.height)
        self.contentView.addSubview(containerView)
        
        //图片设置
        self.imageSetting()
        
        //给cell添加双击和轻点的手势
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(tapGestureAction(_:)))
        
        doubleTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(doubleTapGestureAction(_:)))
        doubleTapGesture?.numberOfTapsRequired = 2
        //防止手势冲突
        tapGesture?.require(toFail: doubleTapGesture!)
        
        self.addGestureRecognizer(tapGesture!)
        self.addGestureRecognizer(doubleTapGesture!)
    }
    
    //MARK:图片设置
    func imageSetting(){
        
        containerView.addSubview(imageView)
        if imageUrl != "" {
            //判断图片是否有缓存
            SDImageCache.shared().queryDiskCache(forKey: imageUrl, done: { (downloadImage, cacheType) in
                if downloadImage == nil{//图片没有缓存的情况下，开始下载图片
                    //添加占位视图
                    if ImageBrowserModel.bundlePath != ""{
                        self.placeholderView.image = UIImage.init(named: ImageBrowserModel.bundlePath + "/pic_loading.tiff")
                    }
                    self.placeholderView.center = CGPoint(x: self.cellBounds.width/2.0, y: self.cellBounds.height/2.0)
                    self.placeholderView.bounds = CGRect(x: 0, y: 0, width: self.cellBounds.width/1.5, height: self.cellBounds.width/2.0)
                    self.contentView.addSubview(self.placeholderView)
                    //添加加载视图
                    self.loadingView.center = CGPoint(x: self.cellBounds.width/2.0, y: self.cellBounds.height/2.0)
                    self.loadingView.circleTintColor = UIColor.white
                    self.contentView.addSubview(self.loadingView)
                    //图片下载完成之前，scrollview禁止操作
                    self.containerView.isUserInteractionEnabled = false
                    
                    self.imageView.sd_setImage(with: URL.init(string: self.imageUrl), placeholderImage: UIImage.init(named: ""), options: .continueInBackground, progress: { (receivedSize, expectedSize) in
                        //计算图片下载的当前进度
                        self.loadingView.process = CGFloat(receivedSize)/CGFloat(expectedSize)
                        //回调下载进度方法
                        if self.imageDownloadProgress != nil{
                            self.imageDownloadProgress!(self.loadingView.process,self.tag)
                        }
                        }, completed: { (downloadImage, error, cacheType, url) in
                            if error == nil{//下载完成
                                //恢复操作
                                self.containerView.isUserInteractionEnabled = true
                                self.placeholderView.removeFromSuperview()
                                self.loadingView.removeFromSuperview()
                                self.setImageAttribute()
                            }else{//下载出错
                                if ImageBrowserModel.bundlePath != ""{
                                    self.placeholderView.image = UIImage.init(named: ImageBrowserModel.bundlePath + "/pic_loading_fail.tiff")
                                }
                                self.loadingView.removeFromSuperview()
                            }
                    })
                }else{//图片有缓存的情况下，直接使用图片
                    self.imageView.image = downloadImage
                    //进度为1
                    self.loadingView.process = 1
                    //回调下载进度方法
                    if self.imageDownloadProgress != nil{
                        self.imageDownloadProgress!(self.loadingView.process,self.tag)
                    }
                    self.setImageAttribute()
                }
            })
        }else{
            //添加图片
            imageView.image = originImageView.image
            self.setImageAttribute()
        }
    }
    
    //MARK:设置图片属性
    func setImageAttribute(){
        //获取图片最优尺寸
        let showSize = imageView.sizeThatFits(UIScreen.main.bounds.size)
        let height = (cellBounds.width / showSize.width) * showSize.height
        //如果图片高度 >= 屏幕高度，则y = 0
        //如果图片高度 < 屏幕高度，则y = (屏幕高度-图片高度) / 2.0  ，即居中显示
        var imageViewHeight:CGFloat = 0.0
        
        if height > cellBounds.height {
            isLongImage = true
            imageViewHeight = 0
            containerView.minimumZoomScale = 1.0//长图的最小缩小比例为1.0
            containerView.contentSize = CGSize(width: cellBounds.width, height: height)
        }else{
            isLongImage = false
            imageViewHeight = (cellBounds.height - height)/2.0
            containerView.minimumZoomScale = 0.5//小图的最小缩小比例为0.5
            containerView.contentSize = CGSize.zero
        }
        imageView.frame = CGRect(x: 0, y: imageViewHeight, width: cellBounds.width, height: height)
    }
    
    //MARK:单击手势
    func tapGestureAction(_ tap:UITapGestureRecognizer){
        if self.closeBrowser != nil {
            self.containerView.backgroundColor = UIColor.clear
            if isLongImage {//如果是长图，则比例缩放到1倍，并且滑动到顶部，主要是避免图片的跳动
                self.containerView.zoomScale = 1.0
                self.containerView.setContentOffset(CGPoint.zero, animated: false)
            }
            UIView.animate(withDuration: ImageBrowserModel.beginOrFinishAnimationDuration, animations: {
                self.containerView.zoomScale = 1.0
                self.imageView.transform = CGAffineTransform.identity
            })
            if self.closeBrowser != nil {
                self.closeBrowser!(self.imageView)
            }
        }
    }
    
    //MARK:双击手势
    func doubleTapGestureAction(_ doubleTap:UITapGestureRecognizer){
        //如果当前缩放比例小于1.0时，双击还原成1.0
        if self.currentScale < 1.0 {
            self.currentScale = 1.0
        }else if self.currentScale < 2.0{//缩放比例在1.0 - 2.0 之间时，双击放大到2.0
            self.currentScale = 2.0
            self.isOffset = true
        }else{//如果/Users/yangb/Desktop/测试代码/ImageBrowser/ImageBrowser当前缩放比例等于2.0，则缩放比例还原到1.0
            self.currentScale = 1.0
            self.isOffset = false
        }
        let zoomRect = self.zoomRectForScale(self.currentScale, center: doubleTap.location(in: doubleTap.view))
        //放大某个区域
        self.containerView.zoom(to: zoomRect, animated: true)
    }
    
    var isOffset = false
    //MARK:通过点击位置和缩放比例，获取应该缩放的区域范围
    func zoomRectForScale(_ scale:CGFloat,center:CGPoint) -> CGRect{
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.containerView.frame.size.height / scale
        zoomRect.size.width = self.containerView.frame.size.width / scale
        zoomRect.origin.x = center.x - zoomRect.size.width/2.0
        zoomRect.origin.y = center.y - zoomRect.size.height/2.0
        if self.isOffset {//如果当前图片超出了屏幕，则进行了偏移，所以同时需要加上偏移量
            zoomRect.origin.y += self.containerView.contentOffset.y
        }else{//当图片缩小还原时
            zoomRect.origin.y = self.containerView.contentOffset.y/2.0 - center.y/2.0
        }
        return zoomRect
    }
    
    //返回要放大的视图
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    //MARK:缩放过程
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var centerX = scrollView.center.x
        var centerY = scrollView.center.y
        //目前contentsize的width是否大于原scrollview的contentsize，如果大于，设置imageview中心x点为contentsize的一半，以固定imageview在该contentsize中心。如果不大于说明图像的宽还没有超出屏幕范围，可继续让中心x点为屏幕中点，此种情况确保图像在屏幕中心。
        centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : centerX
        centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : centerY
        //x往左偏移一半的间隔
        self.imageView.center = CGPoint(x: centerX,  y: centerY)
    }
    
    //MARK:获取倍数
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.currentScale = scale
    }
    
}
