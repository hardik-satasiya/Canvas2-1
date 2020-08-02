//
//  ViewController.swift
//  Canvas2Demo
//
//  Created by scchn on 2020/7/31.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa
import Canvas2

class ViewController: NSViewController {

    @IBOutlet weak var shapeTableView: NSTableView!
    @IBOutlet weak var pointStyleListButton: NSPopUpButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var closeSwitch: NSButton!
    @IBOutlet weak var selectableSwitch: NSButton!
    @IBOutlet weak var rotationSwitch: NSButton!
    @IBOutlet weak var magnetSwitch: NSButton!
    @IBOutlet weak var canvasView: CanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shapeTableView.delegate = self
        shapeTableView.dataSource = self
        shapeTableView.doubleAction = #selector(makeShape(_:))
        
        pointStyleListButton.removeAllItems()
        pointStyleListButton.addItems(withTitles: CanvasView.PointStyle.allCases.map(String.init))
        pointStyleListButton.selectItem(at: canvasView.pointStyle.rawValue)
        
        colorWell.color = canvasView.strokeColor
        
        canvasView.wantsLayer = true
        canvasView.layer?.cornerRadius = 4
        canvasView.layer?.borderWidth = 1
        canvasView.layer?.backgroundColor = NSColor.white.cgColor
        canvasView.delegate = self
        
        updateUI()
    }
    
    func updateUI() {
        removeButton.isEnabled = !canvasView.selectedItems.isEmpty
        selectableSwitch.state = canvasView.isSelectable ? .on : .off
        rotationSwitch.state = canvasView.isRotationEnabled ? .on : .off
        magnetSwitch.state = canvasView.isMagnetEnabled ? .on : .off
        colorWell.color = canvasView.singleSelection?.strokeColor ?? canvasView.strokeColor
        
        if let polygon = (canvasView.singleSelection ?? canvasView.currentItem) as? PolygonShape {
            closeSwitch.state = polygon.isClosed ? .on : .off
            closeSwitch.isHidden = false
        } else {
            closeSwitch.isHidden = true
        }
    }
    
    @objc func makeShape(_ sender: NSTableView) {
        guard sender.selectedRow != -1 else { return }
        let shape = ShapeList.allCases[sender.selectedRow]
        canvasView.startSession(shape.convert())
        sender.deselectAll(nil)
        updateUI()
    }

    @IBAction func pointStyleListButtonAction(_ sender: NSPopUpButton) {
        guard let st = CanvasView.PointStyle(rawValue: sender.indexOfSelectedItem) else {
            return
        }
        canvasView.pointStyle = st
    }
    
    @IBAction func cursorButtonAction(_ sender: Any) {
        canvasView.finishSession()
        canvasView.deselectAllItems()
    }
    
    @IBAction func removeButtonAction(_ sender: Any) {
        canvasView.removeSelectedItems()
    }
    
    @IBAction func colorWellAction(_ sender: NSColorWell) {
        let color = sender.color
        canvasView.strokeColor = color
        canvasView.currentItem?.strokeColor = color
        canvasView.selectedItems.forEach { $0.strokeColor = color }
    }
    
    @IBAction func closeSwitchAction(_ sender: NSButton) {
        guard let polygon = (canvasView.singleSelection ?? canvasView.currentItem) as? PolygonShape else {
            return
        }
        polygon.isClosed = sender.state == .on
    }
    
    @IBAction func selectableSwitchAction(_ sender: NSButton) {
        canvasView.isSelectable = sender.state == .on
    }
    
    @IBAction func rotationSwitchAction(_ sender: NSButton) {
        canvasView.isRotationEnabled = sender.state == .on
    }
    
    @IBAction func magnetSwitchAction(_ sender: NSButton) {
        canvasView.isMagnetEnabled = sender.state == .on
    }
    
    var mouseLocation: CGPoint = .zero
    
}

extension ViewController: CanvasViewDelegate {
    
    func canvasView(_ canvasView: CanvasView, didFinishSession item: Shape) {
        updateUI()
    }
    
    func canvasView(_ canvasView: CanvasView, didSelect items: [Shape]) {
        updateUI()
    }
    
    func canvasView(_ canvasView: CanvasView, didDeselect items: [Shape]) {
        updateUI()
    }
    
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int { ShapeList.allCases.count }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: .shapeCell, owner: nil)
        if let cellView = view as? NSTableCellView {
            let shape = ShapeList.allCases[row]
            cellView.textField?.stringValue = "\(shape)"
        }
        return view
    }
    
}

extension NSUserInterfaceItemIdentifier {
    static let shapeCell = NSUserInterfaceItemIdentifier("ShapeCell")
}
