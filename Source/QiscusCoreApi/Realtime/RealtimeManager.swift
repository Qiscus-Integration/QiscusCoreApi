 //
//  RealtimeManager.swift
//  QiscusCore
//
//  Created by Qiscus on 09/08/18.
//

import Foundation
import QiscusRealtime

typealias _roomEvent = (RoomEvent) -> Void
typealias _roomTyping = (RoomTyping) -> Void
 
public class RealtimeManager {
    static var shared : RealtimeManager = RealtimeManager()
    private var client : QiscusRealtime? = nil
    private var pendingSubscribeTopic : [RealtimeSubscribeEndpoint] = [RealtimeSubscribeEndpoint]()
    var state : QiscusRealtimeConnectionState = QiscusRealtimeConnectionState.disconnected
    private var roomEvents : [String : _roomEvent] = [String : _roomEvent]()
    
    private var roomTypings : [String : _roomTyping] = [String : _roomTyping]()
    func setup(appName: String) {
        // make sure realtime client still single object
       // if client != nil { return }
        let bundle = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        var deviceID = "00000000"
        if let vendorIdentifier = UIDevice.current.identifierForVendor {
            deviceID = vendorIdentifier.uuidString
        }
        let clientID = "iosMQTT-\(bundle)-\(deviceID)"
        let config = QiscusRealtimeConfig(appName: appName, clientID: clientID, host: "realtime-jogja.qiscus.com", port: 1885)
        client = QiscusRealtime.init(withConfig: config)
    }
    
    func disconnect() {
        guard let c = client else {
            return
        }
        c.disconnect()
        self.pendingSubscribeTopic.removeAll()
    }
    
