
import UIKit

let SERVER = ""
let DOMAIN = ""
let USERNAME = ""
let PASSWORD = ""
let DISPLAY_NAME = ""
let PORT = 0

class ViewController: UIViewController, iOSWrapperListener {

    @IBOutlet weak var regStatusLabel: UILabel!
    
    var currentCallId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeCloudonixSDK()
    }
    
    // MARK: - Actions
    
    @IBAction func onDial(_ sender: Any) {
        iOSWrapper.sharedInstance()?.dial("")
    }
    
    @IBAction func onHangup(_ sender: Any) {
        guard let callId = currentCallId else {
            return
        }
        
        iOSWrapper.sharedInstance()?.hangup(callId)
    }
    
    // MARK: - Cloudonix SDK
    
    func initializeCloudonixSDK() {
        guard let url = Bundle.main.url(forResource: "", withExtension: "lic") else {
            print("Cloudonix license key not found")
            return
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to get contents of Cloudonix license key ")
            return
        }
        
        var licenseKey = String(data: data, encoding: .utf8)
        licenseKey = licenseKey?.replacingOccurrences(of: "\n", with: "")
        
        iOSWrapper.sharedInstance().initialize(withKey: licenseKey) { (success, error) in
            if success {
                print("Cloudonix SDK initialized")
                
                iOSWrapper.sharedInstance().setConfig("USE_OPUS", value: "1")
                iOSWrapper.sharedInstance().setConfig("ENABLE_ICE", value: "0")
                iOSWrapper.sharedInstance().setConfig("ENABLE_NAT", value: "1")
                iOSWrapper.sharedInstance().setConfig("ENABLE_STUN", value: "0")
                iOSWrapper.sharedInstance().setConfig("DISABLE_SECURE_SIPS", value: "1")
                iOSWrapper.sharedInstance()?.setConfig("USER_AGENT", value: "MyApp/1.0")
                
                iOSWrapper.sharedInstance()?.add(self)
                
                self.configureCloudonixSDK()
                self.register()
            } else {
                print("Failed to initialize Cloudonix SDK: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func configureCloudonixSDK() {
        let regData = iOSRegistrationData()
        regData.serverUrl = SERVER
        regData.domain = DOMAIN
        regData.username = USERNAME
        regData.password = PASSWORD
        regData.displayName = DISPLAY_NAME
        regData.transportType = IOS_TRANSPORT_TYPE_TLS
        regData.port = Int32(PORT)
        
        iOSWrapper.sharedInstance().setConfiguration(regData)
    }
    
    func register() {
        iOSWrapper.sharedInstance()?.registerAccount()
    }
    
    // MARK: - iOSWrapperListener
    
    func onRegisterState(_ result: iOSRegistrationState_e, expiry: Int32) {
        DispatchQueue.main.async {
            self.regStatusLabel.text = iOSWrapper.sharedInstance().isRegistered() ? "\(USERNAME): Registered" : "Not Registered"
        }
    }
    
    func onCallState(_ callId: String!, callState: iOSCallState_e, contactUrl: String!) {
        DispatchQueue.main.async {
            if callState == IOS_CallState_Confirmed {
                self.currentCallId = callId
            }
        }
    }
}
