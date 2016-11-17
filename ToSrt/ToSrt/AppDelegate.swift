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
        
        // 点击关闭按钮时退出程序
        let closeButton = self.window.standardWindowButton(.closeButton)
        closeButton!.target = self
        closeButton!.action = #selector(closeApplication)
        
    }
    
    // 关闭应用程序
    func closeApplication() {
        NSApplication.shared().terminate(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

