//
//  AudioStreamer.swift
//  Task1
//
//  Created by Игорь Клюжев on 09.11.2022.
//

import Foundation
import AVFoundation
import SPIndicator

class AudioStreamer {
    private var audioEngine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var outputStream: OutputStream?
    private var audioFormat: AVAudioFormat?

    private var sendData: ((Data) -> Void)?

    init() {
        audioEngine = AVAudioEngine()
        player = AVAudioPlayerNode()
        prepareSession()

        audioFormat = audioEngine?.inputNode.inputFormat(forBus: 0)

        guard let player = player,
              let audioEngine = audioEngine
        else { return }

        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: audioFormat)
        audioEngine.prepare()

        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                showError(title: "Can't start audio engine")
            }
        }
    }

    func startStreaming(sendData: @escaping (Data) -> Void /*to stream: OutputStream*/) {
//        outputStream = stream
        self.sendData = sendData
        audioEngine?.inputNode.installTap(
            onBus: 0,
            bufferSize: 4800,
            format: audioFormat
        ) { buffer, time in
            print("Sending buffer with time \(time)")
            let data = self.audioBufferToNSData(PCMBuffer: buffer)
            self.sendData?(Data(referencing: data))
        }
    }

    func stopStreaming() {
        audioEngine?.inputNode.removeTap(onBus: 0)
//        outputStream?.close()
        sendData = nil
    }

    func schedulePlay(_ data: Data) {
        prepareSession()

        guard let audioEngine = audioEngine else { return }

        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                showError(title: "Can't start audio engine")
            }
        }

        guard let audioFormat = audioFormat,
              let audioBuffer = dataToPCMBuffer(format: audioFormat, data: NSData(data: data))
        else {
            showError(title: "No buffer made from data")
            return
        }
        player?.scheduleBuffer(audioBuffer)
        player?.play()
    }

    private func showError(title: String) {
        DispatchQueue.main.async {
            SPIndicator.present(title: title, preset: .error)
        }
    }

    private func prepareSession() {
        AudioOutputUnitStop((audioEngine?.inputNode.audioUnit)!)
        AudioUnitUninitialize((audioEngine?.inputNode.audioUnit)!)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker) // TODO: check if needed
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            showError(title: error.localizedDescription)
        }
    }

    private func audioBufferToNSData(PCMBuffer: AVAudioPCMBuffer) -> NSData {
        let channelCount = 1
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: channelCount)
        let data = NSData(bytes: channels[0],
                          length: Int(PCMBuffer.frameLength * PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))

        return data
    }

    private func dataToPCMBuffer(format: AVAudioFormat, data: NSData) -> AVAudioPCMBuffer? {
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                                 frameCapacity: UInt32(data.length) / format.streamDescription.pointee.mBytesPerFrame)
        else {
            showError(title: "Can't create audio buffer")
            return nil
        }

        audioBuffer.frameLength = audioBuffer.frameCapacity
        let channels = UnsafeBufferPointer(start: audioBuffer.floatChannelData,
                                           count: Int(audioBuffer.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]),
                      length: data.length)
        return audioBuffer
    }
}
