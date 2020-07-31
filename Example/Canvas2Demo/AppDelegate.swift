//
//  AppDelegate.swift
//  Canvas2Demo
//
//  Created by scchn on 2020/7/31.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa
import Canvas2

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var app: NSApplication!
    
    var canvasView: CanvasView? {
        (app.mainWindow?.contentViewController as? ViewController)?.canvasView
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    @IBAction func selectAll(_ sender: Any) {
        canvasView?.selectAllItems()
    }
    
}

