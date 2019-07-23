/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa

class ViewController: NSViewController {

  @IBOutlet weak var statusLabel: NSTextField!

  @IBOutlet weak var fileListTable: NSTableView!
  let sizeFormatter = ByteCountFormatter()
  var directory: Directory?
  var directoryItems: [Metadata]?
  var sortOrder = Directory.FileOrder.Name
  var sortAscending = true

  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.stringValue = "No Items"
    setupFileList()
  }
  
  func setupFileList() {
    fileListTable.dataSource = self
    fileListTable.delegate = self
    fileListTable.target = self
    fileListTable.doubleAction = #selector(tableViewDoubleClick(_:))
    
    fileListTable.tableColumns.first?.sortDescriptorPrototype = NSSortDescriptor(key: Directory.FileOrder.Name.rawValue, ascending: true)
    fileListTable.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor(key: Directory.FileOrder.Date.rawValue, ascending: true)
    fileListTable.tableColumns.last?.sortDescriptorPrototype = NSSortDescriptor(key: Directory.FileOrder.Size.rawValue, ascending: true)
    
  }

  override var representedObject: Any? {
      didSet {
          if let url = representedObject as? URL {
            directory = Directory(folderURL: url)
            reloadFileList()
          }
      }
  }
  
  func reloadFileList() {
    directoryItems = directory?.contentsOrderedBy(sortOrder, ascending: sortAscending)
    fileListTable.reloadData()
  }
  
  func updateStatus() {
    var statusMessage = ""
    let itemsSelected = fileListTable.selectedRowIndexes.count
    if directoryItems == nil {
      statusMessage = "No Items"
    } else if itemsSelected == 0 {
      statusMessage = "\(directoryItems!.count) items"
    } else {
      statusMessage = "\(itemsSelected) of \(directoryItems!.count) selected"
    }
    statusLabel.stringValue = statusMessage
  }
  
  @objc func tableViewDoubleClick(_ sender:AnyObject) {
    guard fileListTable.selectedRow >= 0, let item = directoryItems?[fileListTable.selectedRow] else {
      return
    }
    
    if item.isFolder {
      representedObject = item.url as Any
    } else {
      NSWorkspace.shared.open(item.url as URL)
    }
  }
  
}

extension ViewController: NSTableViewDelegate {
  
  fileprivate enum CellIdentifiers {
    static let NameCell = "NameCellID"
    static let DateCell = "DateCellID"
    static let SizeCell = "SizeCellID"
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let item = directoryItems?[row] else {
      return nil
    }
    
    var image: NSImage?
    var cellIdentifier = ""
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .long
    
    var text = ""
    if tableColumn == tableView.tableColumns[0] {
      image = item.icon
      text = item.name
      cellIdentifier = CellIdentifiers.NameCell
    } else if tableColumn == tableView.tableColumns[1] {
      text = dateFormatter.string(from: item.date)
      cellIdentifier = CellIdentifiers.DateCell
    } else if tableColumn == tableView.tableColumns[2] {
      text = item.isFolder ? "--" : sizeFormatter.string(fromByteCount: item.size)
      cellIdentifier = CellIdentifiers.SizeCell
    }
    
    let identifier = NSUserInterfaceItemIdentifier(cellIdentifier)
    if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
      cell.textField?.stringValue = text
      cell.imageView?.image = image
      return cell
    }
    
    return nil
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    updateStatus()
  }
  
}

extension ViewController: NSTableViewDataSource {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return directoryItems?.count ?? 0
  }
  
  func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    guard let sortDescriptor = tableView.sortDescriptors.first else {
      return
    }
    
    if let order = Directory.FileOrder(rawValue: sortDescriptor.key!) {
      sortOrder = order
      sortAscending = sortDescriptor.ascending
      reloadFileList()
    }
  }
  
}

