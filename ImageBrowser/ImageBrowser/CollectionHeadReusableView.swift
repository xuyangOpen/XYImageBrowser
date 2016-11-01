//
//  CollectionHeadReusableView.swift
//  ImageBrowser
//
//  Created by King on 16/11/1.
//  Copyright © 2016年 kf. All rights reserved.
//

import UIKit

class CollectionHeadReusableView: UICollectionReusableView {
    
    let titleLable = UILabel()
    let cellBound = UIScreen.mainScreen().bounds
    
    func setHeadTitle(title:String){
        self.titleLable.text = title
        self.titleLable.textColor = UIColor.blackColor()
        self.titleLable.textAlignment = .Center
        self.titleLable.frame = self.bounds
        self.addSubview(self.titleLable)
        self.backgroundColor = UIColor.lightGrayColor()
    }
}
