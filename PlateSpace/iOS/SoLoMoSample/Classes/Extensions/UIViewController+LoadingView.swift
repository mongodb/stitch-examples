//
//  UIViewController+LoadingView.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/14/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    
    fileprivate static let viewTagNumber = 100
    
    func showLoadingView(show : Bool){
        
        if show {
            if self.view.viewWithTag(UIViewController.viewTagNumber) != nil{
             // do nothing
            }
            else{
                let view  = UIView(frame: self.view.frame)
                view.tag = UIViewController.viewTagNumber
                view.backgroundColor = UIColor.black
                view.alpha = 0.5
                let activityIndicator = UIActivityIndicatorView()
                activityIndicator.startAnimating()
                activityIndicator.center = view.center
                view.addSubview(activityIndicator)
                self.view.addSubview(view)
            }

        }
        else{
            if let view = self.view.viewWithTag(UIViewController.viewTagNumber){
                view.removeFromSuperview()
            }
        }
    }
    
}
