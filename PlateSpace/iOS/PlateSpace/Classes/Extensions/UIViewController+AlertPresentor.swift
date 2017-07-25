//
//  UIViewController+AlertPresentor.swift
//  PlateSpace
//

import UIKit

extension UIViewController {
    func showErrorAlert(withDescription description: String? = nil) {
        let message = description ?? "An error has occured"
        showAlert(withTitle: nil, message: message)
    }
    
    func showAlert(withTitle title: String?, message: String?) {
        if presentedViewController != nil || (title == nil && message == nil) {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)        
    }
    
    func showAlert(withTitle title: String?, message: String?, cancelButtonTitle: String, approveButtonTitle: String, approveActionHandler: ((UIAlertAction) -> Void)?, cancelActionHandler: ((UIAlertAction) -> Void)? = nil) {
        if presentedViewController != nil || (title == nil && message == nil) {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: cancelActionHandler)
        alertController.addAction(cancelAction)
        
        let approveAction = UIAlertAction(title: approveButtonTitle, style: .default, handler: approveActionHandler)
        alertController.addAction(approveAction)
        
        present(alertController, animated: true, completion: nil)
    }

}
