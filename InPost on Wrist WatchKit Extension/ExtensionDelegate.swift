//
//  ExtensionDelegate.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 26/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import Alamofire
import AlamofireNetworkActivityLogger
import SwiftyBeaver

let log = SwiftyBeaver.self
let logFile: URL? = {
    guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        return nil
    }

    let dateFromatter: DateFormatter = {
        $0.dateFormat = "yyyy_MM_dd__HH_mm_ss"

        return $0
    }(DateFormatter())

    return url.appendingPathComponent("swiftybeaver_\(dateFromatter.string(from: Date())).log", isDirectory: false)
}()

let afSession: Session = {
    let manager = ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: ["api-inmobile-pl.easypack24.net" : DisabledTrustEvaluator()])
    return Session(serverTrustManager: manager)
}()

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let appCoordinator = AppCoordinator()

    func applicationDidFinishLaunching() {
        NetworkActivityLogger.shared.startLogging()
        let console = ConsoleDestination()
        let file = FileDestination(logFileURL: logFile)

        console.format = "$DHH:mm:ss$d $L\n\t$n:$l\n\t\t$M"
        file.format = "$DHH:mm:ss$d $L\n\t$n:$l\n\t\t$M"

        log.addDestination(console)
        log.addDestination(file)

        NetworkCollectParcelService().validateParcel(shipmentNumber: "123123", openCode: "345345", location: CLLocation(latitude: 12, longitude: 12),
                                                     completion: { _ in })

        appCoordinator.start()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
