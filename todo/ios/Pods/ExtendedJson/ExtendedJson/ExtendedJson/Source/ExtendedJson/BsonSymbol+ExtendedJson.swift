//
//  BsonSymbol+ExtendedJson.swift
//  ExtendedJson
//
//  Created by Jason Flax on 10/6/17.
//  Copyright © 2017 MongoDB. All rights reserved.
//

import Foundation

extension Symbol: ExtendedJsonRepresentable {
    enum CodingKeys: String, CodingKey {
        case symbol = "$symbol"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try container.decode(String.self, forKey: CodingKeys.symbol))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.symbol, forKey: CodingKeys.symbol)
    }

    public static func fromExtendedJson(xjson: Any) throws -> ExtendedJsonRepresentable {
        guard let json = xjson as? [String: Any],
            let symbol = json[ExtendedJsonKeys.symbol.rawValue] as? String,
            json.count == 1 else {
                throw BsonError.parseValueFailure(value: xjson, attemptedType: Symbol.self)
        }

        return Symbol(symbol)
    }

    public var toExtendedJson: Any {
        return [ExtendedJsonKeys.symbol.rawValue: self.symbol]
    }

    public func isEqual(toOther other: ExtendedJsonRepresentable) -> Bool {
        return other is Symbol && (other as! Symbol).symbol == self.symbol
    }
}
