//
//  UIViewController+ChildHandling.swift
//  PlateSpace
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
