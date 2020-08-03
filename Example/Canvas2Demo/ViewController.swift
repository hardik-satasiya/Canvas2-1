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
    
    let loader = ShapeLoader()

    @IBOutlet weak var shapeTableView: NSTableView!
    // Toolbar
    @IBOutlet weak var removeButton: NSButton!
    // Canvas
    @IBOutlet weak var canvasView: CanvasView!
    // Settings
    @IBOutlet weak var pointStyleListButton: NSPopUpButton!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var selectableSwitch: NSButton!
    @IBOutlet weak var rotationSwitch: NSButton!
    @IBOutlet weak var magnetSwitch: NSButton!
    @IBOutlet weak var closeSwitch: NSButton!
    
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
        canvasView.backgroundColor = .white
        canvasView.delegate = self
        
        loadSavedShapes()
        updateUI()
    }
    
    func showAlert(title: String, message: String, icon: NSImage? = nil) {
        if let window = view.window {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.icon = icon
            alert.beginSheetModal(for: window)
        }
    }
    
    func loadSavedShapes() {
        do {
            canvasView.addItems(try loader.load())
        } catch {
            showAlert(title: "Load shapes failed", message: error.localizedDescription, icon: #imageLiteral(resourceName: "Failure"))
        }
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
    
    // MARK: - UI Actions
    
    @objc func makeShape(_ sender: NSTableView) {
        guard sender.selectedRow != -1 else { return }
        let shape = ShapeList.allCases[sender.selectedRow]
        canvasView.startSession(shape.shapeType())
        sender.deselectAll(nil)
        updateUI()
    }
    
    @IBAction func cursorButtonAction(_ sender: Any) {
        canvasView.finishSession()
        canvasView.deselectAllItems()
    }
    
    @IBAction func removeButtonAction(_ sender: Any) {
        canvasView.removeSelectedItems()
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        do {
            try loader.save(canvasView.items)
        } catch {
            showAlert(title: "Error", message: error.localizedDescription, icon: #imageLiteral(resourceName: "Failure"))
        }
    }
    
    @IBAction func pointStyleListButtonAction(_ sender: NSPopUpButton) {
        guard let st = CanvasView.PointStyle(rawValue: sender.indexOfSelectedItem) else {
            return
        }
        canvasView.pointStyle = st
    }
    
    @IBAction func colorWellAction(_ sender: NSColorWell) {
        let color = sender.color
        canvasView.strokeColor = color
        canvasView.currentItem?.strokeColor = color
        canvasView.selectedItems.forEach { $0.strokeColor = color }
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
    
    @IBAction func closeSwitchAction(_ sender: NSButton) {
        guard let polygon = (canvasView.singleSelection ?? canvasView.currentItem) as? PolygonShape
            else { return }
        polygon.isClosed = sender.state == .on
    }
    
}

extension ViewController: CanvasViewDelegate {
    
    func canvasView(_ canvasView: CanvasView, didFinishSession item: Shape) {
        updateUI()
    }
    
    func canvasViewDidCancelSession(_ canvasView: CanvasView) {
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
