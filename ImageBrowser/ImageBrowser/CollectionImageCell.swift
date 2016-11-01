//
//  CollectionImageCell.swift
//  ImageBrowser
//
//  Created by King on 16/10/21.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit
import SDWebImage

class CollectionImageCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let processView = CircleProcess.init(frame: CGRectMake(0, 0, 50, 50))
    
    //设置图片名称
    func setImageViewInfo(imageName:String){
        self.contentView.addSubview(imageView)
        imageView.contentMode = .ScaleAspectFill
        imageView.layer.masksToBounds = true
        if imageName.hasSuffix("gif") {
            let path = NSBundle.mainBundle().pathForResource(imageName, ofType: nil)
            imageView.sd_setImageWithURL(NSURL.init(fileURLWithPath: path!))
        }else{
            imageView.image = UIImage.init(named: imageName)
        }
        
        imageView.frame = self.bounds
    }
    
    //设置图片路径
    func setImageViewWithUrl(url:String){
        self.contentView.addSubview(imageView)
        imageView.contentMode = .ScaleAspectFill
        imageView.layer.masksToBounds = true
        
        SDImageCache.sharedImageCache().clearDisk()
        SDImageCache.sharedImageCache().clearMemory()
        SDImageCache.sharedImageCache().cleanDisk()
        //判断图片是否缓存过
        SDImageCache.sharedImageCache().queryDiskCacheForKey(url) { (cacheImage, cacheType) in
            if cacheImage == nil{//图片未缓存
                //添加一个加载视图
                self.processView.circleTintColor = UIColor.grayColor()
                self.contentView.addSubview(self.processView)
                self.processView.frame = CGRectMake(0, 0, 50, 50)
                self.processView.center = CGPointMake(self.bounds.width/2.0, self.bounds.height/2.0)
                //下载图片
                SDWebImageManager.sharedManager().downloadImageWithURL(NSURL.init(string: url), options: .ProgressiveDownload, progress: { (receivedSize, expectedSize) in
                    self.processView.process = CGFloat(receivedSize) / CGFloat(expectedSize)
                    }, completed: { (image, err, cacheType, flag, downloadUrl) in
                        if flag {
                            //设置图片
                            self.imageView.image = image
                            //缓存图片
                            SDImageCache.sharedImageCache().storeImage(image, forKey: url, toDisk: false)
                        }
                        //移除加载视图
                        self.processView.removeFromSuperview()
                })
            }else{//图片已缓存
                self.imageView.sd_setImageWithURL(NSURL.init(string: url))
            }
        }

        imageView.sd_setImageWithURL(NSURL.init(string: url))
        imageView.frame = self.bounds
    }
}
