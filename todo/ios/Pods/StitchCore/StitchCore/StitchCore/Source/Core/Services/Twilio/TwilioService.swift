import ExtendedJson
import PromiseKit

public class TwilioService: Service {
    internal var client: StitchClient
    internal var name: String

    init(client: StitchClient, name: String) {
        self.client = client
        self.name = name
    }

    // swiftlint:disable:next identifier_name
    func send(from: String, to: String, body: String) -> Promise<Undefined> {
        return client.executeServiceFunction(name: "send",
                                              service: name,
                                              args: ["from": from,
                                                     "to": to,
                                                     "body": body] as Document)
        .flatMap {
            guard let doc = try Document.fromExtendedJson(xjson: $0) as? Document else {
                throw StitchError.responseParsingFailed(reason: "\($0) was not a valid document")
            }
            return try BSONDecoder().decode(Undefined.self,
                                             from: doc)
        }
    }
}
