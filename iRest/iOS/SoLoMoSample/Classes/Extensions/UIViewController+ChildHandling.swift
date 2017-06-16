//
//  UIViewController+ChildHandling.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/9/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    func addChildController(childController : UIViewController){
        addChildViewController(childController)
        self.view.addSubview(childController.view)
        childController.didMove(toParentViewController: self)
    }
    
    func removeChildController(childController : UIViewController){
        childController.willMove(toParentViewController: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParentViewController()
    }
    
}
