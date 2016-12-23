//
//  XYImageBrowser.swift
//  ImageBrowser
//
//  Created by King on 16/10/21.
//  Copyright © 2016年 kf. All rights reserved.
//

/*
    待完善的问题：
    1、图片下载过程中，给张默认图片
    2、图片下载失败时，给张下载失败的提示图片
 */

import UIKit
import SDWebImage
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol ImageBrowserDelegate:NSObjectProtocol {
    //保存图片的代理方法
    func saveImageStatus(_ status:SaveStatus) -> Void
    //识别图中二维码的代理方法
    func identificationCode(_ content:String?,failedReason:String?) -> Void
}

public enum SaveStatus : Int {
    case success              //保存成功
    case failed               //保存失败
}

public enum BrowserModel : Int {
    case localModel             //浏览本地图片模式
    case netModel               //浏览网络图片模式
}

class XYImageBrowser: UIView,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UITableViewDelegate,UITableViewDataSource {

    //需要传入赋值的属性
    var currentImageIndex = 0{//当前显示图片的下标
        didSet{
            self.counterLabel.text = "\(self.currentImageIndex+1)/\((self.imageViewArray?.count)!)"
        }
    }
    var imageViewArray:[UIImageView]?       //需要浏览的图片原控件
    //图片的url路径
    var imageUrlArray:[String]?{
        didSet{
            if imageUrlArray != nil && imageUrlArray?.count > 0 {
                //如果图片url路径不为空，则当前形式为浏览图片形式
                self.browserModel = .netModel
                //初始化图片下载进度
                for _ in 0..<imageUrlArray!.count {
                    self.imageDownloadProgress.append(0.0)
                }
            }
        }
    }
    //图片下载进度跟踪数组
    var imageDownloadProgress = [CGFloat]()
    
    //图片浏览器的私有属性
    var imagePickerView:UICollectionView?
    let reuseIdentifier = "XYImageCell"
    let mainbounds = UIScreen.main.bounds       //屏幕尺寸
    let counterLabel = UILabel()                        //上中计数的label
    let moreButton = UIButton()                         //右上角更多操作的按钮
    var isShowMorePanel = false                         //是否显示更多操作的面板
    var morePanel:UITableView?                          //更多面板
    var panelMenu = ["保存图片","识别图中二维码"]           //面板内容
    weak var delegate:ImageBrowserDelegate?             //代理
    
    var originRectArray = [NSValue]()                   //存放图片原位置的数组
    var isAnimating = false                             //是否正在动画
    var placeholderOriginImage:UIImage?                 //原控件的图片
    var browserModel = BrowserModel.localModel          //图片浏览形式
    
    //用来放大或者缩小的临时视图
    var tempImageView = UIImageView()

    //MARK:显示方法
    func show(){
        let window = UIApplication.shared.keyWindow
        //设置视图的优先级
        window?.windowLevel = UIWindowLevelStatusBar
        self.frame = window!.bounds
        self.backgroundColor = UIColor.black
        window?.addSubview(self)
        //获取原图片的所有位置
        self.getOriginRect()
        
        //浏览模式
        switch self.browserModel {
        case .localModel:
            //开始动画
            self.beginAnimationWithLocal(self.imageViewArray![currentImageIndex].image!)
            break
        case .netModel:
            //预先加载图片
            self.beginAnimationWithNet()
            break
        }
    }
    
    //MARK:获取原图片的所有位置
    func getOriginRect(){
        for i in 0..<self.imageViewArray!.count {
            let originFrame = self.imageViewArray![i].convert(self.imageViewArray![i].frame, to: self)
            self.originRectArray.append(NSValue.init(cgRect: originFrame))
        }
    }
    
    //MARK:开始动画--网络模式
    func beginAnimationWithNet(){
        //查询url图片是否已经缓存，如果已经缓存了，则使用动画，如果没有缓存，则开始缓存图片
        SDImageCache.shared().queryDiskCache(forKey: self.imageUrlArray![self.currentImageIndex]) { (cacheImage, cacheType) in
            if cacheImage == nil{//图片没有缓存时，直接初始化视图
                //初始化视图
                self.setViewInfo()
            }else{//图片缓存了时，则开始启用动画
                //开始动画
                self.beginAnimationWithLocal(cacheImage!)
            }
        }
    }
    
