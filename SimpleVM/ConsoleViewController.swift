//
//  ConsoleViewController.swift
//  SimpleVM
//
//  Created by Khaos Tian on 7/26/20.
//

import Cocoa
import SwiftTerm

class ConsoleViewController: NSViewController, TerminalViewDelegate {
    
    private lazy var terminalView: TerminalView = {
        let terminalView = TerminalView()
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        terminalView.terminalDelegate = self
        return terminalView
    }()
    
    private var readPipe: Pipe?
    private var writePipe: Pipe?
        
    override func loadView() {
        view = NSView()
    }
    
    deinit {
        readPipe?.fileHandleForReading.readabilityHandler = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(terminalView)
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: view.topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            terminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func configure(with readPipe: Pipe, writePipe: Pipe) {
        self.readPipe = readPipe
        self.writePipe = writePipe
        
        readPipe.fileHandleForReading.readabilityHandler = { [weak self] pipe in
            let data = pipe.availableData
            if let strongSelf = self {
                DispatchQueue.main.sync {
                    strongSelf.terminalView.feed(byteArray: [UInt8](data)[...])
                }
            }
        }
    }
    
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        
    }
    
    func setTerminalTitle(source: TerminalView, title: String) {
        
    }
    
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        writePipe?.fileHandleForWriting.write(Data(data))
    }
    
    func scrolled(source: TerminalView, position: Double) {
        
    }
}
