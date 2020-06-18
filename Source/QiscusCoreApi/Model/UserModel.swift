//
//  Auth.swift
//  QiscusCoreLite
//
//  Created by Qiscus on 19/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import SwiftyJSON
import Foundation

public enum SortType: String {
    case asc = "asc"
    case desc = "desc"
}

public struct UserModel {
    public var avatarUrl        : URL       = URL(string: "http://")!
    public var email            : String    = ""
    public var id               : String    = ""
    public var rtKey            : String    = ""
    public var token            : String    = ""
    public var username         : String    = ""
    public var extras           : String    = ""
    
    init() { }
    
    init(json: JSON) {
        avatarUrl       = json["avatar_url"].url ?? URL(string: "http://")!
        email           = json["email"].stringValue
        id              = json["id_str"].stringValue
        rtKey           = json["rtKey"].stringValue
        token           = json["token"].stringValue
        username        = json["username"].stringValue
        extras          = json["extras"].rawString() ?? ""
    }
}

extension UserModel {
    private func filename(id: String, name: String) -> String {
        return "\(id.reversed())_\(name)"
    }
    
    internal func save(appID: String) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(self.id, forKey: filename(id: appID, name: "id"))
        defaults.set(self.username, forKey: filename(id: appID, name: "username"))
        defaults.set(self.email, forKey: filename(id: appID, name: "email"))
        defaults.set(self.token, forKey: filename(id: appID, name: "token"))
        defaults.set(self.rtKey, forKey: filename(id: appID, name: "rtKey"))
        defaults.set(self.avatarUrl, forKey: filename(id: appID, name: "avatarUrl"))
        defaults.set(self.extras, forKey: filename(id: appID, name: "extras"))
    }
        
    mutating func loadUserProfile(appID: String) {
        // save in cache
        let storage = UserDefaults.standard
        self.token      = storage.string(forKey: filename(id: appID, name: "token")) ?? ""
        self.id         = storage.string(forKey: filename(id: appID, name: "id")) ?? ""
        self.email      = storage.string(forKey: filename(id: appID, name: "email")) ?? ""
        self.username   = storage.string(forKey: filename(id: appID, name: "username")) ?? ""
        self.extras     = storage.string(forKey: filename(id: appID, name: "extras")) ?? ""
        self.avatarUrl  = storage.url(forKey: filename(id: appID, name: "avatarUrl")) ?? URL(string: "http://")!
    }
    
    internal func clear(appID: String) {
        // remove file user
        let storage = UserDefaults.standard
        storage.removeObject(forKey: filename(id: appID, name: "id"))
        storage.removeObject(forKey: filename(id: appID, name: "token"))
        storage.removeObject(forKey: filename(id: appID, name: "username"))
        storage.removeObject(forKey: filename(id: appID, name: "email"))
        storage.removeObject(forKey: filename(id: appID, name: "rtKey"))
        storage.removeObject(forKey: filename(id: appID, name: "avatarUrl"))
        storage.removeObject(forKey: filename(id: appID, name: "syncEventId"))
        storage.removeObject(forKey: filename(id: appID, name: "syncId"))
        storage.removeObject(forKey: filename(id: appID, name: "isConnectedMQTT"))
        storage.removeObject(forKey: filename(id: appID, name: "extras"))
        storage.removeObject(forKey: filename(id: appID, name: "customHeader"))
        storage.removeObject(forKey: filename(id: appID, name: "deviceToken"))
    }
}

open class MemberModel {
    public var avatarUrl : URL? = nil
    public var email : String   = ""
    public var id : String      = ""
    public var lastCommentReadId : Int  = -1
    public var lastCommentReceivedId : Int  = -1
    public var username : String    = ""
    private let userKey = "CoreMemKey_"
    
    init() { }
    
    init(json: JSON) {
        self.id         = json["email"].stringValue
        self.username   = json["username"].stringValue
        self.avatarUrl  = json["avatar_url"].url ?? nil
        self.email      = json["email"].stringValue
        self.lastCommentReadId      = json["last_comment_read_id"].intValue
        self.lastCommentReceivedId  = json["last_comment_received_id"].intValue
    }
}

extension MemberModel {
    internal func saveLastOnline(_ time: Date) {
        let db = UserDefaults.standard
        db.set(time, forKey: self.userKey + "lastSeen")
    }
    
    func lastSeen() -> Date? {
        let db = UserDefaults.standard
        return db.object(forKey: self.userKey + "lastSeen") as? Date
        // MARK: TODO get alternative when null
    }
}