    //MARK:开始动画--本地模式
    func beginAnimationWithLocal(_ animationImage:UIImage){
        //开始动画状态
        self.isAnimating = true
        
        //用一个临时图片来完成放大的效果
        tempImageView.image = animationImage
        //获取到图片原控件的位置
        tempImageView.frame = self.originRectArray[self.currentImageIndex].cgRectValue
        tempImageView.layer.masksToBounds = true
        tempImageView.contentMode = self.imageViewArray![currentImageIndex].contentMode
        self.addSubview(tempImageView)
        
        //获取最优比例
        let size = self.tempImageView.sizeThatFits(self.bounds.size)
        let height = (self.bounds.width / size.width) * size.height
        
        UIView.animate(withDuration: ImageBrowserModel.beginOrFinishAnimationDuration, animations: {
            self.tempImageView.frame = CGRect(x: 0, y: (self.bounds.height-height)/2.0, width: self.bounds.width, height: height)
        }, completion: { (flag) in
            //动画完成之后，开始初始化视图
            self.setViewInfo()
            self.tempImageView.removeFromSuperview()
            self.isAnimating = false
        }) 
    }
    
    //MARK:点击图片时，关闭图片浏览器
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isShowMorePanel {//关闭图片浏览器
            if !isAnimating {//如果不在进行动画，才能关闭图片浏览器
                //将window的优先级恢复成默认
                UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelNormal
                //移除计数器的label
                self.counterLabel.removeFromSuperview()
                //更多的菜单按钮
                self.moreButton.removeFromSuperview()
                //判断当前浏览器模式，如果是网络图片模式，并且正在下载的进度情况下，视图透明度变为0后移除
                if self.browserModel == .netModel && self.imageDownloadProgress[self.currentImageIndex] < 1 {
                    UIView.animate(withDuration: ImageBrowserModel.beginOrFinishAnimationDuration, animations: {
                        self.alpha = 0
                        }, completion: { (flag) in
                            self.removeFromSuperview()
                    })
                }else{
                    self.backgroundColor = UIColor.clear
                    //获取当前图片原位置
                    let originFrame = self.originRectArray[self.currentImageIndex].cgRectValue
                    
                    //是否需要此操作
                    let originImageView = self.imageViewArray![self.currentImageIndex]
                    if ImageBrowserModel.isNeedPlaceholder {
                        //将原图片控件的图片清空，并改变背景颜色
                        if originImageView.backgroundColor == nil {
                            originImageView.backgroundColor = UIColor.white
                        }
                        self.placeholderOriginImage = originImageView.image
                        originImageView.image = nil
                    }
                    //播放结束动画
                    UIView.animate(withDuration: ImageBrowserModel.beginOrFinishAnimationDuration, animations: {
                        if self.frame.intersects(originFrame){
                            self.tempImageView.frame = originFrame
                        }else{
                            self.tempImageView.alpha = 0
                        }
                    }, completion: { (flag) in
                        self.removeFromSuperview()
                        if ImageBrowserModel.isNeedPlaceholder{
                            //将图片还原
                            originImageView.image = self.placeholderOriginImage
                        }
                    }) 
                }
            }
        }else{//关闭菜单
            self.closePanel()
        }
    }
    
    //MARK:初始化方法
    func setViewInfo(){
        //布局  每行3个item
        let flowLayout = ImageCollectionViewLayout()
        flowLayout.scrollDirection = .horizontal//滚动方向
        flowLayout.itemSize = CGSize(width: self.bounds.width, height: self.bounds.height)
        //UICollectionView
        self.imagePickerView = UICollectionView.init(frame: CGRect(x: 0, y: 0, width: self.bounds.width + ImageBrowserModel.itemSpace, height: self.bounds.height), collectionViewLayout: flowLayout)
        self.imagePickerView?.backgroundColor = UIColor.clear
        self.imagePickerView?.delegate = self
        self.imagePickerView?.dataSource = self
        self.imagePickerView?.isPagingEnabled = true
        self.imagePickerView?.showsHorizontalScrollIndicator = false
        self.imagePickerView?.showsVerticalScrollIndicator = false
        
        //滚动到第currentImageIndex张图片
        self.imagePickerView?.scrollToItem(at: IndexPath.init(item: self.currentImageIndex, section: 0), at: .centeredHorizontally, animated: false)
        //注册item
        self.imagePickerView?.register(XYImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        //注册头部
        self.imagePickerView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "ImageHeader")
        self.addSubview(self.imagePickerView!)
        
        //下标的label
        counterLabel.text = "\(self.currentImageIndex+1)/\((self.imageViewArray?.count)!)"
        counterLabel.textColor = UIColor.white
        counterLabel.textAlignment = .center
        counterLabel.font = UIFont.boldSystemFont(ofSize: 20)
        counterLabel.frame = CGRect(x: (mainbounds.width-200)/2.0, y: 22, width: 200, height: 25)
        self.addSubview(self.counterLabel)
        //右上角的点击按钮
        if ImageBrowserModel.bundlePath != ""{
            moreButton.setImage(UIImage.init(named: ImageBrowserModel.bundlePath + "/dian.tiff"), for: UIControlState())
        }
        moreButton.frame = CGRect(x: mainbounds.width-70, y: 22, width: 50, height: 25)
        moreButton.imageEdgeInsets = UIEdgeInsetsMake(3, 10, 3, 10)
        moreButton.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        self.addSubview(moreButton)
    }

    //MARK:UICollectionView的代理方法
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.imageViewArray?.count)!
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! XYImageCell
        //如果复用的cell有下载进度，则重新复用
        if self.browserModel == .netModel {
            while cell.loadingView.process < 1 && cell.loadingView.process > 0 {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! XYImageCell
            }
            
            //网络图片浏览模式
            cell.tag = indexPath.item
            cell.loadingView.process = self.imageDownloadProgress[indexPath.item]
            //图片下载进度回调
            cell.imageDownloadProgress = {(progress,tag) in
                self.imageDownloadProgress[tag] = progress
            }
            cell.imageUrl = self.imageUrlArray![indexPath.row]
        }else{
            //本地图片浏览模式
            cell.originImageView = self.imageViewArray![indexPath.item]
        }
        
        //初始化cell
        cell.setContentInfo()
        
        //关闭图片浏览器的回调
        cell.closeBrowser = { (imgView) in
            //设置临时视图
            self.tempImageView = imgView
            self.tempImageView.layer.masksToBounds = true
            self.tempImageView.contentMode = self.imageViewArray![indexPath.item].contentMode
            self.touchesBegan(Set(), with: nil)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        //设置item的中间距离为默认为20
        return ImageBrowserModel.itemSpace
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //获得单位宽
        let unitWidth = self.imagePickerView?.bounds.width
        //如果当前偏移量小于半个单位宽，则当前下标为1
        if scrollView.contentOffset.x < unitWidth!/2.0 {
            self.currentImageIndex = 0
        }else{
            var offset = Int(scrollView.contentOffset.x / unitWidth!)
            if scrollView.contentOffset.x.truncatingRemainder(dividingBy: unitWidth!) > unitWidth!/2.0{
                offset += 1
            }
            if offset < self.imageViewArray?.count {
                self.currentImageIndex = offset
            }
        }
    }
    
    //MARK:更多按钮点击事件
    func moreAction(){
        if isShowMorePanel {//面板为显示状态
            //关闭面板
            self.closePanel()
        }else{//面板为隐藏状态
            self.openPanel()
        }
    }
    
    //MARK:关闭菜单面板
    func closePanel(){
        self.isShowMorePanel = false
        UIView.animate(withDuration: 0.5, animations: {
            self.morePanel?.frame = CGRect(x: 0, y: self.bounds.height, width: self.bounds.width, height: 44*CGFloat(self.panelMenu.count+1))
            }, completion: { (flag) in
                
        })
    }
    
    //MARK:打开菜单面板
    func openPanel(){
        self.isShowMorePanel = true
        //呼出面板
        if self.morePanel == nil {
            self.morePanelInitial()
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.morePanel?.frame = CGRect(x: 0, y: self.bounds.height - 44*CGFloat(self.panelMenu.count+1), width: self.bounds.width, height: 44*CGFloat(self.panelMenu.count+1))
        })
    }
    
    //更多面板初始化
    func morePanelInitial(){
        self.morePanel = UITableView.init(frame: CGRect(x: 0, y: bounds.height, width: bounds.width, height: 44*CGFloat(self.panelMenu.count+1)), style: .plain)
        self.morePanel!.delegate = self
        self.morePanel!.dataSource = self
        self.addSubview(self.morePanel!)
    }
    
    //MARK:Tableview的代理方法
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.panelMenu.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "panelMenuCell") ?? UITableViewCell.init(style: .default, reuseIdentifier: "panelMenuCell")
        if indexPath.row < self.panelMenu.count {
            cell.textLabel?.text = self.panelMenu[indexPath.row]
        }else{
            cell.textLabel?.text = "取消"
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == self.panelMenu.count {
            self.closePanel()
        }else if indexPath.row == 0{//保存图片
            switch self.browserModel {
            case .localModel:
                if self.imageViewArray![self.currentImageIndex].image != nil {
                    UIImageWriteToSavedPhotosAlbum(self.imageViewArray![self.currentImageIndex].image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }else{
                    if self.delegate != nil {
                        self.delegate?.saveImageStatus(.failed)
                    }
                }
            case .netModel:
                //判断图片是否已经缓存完毕，如果缓存完毕，则可以保存，如果没有缓存完成，则不能保存
                SDImageCache.shared().queryDiskCache(forKey: self.imageUrlArray![self.currentImageIndex]) { (cacheImage, cacheType) in
                    if cacheImage == nil{
                        if self.delegate != nil {
                            self.delegate?.saveImageStatus(.failed)
                        }
                    }else{
                        UIImageWriteToSavedPhotosAlbum(cacheImage!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                }
            }
        }else if indexPath.row == 1{//识别图中二维码
            switch self.browserModel {
            case .localModel:
                if self.imageViewArray![self.currentImageIndex].image != nil {
                    //调用识别二维码的方法
                    self.identificationQRCode(self.imageViewArray![self.currentImageIndex].image!)
                }else{
                    if self.delegate != nil {
                        self.delegate?.identificationCode(nil, failedReason: "图片不存在")
                    }
                }
            case .netModel:
                //判断图片是否已经缓存完毕，如果缓存完毕，则可以保存，如果没有缓存完成，则不能保存
                SDImageCache.shared().queryDiskCache(forKey: self.imageUrlArray![self.currentImageIndex]) { (cacheImage, cacheType) in
                    if cacheImage == nil{
                        if self.delegate != nil {
                            self.delegate?.identificationCode(nil, failedReason: "图片未下载")
                        }
                    }else{
                        self.identificationQRCode(cacheImage!)
                    }
                }
            }
        }
    }
    
    //MARK:保存图片的回调方法
    func image(_ image: UIImage, didFinishSavingWithError: NSError?,contextInfo: AnyObject)
    {
        if didFinishSavingWithError == nil
        {
            if self.delegate != nil {
                self.delegate?.saveImageStatus(.success)
            }
        }else{
            if self.delegate != nil {
                self.delegate?.saveImageStatus(.failed)
            }
        }
    }
    
    //MARK:识别图中二维码的图片
    func identificationQRCode(_ image:UIImage){
        //初始化检测器
        let detector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        //监测到的结果数组
        let features = detector?.features(in: CIImage.init(cgImage: image.cgImage!))
        if (features?.count)! >= 1 {
            let feature = features?[0] as! CIQRCodeFeature
            let scannedResult = feature.messageString
            if self.delegate != nil {
                self.delegate?.identificationCode(scannedResult, failedReason: nil)
            }
        }
    }
    
}
