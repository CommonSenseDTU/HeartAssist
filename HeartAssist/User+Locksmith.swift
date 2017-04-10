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
            self.signature?.signatureDate = date
        }
    }
    
    public var data: [String: Any] {
        return [
            "id": id,
            "userId": userId ?? "",
            "password": password ?? "",
            "firstName": firstName ?? "",
            "lastName": lastName ?? "",
            "gender": gender ?? "",
            "dateOfBirth": dateOfBirth ?? "",
            "signatureDate": signatureDate ?? ""
        ]
    }
}
