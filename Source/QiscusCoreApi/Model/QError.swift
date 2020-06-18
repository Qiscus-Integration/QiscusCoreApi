//
//  QError.swift
//  QiscusCoreLite
//
//  Created by Qiscus on 27/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

#if os(iOS)
import UIKit
#endif

public class QError {
    public var message : String = ""
    
    init(message: String) {
        self.message = message
    }
    
}
