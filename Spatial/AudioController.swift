//
//  AudioController.swift
//  MyApp
//
//  Created by Daniel Glover on 05/07/2026.
//

import AVFoundation
import Combine
import CoreMotion



@MainActor
class AudioController: NSObject, ObservableObject {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let env = AVAudioEnvironmentNode()
    let mm = CMHeadphoneMotionManager()
    
    let format: AVAudioFormat
    
    var displayLink: CADisplayLink?
    var startTime: CFTimeInterval = 0
    
    let monoF: AVAudioFormat
    
    override init(){
        // Registering both nodes with the engine so they can be wired together
        engine.attach(player)
        engine.attach(env)
        player.renderingAlgorithm = .HRTF
        
        // Pulls the hardware's own output, so the nodes speak the same language (sample rate, channel count etc.)
        format = engine.outputNode.inputFormat(forBus: 0)
        monoF = AVAudioFormat(standardFormatWithSampleRate: format.sampleRate, channels: 1)!
        
        do {
            // This wires player -> env -> output (hardware)
            try engine.connectNode(player, to: env, format: monoF)
            try engine.connectNode(env, to: engine.outputNode, format: format)
        } catch {
            print("An error occurred: \(error.localizedDescription)")
        }
    }
    
    func startTracking(){
        
        guard mm.isDeviceMotionAvailable else {
            print("Headphone motion is not available.")
            return
        }
        
        mm.startDeviceMotionUpdates(to: .main){(m, err) in
            if let error = err {
                print("Error receiving updates: \(error.localizedDescription)")
                return
            }
            
            // Safely unwrap
            // guard let motion = m else { return }
            
            // print("Yaw: \(motion.attitude.yaw), Pitch: \(motion.attitude.pitch), Roll: \(motion.attitude.roll)")
        }
    }
    
    @objc func tick() {
        let elapsedTime = Float(CACurrentMediaTime() - startTime)
        let radius: Float = 5.0 // Default radius for testing
        let theta = elapsedTime * 5.0
        player.position = AVAudio3DPoint(x: radius * cos(theta), y: 0, z: radius * sin(theta))
    }
    
    func playTone(){
        
        // Our sample rate is 44100, meaning that every second, the buffer is being sampled that number of times
        let frameCount = format.sampleRate * 5
        print("Frame count: ", frameCount)
        let frequency = 440
        let buffer = AVAudioPCMBuffer(pcmFormat: monoF, frameCapacity: AVAudioFrameCount(frameCount))
        
        buffer?.frameLength = AVAudioFrameCount(frameCount)
        
        for i in 0..<Int(frameCount){
            let t = Float(i) / Float(format.sampleRate)
            print("Time: ", t)
            let sample = sin((2.0 * Float.pi) * Float(frequency) * t) // This generates a 440Khz wave
            
            buffer?.floatChannelData![0][i] = sample
        }
        
        player.scheduleBuffer(buffer!)
        
        func startAnimating() {
            startTime = CACurrentMediaTime()
            _ = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
                Task { @MainActor in
                    self.tick()
                }
            }
        }
        
        startAnimating()
        startTracking()
        
        do {
            try player.playAudio()
            
        } catch {
            print("An error occured whilst trying to play audio: \(error.localizedDescription)")
        }
    }
    
    func getPID(id: String) -> pid_t {
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            let pid = app.processIdentifier
            return pid
        } else { return -1 }
    }
    
    func pidToProcessObject(pid: pid_t) -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var pidVar = pid
        var processObjectID: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(MemoryLayout<pid_t>.size), &pidVar,
            &size, &processObjectID
        )

        if status != noErr {
            print("Failed to translate PID: \(status)")
        }

        return processObjectID
    }
    
    func tccPermissionFire(pid: pid_t) {
        let processObjectID = pidToProcessObject(pid: pid)
        let tapDesc = CATapDescription(stereoMixdownOfProcesses: [processObjectID])
        var tapID: AudioObjectID = 0
        let c = AudioHardwareCreateProcessTap(tapDesc, &tapID)
        print("Tap creation status:", c)
        
        setupAggDevice(tapID: tapDesc.uuid.uuidString)
    }
    
    
    func setupAggDevice(tapID: String){
        let aggregateUID = "com.spatial.aggregate"

        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "SpatialCapture",
            kAudioAggregateDeviceUIDKey: aggregateUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceTapListKey: [
                [kAudioSubTapUIDKey: tapID]
            ]
        ]
        
        var aggregateDeviceID: AudioObjectID = 0
        let status = AudioHardwareCreateAggregateDevice(description as CFDictionary, &aggregateDeviceID)
        print("Aggregate status:", status)
        
        var ioProcID: AudioDeviceIOProcID?
        
        AudioDeviceCreateIOProcID(aggregateDeviceID, { (inDevice, inNow, inInputData, inInputTime, outOutputData, inOutputTime, inClientData) in
            let bufferList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inInputData))
            for buffer in bufferList {
                let samples = buffer.mData?.assumingMemoryBound(to: Float.self)
                print(samples?[0] ?? 0)
            }
            return noErr
        }, nil, &ioProcID)
        
        AudioDeviceStart(aggregateDeviceID, ioProcID)
        
    }
}
