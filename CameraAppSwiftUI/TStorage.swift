//
//  TStorage.swift
//  CameraAppSwiftUI
//
//  Created by MacBook Air M1 on 25/11/25.
//

import Foundation


struct TStorage {
    private enum Keys {
        static let shouldRated = "shouldRated"
    }
    
    static var shouldRated: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.shouldRated)
            UserDefaults.standard.synchronize()
        }
        get {
            let wordlaring =  UserDefaults.standard.integer(forKey: Keys.shouldRated)
            return wordlaring
        }
    }
}
