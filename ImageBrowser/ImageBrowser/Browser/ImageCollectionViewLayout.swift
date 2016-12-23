//
//  ImageCollectionViewLayout.swift
//  ImageBrowser
//
//  Created by King on 16/10/24.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit

class ImageCollectionViewLayout: UICollectionViewFlowLayout {

    override var collectionViewContentSize : CGSize {
        
        let count = CGFloat((self.collectionView?.dataSource?.collectionView(self.collectionView!, numberOfItemsInSection: 0))!)
        //设置
        return CGSize(width: self.collectionView!.frame.size.width * count , height: self.collectionView!.frame.size.height)
    }
    
    func frameForItemAtIndexPath(_ indexPath:IndexPath) -> CGRect{
        return CGRect(x: CGFloat(indexPath.item)*(self.collectionView!.frame.size.width), y: 0, width: self.collectionView!.frame.size.width, height: self.collectionView!.frame.size.height)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        //这里必须使用copy，不然会有警告⚠️
        let attr = super.layoutAttributesForItem(at: indexPath)?.copy() as! UICollectionViewLayoutAttributes
        attr.frame = self.frameForItemAtIndexPath(indexPath)
        return attr
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let count = self.collectionView?.dataSource?.collectionView(self.collectionView!, numberOfItemsInSection: 0)
        var attrs = [UICollectionViewLayoutAttributes]()
        for idx in 0..<count! {
            var attr:UICollectionViewLayoutAttributes?
            let idxPath = IndexPath.init(row: idx, section: 0)
            let itemFrame = self.frameForItemAtIndexPath(idxPath)
            if itemFrame.intersects(rect) {
                attr = self.layoutAttributesForItem(at: idxPath)
                attrs.append(attr!)
            }
        }
        return attrs
    }
    
}
