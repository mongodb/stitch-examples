//
//  ViewController.swift
//  MongoDBSample
//
//

import UIKit
import MongoCore

class ViewController: UIViewController {
    
    private var baasClient: BaasClient?

    override func viewDidLoad() {
        super.viewDidLoad()
    
        baasClient = BaasClient(appName: "todo")
    }

    
    // MARK: - Actions
    
}

