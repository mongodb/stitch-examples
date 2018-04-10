import StitchCore

// Protocol that view controllers should inherit when they need a StitchClient
protocol UIStitchDelegate {
    
    // Method that will be called once in a ViewController's
    // lifetime with an initialized StitchClient
    func onReady(_ stitchClient: StitchClient)
}

extension UIStitchDelegate {
    
    // Method that should be called in a ViewController's
    // viewDidLoad() or viewDidAppear() to register the
    // controller with the globally managed StitchClient
    func register(uiStitchDelegate: UIStitchDelegate) {
        UIStitchManager.shared.delegates.append(uiStitchDelegate)
    }
}

// Private singleton class which manages a StitchClient and
// a list of the delegates that have yet to use it. Other files
// can only access the shared StitchClient via inheriting
// UIStitchDelegate
private class UIStitchManager {
    static fileprivate(set) var shared = UIStitchManager()
    
    private struct Consts {
        
        static var AppId: String {
            let path = Bundle.main.path(forResource: "Stitch-Info", ofType: "plist")
            let infoDic = NSDictionary(contentsOfFile: path!) as? [String: AnyObject]
            let appId = infoDic!["APP_ID"] as! String
            assert(appId != "<Your-App-ID>", "Insert your App ID in Stitch-Info.plist")
            return appId
        }
    }

    var stitchClient: StitchClient?
    var delegates = [UIStitchDelegate?]() {
        didSet {
            guard let client = self.stitchClient else { return }
            for (idx, delegate) in delegates.enumerated().reversed() {
                delegate?.onReady(client)
                delegates.remove(at: idx)
            }
        }
    }
    
    init() {
        StitchClientFactory.create(appId: Consts.AppId).done { client in
            self.stitchClient = client
            for (idx, delegate) in self.delegates.enumerated().reversed() {
                delegate?.onReady(client)
                self.delegates.remove(at: idx)
            }
            }.cauterize()
    }
}
