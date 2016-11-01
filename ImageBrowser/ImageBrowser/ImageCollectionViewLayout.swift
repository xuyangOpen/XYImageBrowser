//
//  ImageCollectionViewLayout.swift
//  ImageBrowser
//
//  Created by King on 16/10/24.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit

class ImageCollectionViewLayout: UICollectionViewFlowLayout {

    override func collectionViewContentSize() -> CGSize {
        
        let count = CGFloat((self.collectionView?.dataSource?.collectionView(self.collectionView!, numberOfItemsInSection: 0))!)
        //设置
        return CGSizeMake(self.collectionView!.frame.size.width * count , self.collectionView!.frame.size.height)
    }
    
    func frameForItemAtIndexPath(indexPath:NSIndexPath) -> CGRect{
        return CGRectMake(CGFloat(indexPath.item)*(self.collectionView!.frame.size.width), 0, self.collectionView!.frame.size.width, self.collectionView!.frame.size.height)
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        //这里必须使用copy，不然会有警告⚠️
        let attr = super.layoutAttributesForItemAtIndexPath(indexPath)?.copy() as! UICollectionViewLayoutAttributes
        attr.frame = self.frameForItemAtIndexPath(indexPath)
        return attr
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let count = self.collectionView?.dataSource?.collectionView(self.collectionView!, numberOfItemsInSection: 0)
        var attrs = [UICollectionViewLayoutAttributes]()
        for idx in 0..<count! {
            var attr:UICollectionViewLayoutAttributes?
            let idxPath = NSIndexPath.init(forRow: idx, inSection: 0)
            let itemFrame = self.frameForItemAtIndexPath(idxPath)
            if CGRectIntersectsRect(itemFrame, rect) {
                attr = self.layoutAttributesForItemAtIndexPath(idxPath)
                attrs.append(attr!)
            }
        }
        return attrs
    }
    
}
