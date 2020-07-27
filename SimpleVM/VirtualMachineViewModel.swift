//
//  VirtualMachineViewModel.swift
//  SimpleVM
//
//  Created by Khaos Tian on 7/26/20.
//

import Foundation
import Combine
import Virtualization

class VirtualMachineViewModel: NSObject, ObservableObject, VZVirtualMachineDelegate {
    
    private var virtualMachine: VZVirtualMachine?
    
    @Published var kernelURL: URL?
    @Published var initialRamdiskURL: URL?
    @Published var bootableImageURL: URL?
    
    @Published var state: VZVirtualMachine.State?
    
    private var cancellables: Set<AnyCancellable> = []
    
    var isReady: Bool {
        return kernelURL != nil && initialRamdiskURL != nil && bootableImageURL != nil
    }
    
    var stateDescription: String? {
        guard let state = state else {
            return nil
        }
        
        switch state {
        case .stopped:
            return "Stopped"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .error:
            return "Error"
        case .starting:
            return "Starting"
        case .pausing:
            return "Pausing"
        case .resuming:
            return "Resuming"
        @unknown default:
            return "Unknown \(state.rawValue)"
        }
    }
    
    func start() {
        guard let kernelURL = kernelURL,
              let initialRamdiskURL = initialRamdiskURL,
              let bootableImageURL = bootableImageURL else {
            return
        }
        
        cancellables = []
        state = nil
        
        let bootloader = VZLinuxBootLoader(kernelURL: kernelURL)
        bootloader.initialRamdiskURL = initialRamdiskURL
        
        let serial = VZVirtioConsoleDeviceConfiguration()
        
        serial.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: .standardInput,
            fileHandleForWriting: .standardOutput
        )

        let entropy = VZVirtioEntropyDeviceConfiguration()
        
        let memoryBalloon = VZVirtioTraditionalMemoryBalloonDeviceConfiguration()
        
        let blockAttachment: VZDiskImageStorageDeviceAttachment
        
        do {
            blockAttachment = try VZDiskImageStorageDeviceAttachment(
                url: bootableImageURL,
                readOnly: true
            )
        } catch {
            NSLog("Failed to load bootableImage: \(error)")
            return
        }
        
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: blockAttachment)
        
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        
        let config = VZVirtualMachineConfiguration()
        config.bootLoader = bootloader
        config.cpuCount = 4
        config.memorySize = 2 * 1024 * 1024 * 1024
        config.entropyDevices = [entropy]
        config.memoryBalloonDevices = [memoryBalloon]
        config.serialPorts = [serial]
        config.storageDevices = [blockDevice]
        config.networkDevices = [networkDevice]
                
        do {
            try config.validate()
            
            let vm = VZVirtualMachine(configuration: config)
            vm.delegate = self
            self.virtualMachine = vm
            
            KeyValueObservingPublisher(object: vm, keyPath: \.state, options: [.initial, .new])
                .sink { [weak self] state in
                    self?.state = state
                }
                .store(in: &cancellables)
            
            vm.start { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    NSLog("Failed: \(error)")
                }
            }
        } catch {
            NSLog("Error: \(error)")
            return
        }
    }
    
    func stop() {
        cancellables = []
        state = nil
        if let virtualMachine = virtualMachine {
            do {
                try virtualMachine.requestStop()
            } catch {
                NSLog("Failed to stop: \(error)")
            }
            self.virtualMachine = nil
        }
    }
    
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        NSLog("Stopped")
    }
    
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        NSLog("Stopped with error: \(error)")
    }
}
