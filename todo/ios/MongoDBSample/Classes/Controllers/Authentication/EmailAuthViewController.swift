//
//  EmailAuthViewController.swift
//  MongoDBSample
//
//

import UIKit
import StitchCore

protocol EmailAuthViewControllerDelegate {
    func emailAuthViewControllerDidPressCloseEmail()
}

enum EmailAuthOperationType {
    case confirmEmail(token: String, tokenId: String)
    case resetPassword(token: String, tokenId: String)
}

class EmailAuthViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var stitchClient: StitchAppClient!
    var delegate: EmailAuthViewControllerDelegate?
    var operationType: EmailAuthOperationType?    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stitchClient = Stitch.defaultAppClient
        
        if let operationType = operationType {
            switch operationType {
            case .confirmEmail(let token, let tokenId):
                confirmEmail(token: token, tokenId: tokenId)
            case .resetPassword(let token, let tokenId):
                resetPassword(token: token, tokenId: tokenId)
            }
        }
        else {
            activityIndicator.isHidden = true
            infoLabel.text = "Missing operation to perform"
        }
    }

    func confirmEmail(token: String, tokenId: String) {
           /*
        activityIndicator.isHidden = false
        infoLabel.text = "Confirming Email..."

        stitchClient?.emailConfirm(token: token, tokenId: tokenId)
            .response(completionHandler: { [weak self] (result) in
                self?.activityIndicator.isHidden = true
            switch result {
            case .success:
                self?.infoLabel.text = "Email Confirmed!"
                break
            case .failure(let error):
                self?.infoLabel.text = error.localizedDescription
                break
            }
        })*/
    }
    
    func resetPassword(token: String, tokenId: String) {
        
        /*
        activityIndicator.isHidden = false
        infoLabel.text = "Resetting Password..."
        
        stitchClient?.resetPassword(token: token, tokenId: tokenId)
            .response(completionHandler: { [weak self] (result) in
                self?.activityIndicator.isHidden = true
                switch result {
                case .success:
                    self?.infoLabel.text = "Password Reset!"
                    break
                case .failure(let error):
                    self?.infoLabel.text = error.localizedDescription
                    break
                }
            })
 */
    }
    
    //MARK: - Actions
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        delegate?.emailAuthViewControllerDidPressCloseEmail()
    }
    
    
}
