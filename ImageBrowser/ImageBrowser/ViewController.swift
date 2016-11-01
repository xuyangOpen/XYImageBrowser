//
//  ViewController.swift
//  ImageBrowser
//
//  Created by King on 16/10/21.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,ImageBrowserDelegate {

    let reuseIdentifier = "imageCell"
    let headReuseIdentifier = "headImageCell"
    let bounds = UIScreen.mainScreen().bounds
    var imageCollectionView:UICollectionView?
    let imagesArray = ["show1.jpg","show2.jpg","show3.jpg","dynamic1.gif","show4.jpg","show5.jpg","show6.jpeg","show7.jpg","show8.PNG","1.pic_hd.jpg","qrcode.jpg"]
    
    //保存图片路径的数组，原图和缩略图
    var originImageArray = [String]()
    var ThumbnailArray = [String]()
    
    //保存图片视图的数组，第一组和第二组
    var sectionOneImageViewArray = [UIImageView]()
    var sectionTwoImageViewArray = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.setCollectionView()
        
        //读取plist文件
        let path = NSBundle.mainBundle().pathForResource("Property List", ofType: "plist")
        let tempArray = NSArray.init(contentsOfFile: path!)
        for i in 0..<tempArray!.count {
            let dic = tempArray![i] as! NSDictionary
            self.originImageArray.append(dic["OriginImage"] as! String)
            self.ThumbnailArray.append(dic["Thumbnail"] as! String)
        }
    }
    
    //MARK:初始化collectionView
    func setCollectionView(){
        //布局  每行3个item
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .Vertical//滚动方向
        flowLayout.minimumLineSpacing = 10//行间距
        flowLayout.minimumInteritemSpacing = 10//item间距
        let itemWidth = (bounds.width - 4*10) / 3.0 - 1
        let itemHeight:CGFloat = 75.0
        flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight)
        flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        flowLayout.headerReferenceSize = CGSizeMake(self.bounds.width, 50)
        //UICollectionView
        self.imageCollectionView = UICollectionView.init(frame: CGRectMake(0, 22, self.bounds.width, self.bounds.height), collectionViewLayout: flowLayout)
        self.imageCollectionView?.backgroundColor = UIColor.whiteColor()
        self.imageCollectionView?.delegate = self
        self.imageCollectionView?.dataSource = self
        
        //注册cell
        self.imageCollectionView?.registerClass(CollectionImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.imageCollectionView?.registerClass(CollectionHeadReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headReuseIdentifier)
        self.view.addSubview(self.imageCollectionView!)
    }
    
    //MARK:UICollectionView的代理方法
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return self.imagesArray.count
        }else {
            return self.originImageArray.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionImageCell
        if indexPath.section == 0 {
            item.setImageViewInfo(self.imagesArray[indexPath.item])
            //添加图片数组
            if !self.sectionOneImageViewArray.contains(item.imageView) {
                self.sectionOneImageViewArray.append(item.imageView)
            }
        }else{
            item.setImageViewWithUrl(self.ThumbnailArray[indexPath.row])
            //添加图片数组
            if !self.sectionTwoImageViewArray.contains(item.imageView) {
                self.sectionTwoImageViewArray.append(item.imageView)
            }
        }
        
        return item
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let head = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: headReuseIdentifier, forIndexPath: indexPath) as! CollectionHeadReusableView

        if indexPath.section == 0 {
            head.setHeadTitle("浏览本地图片")
        }else if indexPath.section == 1{
            head.setHeadTitle("浏览网络图片")
        }
        return head
    }

    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let browser = XYImageBrowser()
            //浏览图片的控件
            browser.imageViewArray = self.sectionOneImageViewArray
            //下标
            browser.currentImageIndex = indexPath.item
            //设置代理 ImageBrowserDelegate
            browser.delegate = self
            //调用图片浏览器
            browser.show()
        }else{
            let browser = XYImageBrowser()
            browser.imageViewArray = self.sectionTwoImageViewArray
            browser.currentImageIndex = indexPath.item
            browser.imageUrlArray = self.originImageArray
            browser.delegate = self
            browser.show()
        }
    }
    
    
    //MARK:图片浏览器的代理方法
    //MARK:保存图片的代理方法
    func saveImageStatus(status: SaveStatus) {
        if status == .Success {
            print("图片保存成功")
        }else {
            print("图片保存失败")
        }
    }
    
    //MARK:识别二维码的代理方法
    func identificationCode(content: String?, failedReason: String?) {
        if failedReason != nil {
            print(failedReason)
        }else{
            print("二维码的内容为 = \(content)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

