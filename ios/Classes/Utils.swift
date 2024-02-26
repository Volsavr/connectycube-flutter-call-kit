//
//  Utils.swift
//


import Foundation
import CommonCrypto

public class Utils {

    // MARK: sha256

    public class func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }

    // MARK: md5

    public class func md5(string: String) -> Data {
        let data = string.data(using: .utf8)!
        var hash = [UInt8](repeating: 0,  count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }

    // MARK: uuid

    public class func uuid(string: String) -> UUID {
        if string.isEmpty {
            return UUID()
        }

        let data = Utils.md5(string: string)
        var str = data.reduce("", {$0 + String(format: "%02X", $1)})

        // format string: NNNNNNNN-NNNN-NNNN-NNNN-NNNNNNNNNNNN
        var index = str.startIndex
        index = str.index(index, offsetBy: 8)
        str.insert("-", at: index)
        index = str.index(index, offsetBy: 5)
        str.insert("-", at: index)
        index = str.index(index, offsetBy: 5)
        str.insert("-", at: index)
        index = str.index(index, offsetBy: 5)
        str.insert("-", at: index)

        return UUID(uuidString: str) ?? UUID()
    }

}

