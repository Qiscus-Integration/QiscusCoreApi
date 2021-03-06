//
//  HTTPMethod.swift
//  QiscusCoreLite
//
//  Created by Qiscus on 18/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

#if os(iOS)
import UIKit
#endif
import Foundation

typealias HTTPHeaders = [String:String]

internal enum HTTPMethod : String {
    case get        = "GET"
    case post       = "POST"
    case put        = "PUT"
    case patch      = "PATCH"
    case delete     = "DELETE"
}

internal enum HTTPTask {
    case request

    case requestParameters(bodyParameters: Parameters?,
        bodyEncoding: ParameterEncoding,
        urlParameters: Parameters?)
    
    case requestParametersAndHeaders(bodyParameters: Parameters?,
        bodyEncoding: ParameterEncoding,
        urlParameters: Parameters?,
        additionHeaders: HTTPHeaders?)
}
