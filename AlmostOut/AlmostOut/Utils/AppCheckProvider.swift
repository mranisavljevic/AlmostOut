//
//  AppCheckProvider.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import Firebase
import FirebaseAppCheck

class AlmostOutAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    return AppAttestProvider(app: app)
  }
}
