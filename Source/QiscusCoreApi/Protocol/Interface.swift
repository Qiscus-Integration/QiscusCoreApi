//
//  Interface.swift
//  Pods
//
//  Created by asharijuang on 05/02/20.
//

import Foundation

/// General Config and Auth
protocol CoreCommand {
    func getJWTNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void)
    func setUserWithIdentityToken(token: String, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void)
    func register(deviceToken token: String, isDevelopment: Bool, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void)
    func signOut()
}

protocol RoomCommand {
    func getChatRoom(id: String, onSuccess: @escaping (RoomModel, [CommentModel]) -> Void, onError: @escaping (QError) -> Void)
    func userRooms(showParticipant: Bool , limit: Int, page: Int, roomType: RoomType, showRemoved: Bool, showEmpty: Bool, onSuccess: @escaping ([RoomModel], Meta) -> Void, onError: @escaping (QError) -> Void)
}

protocol MessageCommand {
    func loadMore(lastMessage message: CommentModel, limit: Int, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void)
    func send(message: CommentModel, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void)
    func markAsRead(message: CommentModel)
    func newMessage() -> CommentModel
    func delete(message: CommentModel, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void)
}
