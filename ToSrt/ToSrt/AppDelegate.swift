//
//  AppDelegate.swift
//  ToSrt
//
//  Created by Cao Zheng on 2016/11/14.
//  Copyright © 2016年 Cao Zheng. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let mainVC = MainViewController();

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 添加主界面到window的view中
        self.window.contentView?.addSubview(self.mainVC.view);
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

