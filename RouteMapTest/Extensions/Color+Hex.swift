//
//  Color+Hex.swift
//  RouteMapTest
//
//  Created by Chris Sanders on 10/26/20.
//

import SwiftUI

extension Color {
    static let lightInvertedBlue = Color(red:0.33, green:0.78, blue:1.00)
    static let linkBlue = Color(red:0.25, green:0.51, blue:0.77)
    static let defaultGray = Color(red: 118 / 255, green: 118 / 255, blue: 118 / 255)
    
    static let goodService = Color(red: 46 / 255, green: 204 / 255, blue: 64 / 255)
    static let notGoodService = Color(red: 255 / 255, green: 226 / 255, blue: 33 / 255)
    static let delayedService = Color(red: 255 / 255, green: 105 / 255, blue: 94 / 255)
    static let serviceChange = Color(red: 255 / 255, green: 133 / 255, blue: 27 / 255)
    static let noService = Color(red: 0.0, green: 0.0, blue: 0.0)
    
    init(hex: String) {
        let r, g, b, o: Double
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = Double((hexNumber & 0xff000000) >> 24) / 255
                    g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                    b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                    o = Double(hexNumber & 0x000000ff) / 255

                    self.init(.sRGB, red: r, green: g, blue: b, opacity: o)
                } else {
                    self = Color.defaultGray
                }
            } else {
                self = Color.defaultGray
            }
        } else {
            self = Color.defaultGray
        }
    }
    
    static func createColor(from hex: String) -> Color {
        var hexString = ""
        if !hex.isEmpty {
            hexString = hex + "ff"
            return Color(hex: hexString)
        }
        return Color(red: 118 / 255, green: 118 / 255, blue: 118 / 255)
    }
}
