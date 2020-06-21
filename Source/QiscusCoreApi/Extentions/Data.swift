//
//  Data.swift
//  QiscusCoreLite
//
//  Created by asharijuang on 28/01/20.
//

import Foundation

extension Data {
    func toJsonString() -> String {
        guard let jsonString = String(data: self, encoding: .utf8) else {return "invalid json data"}
        
        return jsonString
    }
}
