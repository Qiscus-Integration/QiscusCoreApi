//
//  QiscusChatSDK.swift
//  QiscusChatSDK
//
//  Created by asharijuang on 27/01/20.
//  Copyright © 2020 qiscus. All rights reserved.
//

import Foundation

let VERSION_NUMBER = "0.2.1"

public class QiscusCoreAPI {
    
    static var bundle:Bundle{
        get{
            let podBundle = Bundle(for: QiscusCoreAPI.self)
            
            if let bundleURL = podBundle.url(forResource: "SDK", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    public private(set) var config : QiscusConfig!
    private var network : NetworkManager!
    static var enableDebugPrint: Bool = false
    
    /// Logined
    public var isLogined : Bool {
        return self.userProfile != nil
    }
    
    /// Can't set to nil
    public private(set) var userProfile : UserModel? {
        set {
            if let user = newValue {
                user.save(appID: self.config.appId)
            }
        }
        get {
            var user = UserModel.init()
            user.loadUserProfile(appID: self.config.appId)
            return user.token.isEmpty ? nil : user
        }
    }
    
    public init(withAppId id: String, server: QiscusServer? = nil) {
        let defaultURL = URL(string: "https://api.qiscus.com")!
        self.network = NetworkManager(core: self)
        
        let defaultServer = QiscusServer(url: defaultURL, realtimeURL: "", realtimePort: 80)
        self.config = QiscusConfig(appId: id, server: defaultServer)
        if let _server = server {
            self.config.server = _server
        }
    }
}

extension QiscusCoreAPI : CoreCommand {
    public func register(deviceToken: String, isDevelopment: Bool, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        network.registerDeviceToken(deviceToken: deviceToken, isDevelopment: isDevelopment, onSuccess: onSuccess, onError: onError)
    }
    
    public func signOut() {
        if let user = self.userProfile {
            user.clear(appID: self.config.appId)
        }else { print("User no logined")}
    }
    
    /// Login with Nonce or Idendity token
    /// - Parameters:
    ///   - token: Identity token
    ///   - onSuccess: success login
    ///   - onError: error login
    public func setUserWithIdentityToken(token: String, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        network.login(identityToken: token, onSuccess: { (user) in
            // save user profile
            self.userProfile = user
            // return success
            onSuccess(user)
        }, onError: onError)
    }
    
    // MARK: Auth
    /// Get JWTNonce from SDK server. use when login with JWT
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    public func getJWTNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void) {
        network.getNonce(onSuccess: onSuccess, onError: onError)
    }
}

extension QiscusCoreAPI : RoomCommand {
    /// User Rooms, support pagination
    ///
    /// - Parameters:
    ///   - showParticipant: Bool (true = include participants obj to the room, false = participants obj nil)
    ///   - limit: limit room per page
    ///   - page: page
    ///   - roomType: (single, group, public_channel) by default returning all type
    ///   - showRemoved: Bool (true = include room that has been removed, false = exclude room that has been removed)
    ///   - showEmpty: Bool (true = it will show all rooms that have been created event there are no messages, default is false where only room that have at least one message will be shown)
    ///   - onSuccess: response success
    ///   - onError: response error
    public func userRooms(showParticipant: Bool, limit: Int, page: Int, roomType: RoomType, showRemoved: Bool, showEmpty: Bool, onSuccess: @escaping ([RoomModel], Meta) -> Void, onError: @escaping (QError) -> Void) {
        network.getRoomList(showParticipant: showParticipant, limit: limit, page: page, roomType: roomType, showRemoved: showRemoved, showEmpty: showEmpty) { (rooms, meta, errorMessage) in
            if let _rooms = rooms, let _meta = meta {
                onSuccess(_rooms, _meta)
            }else {
                if let _error = errorMessage {
                    onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
            
        }
    }
    
    /// Get Object Room by id
    /// - Parameters:
    ///   - id: room id, not unique id
    ///   - onSuccess: response success
    ///   - onError: response error
    public func getChatRoom(id: String, onSuccess: @escaping (RoomModel, [CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        network.getRoomById(roomId: id, onSuccess: { (room, comments) in
            if let messages = comments {
                onSuccess(room, messages)
            }else {
                onSuccess(room, [CommentModel]())
            }
        }, onError: onError)
    }
}

extension QiscusCoreAPI : MessageCommand {
    /// Load Previous message
    /// - Parameters:
    ///   - message: your last/old message
    ///   - limit: number of limit message per request
    ///   - onSuccess: response success
    ///   - onError: response error
    public func loadMore(lastMessage message: CommentModel, limit: Int, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        network.loadComments(roomId: message.roomId, lastCommentId: Int(message.id) ?? 0, after: false, limit: limit) { (comments, error) in
            if let _comments = comments {
                onSuccess(_comments)
            }else {
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// Delete Message
    /// - Parameters:
    ///   - message: object message to be delete
    ///   - onSuccess: response success
    ///   - onError: response error
    public func delete(message: CommentModel, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void) {
        
        network.deleteComment(commentUniqueId: [message.uniqId]) { (comments, error) in
            if let _comments = comments, let _comment = _comments.first {
                onSuccess(_comment)
            }else {
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    
    /// Long Polling system to get new message
    /// - Parameters:
    ///   - lastMessageId: last message id
    ///   - onSuccess: response array of message when request success
    ///   - onError: response error
    public func sync(lastMessageId: String, onSuccess: @escaping ([CommentModel])->Void, onError: @escaping (QError) -> Void) {
        network.sync(lastCommentReceivedId: lastMessageId) { (comments, error) in
            if let messages = comments {
                onSuccess(messages)
            }else {
                if let errorMessage = error {
                    onError(QError(message: errorMessage))
                }else {
                    onError(QError(message: "New Message Unavailable"))
                }
            }
        }
    }
    
    /// Generate new message
    public func newMessage() -> CommentModel {
        guard let user = self.userProfile else {
            fatalError("Need to login")
        }
        return CommentModel(user: user)
    }
    
    /// Mark as read, to other patricipant
    /// - Parameter message: object message
    public func markAsRead(message: CommentModel) {
        // In this case everytime you receive message, that's mead you read this message
        network.updateCommentStatus(roomId: message.roomId, lastCommentReadId: message.id, lastCommentReceivedId: message.id)
    }
    
    /// Send Message
    /// - Parameters:
    ///   - message: Object message, you can generate by using newMessage
    ///   - onSuccess: response success
    ///   - onError: response error
    public func send(message: CommentModel, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void) {
        // update comment
        let _comment            = message
        _comment.roomId         = message.roomId
        _comment.status         = .sending
        _comment.timestamp      = CommentModel.getTimestamp()
        // check comment type, if not Qiscus Comment set as custom type
        if !_comment.isQiscustype() {
            let _payload    = _comment.payload
            let _type       = _comment.type
            _comment.type = "custom"
            _comment.payload?.removeAll() // clear last payload then recreate
            _comment.payload = ["type" : _type]
            if let payload = _payload {
                _comment.payload!["content"] = payload
            }else {
                _comment.payload!["content"] = ["":""]
            }
        }
        
        network.postComment(roomId: _comment.roomId, type: _comment.type, message: _comment.message, payload: _comment.payload, extras: _comment.extras, uniqueTempId: _comment.uniqId) { (data, error) in
            
            if let errorMessage = error {
                onError(QError(message: errorMessage))
            }else {
                if let newMessage = data {
                    onSuccess(newMessage)
                }else {
                    onError(QError(message: "Failed to send message"))
                }
            }
            
        }
    }
}
