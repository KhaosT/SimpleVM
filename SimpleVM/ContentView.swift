//
//  ContentView.swift
//  SimpleVM
//
//  Created by Khaos Tian on 7/26/20.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @StateObject var viewModel = VirtualMachineViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
            }
            
            Text("vmlinuz: \(viewModel.kernelURL?.lastPathComponent ?? "(Drag to here)")")
                .padding([.top, .bottom])
                .onDrop(of: [.fileURL], isTargeted: nil) { itemProviders -> Bool in
                    processDropItem(of: .kernel, items: itemProviders)
                    return true
                }
            
            Text("initrd: \(viewModel.initialRamdiskURL?.lastPathComponent ?? "(Drag to here)")")
                .padding([.top, .bottom])
                .onDrop(of: [.fileURL], isTargeted: nil) { itemProviders -> Bool in
                    processDropItem(of: .ramdisk, items: itemProviders)
                    return true
                }
            
            Text("image: \(viewModel.bootableImageURL?.lastPathComponent ?? "(Drag to here)")")
                .padding([.top, .bottom])
                .onDrop(of: [.fileURL], isTargeted: nil) { itemProviders -> Bool in
                    processDropItem(of: .image, items: itemProviders)
                    return true
                }
            
            Spacer()
            
            HStack {
                if viewModel.state == nil {
                    Button("Start") {
                        viewModel.start()
                    }
                    .disabled(!viewModel.isReady)
                } else {
                    Button("Stop") {
                        viewModel.stop()
                    }
                }
                
                if let stateDescription = viewModel.stateDescription {
                    Spacer()
                    Text("State: \(stateDescription)")
                }
            }
            
        }
        .padding()
        .frame(width: 300)
    }
    
    enum DropItemType {
        case kernel
        case ramdisk
        case image
    }
    
    private func processDropItem(of type: DropItemType,
                                 items: [NSItemProvider]) {
        guard let item = items.first else {
            return
        }
        
        item.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
            guard let data = data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                switch type {
                case .kernel:
                    viewModel.kernelURL = url
                case .ramdisk:
                    viewModel.initialRamdiskURL = url
                case .image:
                    viewModel.bootableImageURL = url
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
