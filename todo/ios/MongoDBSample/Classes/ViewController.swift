//
//  ViewController.swift
//  MongoDBSample
//
//  Created by Ofer Meroz on 03/02/2017.
//  Copyright © 2017 Zemingo. All rights reserved.
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