    func connect(username: String, password: String) {
        guard let c = client else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.connect(username: username, password: password)
                return
            }
            return
        }
        self.pendingSubscribeTopic.append(.comment(token: password))
        self.pendingSubscribeTopic.append(.notification(token: password))
        
        c.connect(username: username, password: password, delegate: self)
        
    }
    
    /// Subscribe comment(deliverd and read), typing by member in the room, and online status
    ///
    /// - Parameter rooms: array of rooms
    // MARK: TODO optimize, check already subscribe?
    func subscribeRooms(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        for room in rooms {
           
                // subscribe comment deliverd receipt
                if !c.subscribe(endpoint: .delivery(roomID: room.id)){
                    self.pendingSubscribeTopic.append(.delivery(roomID: room.id))
                    QiscusLogger.errorPrint("failed to subscribe event deliver event from room \(room.name), then queue in pending")
                }
                // subscribe comment read
                if !c.subscribe(endpoint: .read(roomID: room.id)) {
                    self.pendingSubscribeTopic.append(.read(roomID: room.id))
                    QiscusLogger.errorPrint("failed to subscribe event read from room \(room.name), then queue in pending")
                }
                if !c.subscribe(endpoint: .typing(roomID: room.id)) {
                    self.pendingSubscribeTopic.append(.typing(roomID: room.id))
                    QiscusLogger.errorPrint("failed to subscribe event typing from room \(room.name), then queue in pending")
                }
                guard let participants = room.participants else { return }
                for u in participants {
                    if !c.subscribe(endpoint: .onlineStatus(user: u.email)) {
                        self.pendingSubscribeTopic.append(.onlineStatus(user: u.email))
                        QiscusLogger.errorPrint("failed to subscribe online status user \(u.email), then queue in pending")
                    }
                }
            
            
           
        }
        
        self.resumePendingSubscribeTopic()
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userId: userId
    func subscribeUserOnlinePresence(userId : String){
        guard let c = client else {
            return
        }
        
        if !c.subscribe(endpoint: .onlineStatus(user: userId)) {
            self.pendingSubscribeTopic.append(.onlineStatus(user: userId))
            QiscusLogger.errorPrint("failed to subscribe online status user \(userId), then queue in pending")
        }
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userIds
    func subscribeUserOnlinePresence(userIds : [String]){
        guard let c = client else {
            return
        }
        
        for userId in userIds {
            if !c.subscribe(endpoint: .onlineStatus(user: userId)) {
                self.pendingSubscribeTopic.append(.onlineStatus(user: userId))
                QiscusLogger.errorPrint("failed to subscribe online status user \(userId), then queue in pending")
            }
        }
    }
    
    func unsubscribeUserOnlinePresence(userId : String){
        guard let c = client else {
            return
        }
        
        c.unsubscribe(endpoint: .onlineStatus(user: userId))
    }
    
    func unsubscribeUserOnlinePresence(userIds : [String]){
        guard let c = client else {
            return
        }
        
        for userId in userIds {
            c.unsubscribe(endpoint: .onlineStatus(user: userId))
        }
    }
    
    /// Subscribe comment(deliverd and read), typing by member in the room, and online status
    ///
    /// - Parameter rooms: array of rooms
    // MARK: TODO optimize, check already subscribe?
    func subscribeRoomsWithoutOnlineStatus(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        for room in rooms {
           
                // subscribe comment deliverd receipt
                if !c.subscribe(endpoint: .delivery(roomID: room.id)){
                    self.pendingSubscribeTopic.append(.delivery(roomID: room.id))
                    QiscusLogger.errorPrint("failed to subscribe event deliver event from room \(room.name), then queue in pending")
                }
                // subscribe comment read
                if !c.subscribe(endpoint: .read(roomID: room.id)) {
                    self.pendingSubscribeTopic.append(.read(roomID: room.id))
                    QiscusLogger.errorPrint("failed to subscribe event read from room \(room.name), then queue in pending")
                }
                if !c.subscribe(endpoint: .typing(roomID: room.id)) {
                    self.pendingSubscribeTopic.append(.typing(roomID: room.id))
                    QiscusLogger.errorPrint("failed to subscribe event typing from room \(room.name), then queue in pending")
                }
            
        }
        
        self.resumePendingSubscribeTopic()
    }
    
    func unsubscribeRooms(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        for room in rooms {
           
                // unsubcribe room event
                c.unsubscribe(endpoint: .delivery(roomID: room.id))
                c.unsubscribe(endpoint: .read(roomID: room.id))
                c.unsubscribe(endpoint: .typing(roomID: room.id))
                guard let participants = room.participants else { return }
                for u in participants {
                    c.unsubscribe(endpoint: .onlineStatus(user: u.email))
                }
            
        }
        
    }
    
    func unsubscribeRoomsWithoutOnlineStatus(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        for room in rooms {
            
                // unsubcribe room event
                c.unsubscribe(endpoint: .delivery(roomID: room.id))
                c.unsubscribe(endpoint: .read(roomID: room.id))
                c.unsubscribe(endpoint: .typing(roomID: room.id))
            
           
        }
        
    }
    

    func isTyping(_ value: Bool, roomID: String){
        guard let c = client else {
            return
        }
        if !c.publish(endpoint: .isTyping(value: value, roomID: roomID)) {
            QiscusLogger.errorPrint("failed to send typing to roomID \(roomID)")
        }
    }
    
    func isOnline(_ value: Bool) {
        guard let c = client else {
            return
        }
        if !c.publish(endpoint: .onlineStatus(value: value)) {
            QiscusLogger.errorPrint("failed to send Online status")
        }
    }
    
    func resumePendingSubscribeTopic() {
        guard let client = client else {
            return
        }
        QiscusLogger.debugPrint("Resume pending subscribe")
        // resume pending subscribe
        if !pendingSubscribeTopic.isEmpty {
            for (i,t) in pendingSubscribeTopic.enumerated().reversed() {
                // check if success subscribe
                if client.subscribe(endpoint: t) {
                    // remove from pending list
                   self.pendingSubscribeTopic.remove(at: i)
                }
            }
        }
        
        QiscusLogger.debugPrint("pendingSubscribeTopic count = \(pendingSubscribeTopic.count)")
    }
    
    // MARK : Typing event
    func subscribeTyping(roomID: String, onTyping: @escaping (RoomTyping) -> Void) {
        guard let c = client else { return }
        
        if c.isConnect{
            if !c.subscribe(endpoint: .typing(roomID: roomID)) {
                self.pendingSubscribeTopic.append(.typing(roomID: roomID))
                QiscusLogger.errorPrint("failed to subscribe event typing from room \(roomID), then queue in pending")
            }else{
                self.roomTypings[roomID] = onTyping
            }
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.subscribeTyping(roomID: roomID) { (roomTyping) in
                    self.roomTypings[roomID] = onTyping
                }
            }
            
        }
    }
    
    func unsubscribeTyping(roomID: String) {
        roomTypings.removeValue(forKey: roomID)
        guard let c = client else {
            return
        }
        // unsubcribe room event
        c.unsubscribe(endpoint: .typing(roomID: roomID))
    }
    
    // MARK : Custom Event
    func subscribeEvent(roomID: String, onEvent: @escaping (RoomEvent) -> Void) {
        guard let c = client else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.subscribeEvent(roomID: roomID, onEvent: onEvent)
                return
            }
            return
        }
        
        if c.isConnect{
            // subcribe user token to get new comment
            if !c.subscribe(endpoint: .roomEvent(roomID: roomID)) {
                self.pendingSubscribeTopic.append(.roomEvent(roomID: roomID))
                QiscusLogger.errorPrint("failed to subscribe room Event, then queue in pending")
            }else {
                self.roomEvents[roomID] = onEvent
            }
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.subscribeEvent(roomID: roomID, onEvent: { (roomEvent) in
                    self.roomEvents[roomID] = onEvent
                })
            }
        }
    }
    
    func unsubscribeEvent(roomID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.roomEvents.count == 0 {
                return
            }
            
            guard let c = self.client else {
                return
            }
            
            if self.roomEvents.removeValue(forKey: roomID) != nil{
                // unsubcribe room event
                c.unsubscribe(endpoint: .roomEvent(roomID: roomID))
            }
        }
    }
    
    // util
    func toDictionary(text : String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("error parsing \(error.localizedDescription)")
            }
        }
        return nil
    }
}

 extension RealtimeManager: QiscusRealtimeDelegate {
    public func didReceiveRoomEvent(roomID: String, data: String) {
        guard let payload = toDictionary(text: data) else { return }
        guard let postEvent = roomEvents[roomID] else { return }
        let event = RoomEvent(sender: payload["sender"] as? String ?? "", data: payload["data"] as? [String : Any] ?? ["":""])
        postEvent(event)
    }
    
    public func didReceiveUser(userEmail: String, isOnline: Bool, timestamp: String) {
        // TODO: Pass this online status event to client app
    }

    public func didReceiveMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String) {
        self.updateMessageStatus(roomId: roomId, commentId: commentId, commentUniqueId: commentUniqueId, Status: Status, userEmail: userEmail, sourceMqtt: true)
    }
    
    func updateMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String, sourceMqtt: Bool = true) {
        switch Status {
        case .deleted:
            // TODO: pass this delete event to client
            break
        case .delivered:
            // TODO: pass this deliver event to client
            break
        case .read:
            // TODO: pass this read event to client
            break
        }
    }
    
    public func didReceiveMessage(data: String) {
        let json = ApiResponse.decode(string: data)
        let comment = CommentModel(json: json)
        
        
    }
    
    public func didReceiveUser(typing: Bool, roomId: String, userEmail: String) {
        // TODO: pass this typing status event to client app
        
    }
    
    public func connectionState(change state: QiscusRealtimeConnectionState) {
        print("::connection state \(state)")
        // TODO: handle connection state later
    }
    
    
    public func disconnect(withError err: Error?){
        print("::disconnected \(err)")
        // TODO: handle disconnect event later
    }

}
