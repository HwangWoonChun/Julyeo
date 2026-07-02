import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct HomeView: View {

    @State private var showRecordView = false
    @State private var showImagePicker = false
    @State private var showResultView = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var showAudioResult = false
    @State private var audioTranscript = ""
    @State private var isTranscribing = false
    @State private var transcribeError: String?
    @State private var showTranscribeError = false
    @StateObject private var speechService = SpeechService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("줄여줘")
                        .font(.system(size: 34, weight: .bold))
                    Text(String(localized: "app.tagline"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)
                .padding(.bottom, 48)

                VStack(spacing: 16) {
                    InputButton(
                        icon: "mic.fill",
                        title: String(localized: "input.record"),
                        subtitle: String(localized: "input.record.subtitle"),
                        color: .red
                    ) { showRecordView = true }

                    InputButton(
                        icon: "camera.fill",
                        title: String(localized: "input.camera"),
                        subtitle: String(localized: "input.camera.subtitle"),
                        color: .blue
                    ) { showCamera = true }

                    InputButton(
                        icon: "waveform",
                        title: String(localized: "input.audiofile"),
                        subtitle: String(localized: "input.audiofile.subtitle"),
                        color: .purple
                    ) { showFilePicker = true }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                                .foregroundStyle(.green)
                                .frame(width: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "input.gallery"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(String(localized: "input.gallery.subtitle"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                pendingImage = image
                                showResultView = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                NavigationLink(destination: HistoryView()) {
                    Label(String(localized: "nav.history"), systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRecordView) { RecordView() }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if pendingImage != nil { showResultView = true }
            }) {
                CameraPickerView(image: $pendingImage, isPresented: $showCamera)
                    .ignoresSafeArea()
            }
            .navigationDestination(isPresented: $showResultView) {
                if let image = pendingImage {
                    ResultView(inputType: .image, image: image)
                        .onDisappear { pendingImage = nil }
                }
            }
            .navigationDestination(isPresented: $showAudioResult) {
                ResultView(inputType: .audio, transcript: audioTranscript)
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, UTType("public.mp3")!, .mpeg4Audio, UTType("com.microsoft.waveform-audio")!].compactMap { $0 }
            ) { result in
                switch result {
                case .success(let url): Task { await transcribeAudioFile(url: url) }
                case .failure(let error):
                    transcribeError = error.localizedDescription
                    showTranscribeError = true
                }
            }
            .alert(String(localized: "audio.error.title"), isPresented: $showTranscribeError) {
                Button(String(localized: "common.confirm"), role: .cancel) {}
            } message: {
                Text(transcribeError ?? String(localized: "audio.error.fallback"))
            }
            .overlay {
                if isTranscribing {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView().scaleEffect(1.5).tint(.white)
                            Text(String(localized: "audio.transcribing"))
                                .foregroundStyle(.white).font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
        }
    }

    private func transcribeAudioFile(url: URL) async {
        isTranscribing = true
        defer { isTranscribing = false }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            audioTranscript = try await speechService.transcribeFile(url: url)
            showAudioResult = true
        } catch {
            transcribeError = error.localizedDescription
            showTranscribeError = true
        }
    }
}

struct InputButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
