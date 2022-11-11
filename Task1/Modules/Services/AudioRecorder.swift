//
//  AudioRecorder.swift
//  Task1
//
//  Created by Игорь Клюжев on 10.11.2022.
//

import Foundation
import AVFoundation

protocol AudioRecorderProtocol {
    func startRecording()
    func stopRecording() -> URL
}

final class AudioRecorder: NSObject, AudioRecorderProtocol {
    private let recordingSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private lazy var audioFile = getDocumentsDirectory().appendingPathComponent("recording.m4a")

    override init() {
        super.init()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try? AVAudioRecorder(url: audioFile, settings: settings)
        audioRecorder?.delegate = self
    }

    private func requestPermission(completion: @escaping (Bool) -> Void) {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    completion(allowed)
                }
            }
        } catch {
            // failed to record!
        }
    }

    func startRecording() {
        audioRecorder?.record()
    }

    func stopRecording() -> URL {
        audioRecorder?.stop()
        audioRecorder = nil
        return audioFile
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}
