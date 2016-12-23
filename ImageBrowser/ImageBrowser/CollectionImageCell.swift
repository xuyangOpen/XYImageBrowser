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
    let processView = CircleProcess.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    
    //设置图片名称
    func setImageViewInfo(_ imageName:String){
        self.contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        if imageName.hasSuffix("gif") {
            let path = Bundle.main.path(forResource: imageName, ofType: nil)
            imageView.sd_setImage(with: URL.init(fileURLWithPath: path!))
        }else{
            imageView.image = UIImage.init(named: imageName)
        }
        
        imageView.frame = self.bounds
    }
    
    //设置图片路径
    func setImageViewWithUrl(_ url:String){
        self.contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        
        SDImageCache.shared().clearDisk()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().cleanDisk()
        //判断图片是否缓存过
        SDImageCache.shared().queryDiskCache(forKey: url) { (cacheImage, cacheType) in
            if cacheImage == nil{//图片未缓存
                //添加一个加载视图
                self.processView.circleTintColor = UIColor.gray
                self.contentView.addSubview(self.processView)
                self.processView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                self.processView.center = CGPoint(x: self.bounds.width/2.0, y: self.bounds.height/2.0)
                //下载图片
                SDWebImageManager.shared().downloadImage(with: URL.init(string: url), options: .progressiveDownload, progress: { (receivedSize, expectedSize) in
                    self.processView.process = CGFloat(receivedSize) / CGFloat(expectedSize)
                    }, completed: { (image, err, cacheType, flag, downloadUrl) in
                        if flag {
                            //设置图片
                            self.imageView.image = image
                            //缓存图片
                            SDImageCache.shared().store(image, forKey: url, toDisk: false)
                        }
                        //移除加载视图
                        self.processView.removeFromSuperview()
                })
            }else{//图片已缓存
                self.imageView.sd_setImage(with: URL.init(string: url))
            }
        }

        imageView.sd_setImage(with: URL.init(string: url))
        imageView.frame = self.bounds
    }
}
