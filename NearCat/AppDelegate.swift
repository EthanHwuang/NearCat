//
//  AppDelegate.swift
//  NearCat
//
//  Created by huchunbo on 15/12/23.
//  Copyright © 2015年 Bijiabo. All rights reserved.
//

import UIKit
import FServiceManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var status: FStatus!
    
    let productionMode: Bool = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        status = FStatus()
        
        window?.backgroundColor = UIColor.whiteColor()
        FConfiguration.sharedInstance.host = productionMode ? "http://near.cat/" : "http://192.168.31.200:3000/"
        
        let userNotificationSettings = UIUserNotificationSettings(
            forTypes: [.Alert, .Badge, .Sound],
            categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(userNotificationSettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        Helper.Notification.setupCustomStyle()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // get token string
        let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
        var deviceTokenString = ""
        for var i = 0; i < deviceToken.length; i++ {
            deviceTokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        // save device token string
        FHelper.deviceToken = deviceTokenString
        // send device token string to backend
        _sendProviderDeviceToken(deviceTokenString)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("application did failed to register remote notification.")
        print(error)
    }
    
    private func _sendProviderDeviceToken(token: String) {
        Action.remoteNotificationTokens.create(token: token)
    }

    
}

