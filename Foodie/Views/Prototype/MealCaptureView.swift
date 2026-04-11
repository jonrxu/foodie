//
//  MealCaptureView.swift
//  Foodie
//

import AVFoundation
import PhotosUI
import Speech
import SwiftUI
import VisionKit

// MARK: - Router

struct MealCaptureView: View {
    let mode: FoodLoggingMode
    let onComplete: (MealInput) -> Void

    var body: some View {
        switch mode {
        case .textLog:
            TextMealInputView(onComplete: onComplete)
        case .voiceLog:
            VoiceMealInputView(onComplete: onComplete)
        case .takePhoto:
            PhotoMealInputView(onComplete: onComplete)
        case .barcodeScan:
            BarcodeMealInputView(onComplete: onComplete)
        }
    }
}

// MARK: - Text

struct TextMealInputView: View {
    let onComplete: (MealInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you eat?")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Describe your meal in a few words")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 20)

                    TextField("e.g. Grilled chicken, rice, salad", text: $text, axis: .vertical)
                        .font(.body)
                        .lineLimit(4...8)
                        .focused($isFocused)
                        .padding(14)
                        .background(.white.opacity(0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                        )

                    Spacer(minLength: 20)

                    HStack(spacing: 10) {
                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            onComplete(.text(text.trimmingCharacters(in: .whitespacesAndNewlines)))
                        } label: {
                            Text("Log meal")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .onAppear { isFocused = true }
    }

    private var pageBackground: some View {
        ZStack {
            Color.white
            LinearGradient(
                colors: [.white, .white, Color.blue.opacity(0.003), Color.blue.opacity(0.012)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - Voice

@MainActor
private final class SpeechRecorder: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startRecording() {
        guard !isRecording else { return }
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                Task { @MainActor [weak self] in
                    self?.errorMessage = "Speech recognition not authorized."
                }
                return
            }
            Task { @MainActor [weak self] in
                self?._startRecording()
            }
        }
    }

    private func _startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal == true) {
                    self?.stopRecording()
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Could not start audio engine."
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

struct VoiceMealInputView: View {
    let onComplete: (MealInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = SpeechRecorder()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice log")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Tap the mic and describe your meal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 20)

                    VStack(spacing: 20) {
                        Button {
                            if recorder.isRecording {
                                recorder.stopRecording()
                            } else {
                                recorder.transcript = ""
                                recorder.startRecording()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(recorder.isRecording ? Color.red.opacity(0.15) : AppTheme.primary.opacity(0.12))
                                    .frame(width: 88, height: 88)
                                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(recorder.isRecording ? .red : AppTheme.primary)
                            }
                        }
                        .buttonStyle(.plain)

                        if recorder.isRecording {
                            Text("Listening…")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        if !recorder.transcript.isEmpty {
                            Text(recorder.transcript)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .padding(14)
                                .background(.white.opacity(0.96))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                                )
                        }

                        if let error = recorder.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 20)

                    HStack(spacing: 10) {
                        Button { recorder.stopRecording(); dismiss() } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            recorder.stopRecording()
                            let final = recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                            onComplete(.voice(final.isEmpty ? "Voice meal" : final))
                        } label: {
                            Text("Log meal")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(recorder.transcript.isEmpty ? Color.gray.opacity(0.3) : AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(recorder.transcript.isEmpty && !recorder.isRecording)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .onDisappear { recorder.stopRecording() }
    }

    private var pageBackground: some View {
        ZStack {
            Color.white
            LinearGradient(
                colors: [.white, .white, Color.teal.opacity(0.003), Color.teal.opacity(0.012)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - Photo

struct PhotoMealInputView: View {
    let onComplete: (MealInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo log")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Pick a photo of your meal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 20)

                    VStack(spacing: 16) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        } else {
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images
                            ) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 36, weight: .semibold))
                                        .foregroundStyle(AppTheme.primary)
                                    Text("Select photo")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(AppTheme.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .background(AppTheme.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if selectedImage != nil {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Choose different photo")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    HStack(spacing: 10) {
                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            guard let image = selectedImage,
                                  let data = image.jpegData(compressionQuality: 0.8) else { return }
                            isAnalyzing = true
                            onComplete(.photo(data, "image/jpeg"))
                        } label: {
                            HStack(spacing: 8) {
                                if isAnalyzing {
                                    ProgressView().tint(.white)
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Log meal")
                                    .font(.headline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedImage == nil ? Color.gray.opacity(0.3) : AppTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedImage == nil || isAnalyzing)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var pageBackground: some View {
        ZStack {
            Color.white
            LinearGradient(
                colors: [.white, .white, Color.blue.opacity(0.003), Color.blue.opacity(0.012)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - Barcode

struct BarcodeMealInputView: View {
    let onComplete: (MealInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var showScanner = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Barcode scan")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Scan a product barcode to log your meal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 20)

                    VStack(spacing: 16) {
                        Button {
                            showScanner = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 44, weight: .semibold))
                                    .foregroundStyle(Color.orange)
                                Text(scannedCode == nil ? "Tap to scan" : "Scan again")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(Color.orange)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(Color.orange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)

                        if let code = scannedCode {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Scanned: \(code)")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 20)

                    HStack(spacing: 10) {
                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            guard let code = scannedCode else { return }
                            onComplete(.barcode(code))
                        } label: {
                            Text("Log meal")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(scannedCode == nil ? Color.gray.opacity(0.3) : AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(scannedCode == nil)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet { code in
                scannedCode = code
                showScanner = false
            }
        }
    }

    private var pageBackground: some View {
        ZStack {
            Color.white
            LinearGradient(
                colors: [.white, .white, Color.orange.opacity(0.003), Color.orange.opacity(0.012)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - Barcode scanner sheet (DataScannerViewController)

private struct BarcodeScannerSheet: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            let alert = UIAlertController(
                title: "Scanner unavailable",
                message: "Barcode scanning is not available on this device.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            let nav = UINavigationController(rootViewController: alert)
            return nav
        }
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        let nav = UINavigationController(rootViewController: scanner)
        try? scanner.startScanning()
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var didScan = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !didScan, let item = addedItems.first,
                  case .barcode(let barcode) = item,
                  let payload = barcode.payloadStringValue else { return }
            didScan = true
            onScan(payload)
        }
    }
}
