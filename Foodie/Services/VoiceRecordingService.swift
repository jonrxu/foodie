//
//  VoiceRecordingService.swift
//  Foodie
//
//

import Foundation
import AVFoundation

@MainActor
final class VoiceRecordingService: NSObject, ObservableObject {
    enum RecordingState {
        case idle
        case recording
        case processing
    }
    
    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var recordingDuration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var timer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("❌ [VoiceRecording] Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() async throws {
        guard state == .idle else { return }
        
        // Request microphone permission
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard granted else {
            throw VoiceRecordingError.permissionDenied
        }
        
        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_log_\(Date().timeIntervalSince1970).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)
        
        guard let url = recordingURL else {
            throw VoiceRecordingError.invalidURL
        }
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            state = .recording
            recordingDuration = 0
            
            // Start timer to track duration
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
                }
            }
            
            print("🎤 [VoiceRecording] Started recording to \(url.lastPathComponent)")
        } catch {
            throw VoiceRecordingError.recordingFailed(error)
        }
    }
    
    func stopRecording() async throws -> Data {
        guard state == .recording else {
            throw VoiceRecordingError.notRecording
        }
        
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        state = .processing
        
        guard let url = recordingURL else {
            state = .idle
            throw VoiceRecordingError.invalidURL
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("✅ [VoiceRecording] Stopped recording, captured \(data.count) bytes")
            
            // Cleanup
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
            audioRecorder = nil
            
            state = .idle
            recordingDuration = 0
            
            return data
        } catch {
            state = .idle
            throw VoiceRecordingError.readFailed(error)
        }
    }
    
    func cancelRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        audioRecorder = nil
        state = .idle
        recordingDuration = 0
        
        print("🚫 [VoiceRecording] Recording cancelled")
    }
}

enum VoiceRecordingError: LocalizedError {
    case permissionDenied
    case invalidURL
    case recordingFailed(Error)
    case notRecording
    case readFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access is required to log food via voice."
        case .invalidURL:
            return "Failed to create recording file."
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .notRecording:
            return "No active recording to stop."
        case .readFailed(let error):
            return "Failed to read recording: \(error.localizedDescription)"
        }
    }
}

