//
//  CreateReviewViewController.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/13/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit

// MARK: - CreateReviewViewControllerDelegate (protocol)

protocol CreateReviewViewControllerDelegate : class {
    func createReviewViewControllerDidCancel()
    func createReviewViewControllerDidFinishWithReview(review : String)
}

class CreateReviewViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet private weak var reviewTextView: UITextView!

    weak var delegate: CreateReviewViewControllerDelegate?
    
    var currentReview: String?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reviewTextView.text = currentReview

        title = currentReview != nil ? "Edit Review" : "New Review"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reviewTextView.becomeFirstResponder()
    }

    // MARK: - Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        reviewTextView.resignFirstResponder()
        delegate?.createReviewViewControllerDidCancel()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        reviewTextView.resignFirstResponder()
        let review = reviewTextView.text
        delegate?.createReviewViewControllerDidFinishWithReview(review: review!)
    }
    
    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        /// Limit allowed text to 140 characters
        return textView.text.characters.count + text.characters.count < 140
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text
        let trimmedString = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        navigationItem.rightBarButtonItem?.isEnabled = trimmedString.characters.count > 0
    }
}
