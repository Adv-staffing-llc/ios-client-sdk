//
//  EnvironmentReporter.swift
//  Darkly
//
//  Created by Mark Pokorny on 3/27/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#endif

enum OperatingSystem: String {
    case iOS, watchOS, macOS   //TODO: when adding tv support, add case

    static var allOperatingSystems: [OperatingSystem] { return [.iOS, .watchOS, .macOS] }
    
    var isBackgroundEnabled: Bool { return OperatingSystem.backgroundEnabledOperatingSystems.contains(self) }
    static var backgroundEnabledOperatingSystems: [OperatingSystem] { return [.macOS] }
    static var backgroundDisabledOperatingSystems: [OperatingSystem] { return [.iOS, .watchOS] }

    var isStreamingEnabled: Bool { return OperatingSystem.streamingEnabledOperatingSystems.contains(self) }
    static var streamingEnabledOperatingSystems: [OperatingSystem] { return [.iOS, .macOS] }
    static var streamingDisabledOperatingSystems: [OperatingSystem] { return [.watchOS] }

}

//sourcery: AutoMockable
protocol EnvironmentReporting {
    //sourcery: DefaultMockValue = true
    var isDebugBuild: Bool { get }
    //sourcery: DefaultMockValue = Constants.deviceModel
    var deviceModel: String { get }
    //sourcery: DefaultMockValue = Constants.systemVersion
    var systemVersion: String { get }
    //sourcery: DefaultMockValue = Constants.systemName
    var systemName: String { get }
    //sourcery: DefaultMockValue = .iOS
    var operatingSystem: OperatingSystem { get }
    //sourcery: DefaultMockValue = .UIApplicationDidEnterBackground
    var backgroundNotification: Notification.Name? { get }
    //sourcery: DefaultMockValue = .UIApplicationWillEnterForeground
    var foregroundNotification: Notification.Name? { get }
    //sourcery: DefaultMockValue = Constants.vendorUUID
    var vendorUUID: String? { get }
}

struct EnvironmentReporter: EnvironmentReporting {
    #if DEBUG
    var isDebugBuild: Bool { return true }
    #else
    var isDebugBuild: Bool { return false }
    #endif

    #if os(iOS)
    var deviceModel: String { return UIDevice.current.model }
    var systemVersion: String { return UIDevice.current.systemVersion }
    var systemName: String { return UIDevice.current.systemName }
    var operatingSystem: OperatingSystem { return .iOS }
    var backgroundNotification: Notification.Name? { return .UIApplicationDidEnterBackground }
    var foregroundNotification: Notification.Name? { return .UIApplicationWillEnterForeground }
    var vendorUUID: String? { return UIDevice.current.identifierForVendor?.uuidString }
    #elseif os(watchOS)
    var deviceModel: String { return WKInterfaceDevice.current().model }
    var systemVersion: String { return WKInterfaceDevice.current().systemVersion }
    var systemName: String { return WKInterfaceDevice.current().systemName }
    var operatingSystem: OperatingSystem { return .watchOS }
    var backgroundNotification: Notification.Name? { return nil }
    var foregroundNotification: Notification.Name? { return nil }
    var vendorUUID: String? { return nil }
    #elseif os(OSX)
    var deviceModel: String { return Sysctl.modelWithoutVersion }
    var systemVersion: String { return ProcessInfo.processInfo.operatingSystemVersion.compactVersionString }
    var systemName: String { return "macOS" }
    var operatingSystem: OperatingSystem { return .macOS }
    var backgroundNotification: Notification.Name? { return NSApplication.willResignActiveNotification }
    var foregroundNotification: Notification.Name? { return NSApplication.didBecomeActiveNotification }
    var vendorUUID: String? { return nil }
    #endif
    //TODO: when adding tv support, add case
//    var vendorUUID: String? { return UIDevice.current.identifierForVendor?.uuidString }   //TODO: this should be in the tvOS case too
}

#if os(OSX)
extension OperatingSystemVersion {
    var compactVersionString: String { return "\(majorVersion).\(minorVersion).\(patchVersion)" }
}

extension Sysctl {
    static var modelWithoutVersion: String {
        //swiftlint:disable:next force_try
        let modelRegex = try! NSRegularExpression(pattern: "([A-Za-z]+)\\d{1,2},\\d")
        let model = Sysctl.model    //e.g. "MacPro4,1"
        return modelRegex.firstCaptureGroup(in: model, options: [], range: model.range) ?? "mac"
    }
}

private extension String {
    func substring(_ range: NSRange) -> String? {
        guard range.location >= 0 && range.location < self.count,
            range.location + range.length >= 0 && range.location + range.length < self.count
            else { return nil }
        let startIndex = index(self.startIndex, offsetBy: range.location)
        let endIndex = index(self.startIndex, offsetBy: range.length)
        return String(self[startIndex..<endIndex])
    }

    var range: NSRange { return NSRange(location: 0, length: self.count) }
}

private extension NSRegularExpression {
    func firstCaptureGroup(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> String? {
        guard let match = self.firstMatch(in: string, options: [], range: string.range),
            let group = string.substring(match.range(at: 1))
            else { return nil }
        return group
    }
}
#endif
