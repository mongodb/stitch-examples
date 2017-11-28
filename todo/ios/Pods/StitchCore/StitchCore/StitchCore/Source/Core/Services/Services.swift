//
//  Services.swift
//  StitchCore
//
//  Created by Jason Flax on 11/14/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

protocol Service {
    var client: StitchClient { get }
    var name: String { get }
}

internal class Services {
    let client: StitchClient

    func twilio(name: String) -> TwilioService {
        return TwilioService(client: client, name: name)
    }

    internal init(client: StitchClient) {
        self.client = client
    }
}
