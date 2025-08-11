//
//  NotificationServiceProtocol.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation
import CoreLocation

protocol NotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func updateFCMToken() async throws
    func scheduleLocationReminder(for items: [ListItem], at coordinate: CLLocationCoordinate2D) throws
}
