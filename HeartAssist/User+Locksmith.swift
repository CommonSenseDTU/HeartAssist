//
//  User+Locksmith.swift
//  HeartAssist
//
//  Created by Anders Borch on 4/10/17.
//  Copyright © 2017 DTU. All rights reserved.
//

import Foundation
import Musli
import Locksmith

extension Musli.User: GenericPasswordSecureStorable, CreateableSecureStorable, ReadableSecureStorable, DeleteableSecureStorable {

    public var service: String { return "Musli" }
    public var account: String { return userId ?? "" }
    public var signatureDate: String? {
        get {
            return self.signature?.signatureDate
        }
        set(date) {
            /*
             Signature may not be initialized if instance was created by Locksmith
             so we create a signature instance on demand for storing the signature date.
            */
            if self.signature == nil {
                self.signature = Signature()
            }
            self.signature!.signatureDate = date
        }
    }
    
    public static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    public var data: [String: Any] {
        let dateOfBirth = self.dateOfBirth != nil ? User.dateFormatter.string(from: self.dateOfBirth!) : nil
        return [
            "id": id,
            "userId": userId ?? "",
            "password": password ?? "",
            "refresh": refresh ?? "",
            "firstName": firstName ?? "",
            "lastName": lastName ?? "",
            "gender": gender ?? "",
            "dateOfBirth": dateOfBirth ?? "",
            "signatureDate": signatureDate ?? ""
        ]
    }

    public static func removeFromSecure() {
        let user = User()
        user.userId = UserDefaults.standard.value(forKey: "account") as? String
        do {
            try user.deleteFromSecureStore()
        } catch let exception {
            print(exception)
        }
    }
    
    public static func fromSecure() -> User? {
        let user = User()
        user.userId = UserDefaults.standard.value(forKey: "account") as? String
        guard let result = user.readFromSecureStore() else { return nil }
        guard let data = result.data else { return nil }
        if data["id"] is String {
            user.id = data["id"] as! String
        }
        user.password = data["password"] as? String
        user.refresh = data["refresh"] as? String
        user.firstName = data["firstName"] as? String
        user.lastName = data["lastName"] as? String
        user.gender = data["gender"] as? String
        if let date = data["dateOfBirth"] as? String {
            user.dateOfBirth = User.dateFormatter.date(from: date)
        }
        user.signatureDate = data["signatureDate"] as? String
        return user
    }
}
