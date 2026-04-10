import Foundation
import CryptoKit
import AppKit

class OTPGenerator {
    
    static func generateTOTP(secret: String) -> String {
        let time = Int(Date().timeIntervalSince1970) / 30
        let code = (time % 1000000).description
        let sixDigitCode = String(repeating: "0", count: max(0, 6 - code.count)) + code
        return String(sixDigitCode.suffix(6))
    }
    
    static func sendCodeToEmail(email: String, code: String) {
        print("📧 Код для \(email): \(code)")
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Код подтверждения"
            alert.informativeText = "Ваш код: \(code)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
