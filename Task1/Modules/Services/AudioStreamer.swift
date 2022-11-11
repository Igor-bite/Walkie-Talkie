//
//  AudioStreamer.swift
//  Task1
//
//  Created by Игорь Клюжев on 09.11.2022.
//

import Foundation
import AVFoundation

class AudioStreamer {
    private var audioEngine: AVAudioEngine? = AVAudioEngine.init()
    private var audioPlayer: AVAudioPlayerNode? = .init()
    private var audioFormat: AVAudioFormat? = {
        //        let settings : Dictionary = ["AVSampleRateKey" : 44100.0,
        //                                     "AVNumberOfChannelsKey" : 1,
        //                                     "AVFormatIDKey" : 1819304813,
        //                                     "AVLinearPCMIsNonInterleaved" : 0,
        //                                     "AVLinearPCMIsBigEndianKey" : 0,
        //                                     "AVLinearPCMBitDepthKey" : 16,
        //                                     "AVLinearPCMIsFloatKey" : 0]

        //        return AVAudioFormat.init(settings: settings)
        return AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                             sampleRate: 44100.0,
                             channels: 1,
                             interleaved: true)
    }()
    var outputStream: OutputStream?

    func stream() {
        audioEngine?.connect(audioEngine!.inputNode, to: audioEngine!.mainMixerNode, format: audioFormat)
        audioEngine?.inputNode.installTap(onBus: 0, bufferSize: 4410, format: audioFormat, block: {buffer, when in
            let input = self.audioEngine!.inputNode
            let bus = 0
            let inputFormat = input.outputFormat(forBus: bus )

            guard let outputFormat = self.audioFormat else { return }

            if let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)){
                var error: NSError?
                var newBufferAvailable = true
                let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    if newBufferAvailable {
                        outStatus.pointee = .haveData
                        newBufferAvailable = false

                        return buffer
                    } else {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                }
                let status = AVAudioConverter(from: inputFormat, to: outputFormat)!.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
                assert(status != .error)
                print(convertedBuffer.format)

                let audioBuffer = convertedBuffer.audioBufferList.pointee.mBuffers
                let data : Data = Data.init(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
                //            let arraySize = Int(buffer.frameLength)
                //            let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count:arraySize))
                print("Streaming data with size: \(data.count)")
                self.streamData(data: data, len: 4410)
            }
        })

        self.audioEngine?.prepare()
        do {
            try self.audioEngine?.start()
        }
        catch {
            NSLog("cannot start audio engine")
        }
        if(self.audioEngine?.isRunning == true){
            NSLog("Audioengine is running")
        }
    }

    private func streamData(data: Data, len: Int) {
        var baseCaseCondition : Bool = false
        var _len : Int = len
        var _byteIndex : Int = 0
        func recursiveBlock(block: @escaping (()->Void)->Void) -> ()->Void {
            return { block(recursiveBlock(block: block)) }
        }
        let aRecursiveBlock :()->Void = recursiveBlock {recurse in
            baseCaseCondition = (data.count > 0 && _byteIndex < data.count) ? true : false
            if ((baseCaseCondition)) {
                _len = (data.count - _byteIndex) == 0 ? 1 : (data.count - _byteIndex) < len ? (data.count - _byteIndex) : len
                NSLog("START | byteIndex: %lu/%lu  writing len: %lu", _byteIndex, data.count, _len)
                var bytes = [UInt8](repeating:0, count:_len)
                data.copyBytes(to: &bytes, from: _byteIndex ..< _byteIndex+_len )
                _byteIndex += (self.outputStream?.write(&bytes, maxLength: _len))!
                NSLog("END | byteIndex: %lu/%lu wrote len: %lu", _byteIndex, data.count, _len)
                recurse()
            }
        }
        if let outputStream = outputStream,
           outputStream.hasSpaceAvailable
        {
            aRecursiveBlock();
        }
    }

    func stopStreaming() {
        audioEngine?.stop()
    }

    func setupPlaying() {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio,
                                          completionHandler: { (granted: Bool) in
            })
        }

        try! AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        try! AVAudioSession.sharedInstance().setActive(true)
        let mainMixer = audioEngine!.mainMixerNode

        audioEngine?.attach(mainMixer)
        audioEngine?.attach(audioPlayer!)
        audioEngine!.connect(audioPlayer!, to: mainMixer, format: audioFormat!)
    }

    func scheduleBufferPlay(_ audioBuffer: AVAudioPCMBuffer) {
        if (audioEngine!.isRunning) {
            audioEngine!.stop()
            audioEngine!.reset()
        }

        audioPlayer!.scheduleBuffer(audioBuffer, completionHandler: nil)

        do {
            try audioEngine!.start()
        }
        catch {
            print("\(#file) > \(#function) > error: \(error.localizedDescription)")
        }

        audioPlayer!.play()
    }

    func audioBufferToNSData(PCMBuffer: AVAudioPCMBuffer) -> NSData {
        let channelCount = 1  // given PCMBuffer channel count is 1
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: channelCount)
        let data = NSData(bytes: channels[0], length:Int(PCMBuffer.frameLength * PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))

        return data
    }

    func dataToPCMBuffer(data: NSData) -> AVAudioPCMBuffer? {

        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!,
                                           frameCapacity: UInt32(data.length) / audioFormat!.streamDescription.pointee.mBytesPerFrame)

        audioBuffer!.frameLength = audioBuffer!.frameCapacity
        let channels = UnsafeBufferPointer(start: audioBuffer!.floatChannelData, count: Int(audioBuffer!.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]) , length: data.length) // copy bytes
        return audioBuffer
    }
}
