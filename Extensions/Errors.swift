//
//  Errors.swift
//  Extensions
//
//  Created by 戚晓龙 on 2019/7/8.
//  Copyright © 2019 Aron. All rights reserved.
//

import Foundation

enum ExtensionErrors: Swift.Error {
    case invalidSelection
    case unsupportLanguage
    
    var localizedDescription: String {
        switch self {
        case .invalidSelection:
            return "No property definitions found"
        default:
            return "This extension only works with Swift files"
        }
    }
}
