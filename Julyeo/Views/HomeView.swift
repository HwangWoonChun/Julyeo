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
            ZStack {
                JTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 헤더
                    VStack(spacing: 8) {
                        Text("줄여줘")
                            .font(JTheme.title())
                        Text("녹음하거나 사진을 찍으면\nAI가 핵심만 정리해드려요")
                            .font(JTheme.body())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, JTheme.spaceXL)
                    .padding(.bottom, JTheme.spaceL)

                    // 입력 옵션
                    VStack(spacing: JTheme.spaceS) {
                        JOptionRow(
                            icon: "mic.fill",
                            title: "녹음으로 요약",
                            subtitle: "회의, 강의, 대화를 녹음하세요"
                        ) {
                            showRecordView = true
                        }

                        JOptionRow(
                            icon: "camera.fill",
                            title: "사진으로 요약",
                            subtitle: "문서, 칠판, 책을 촬영하세요"
                        ) {
                            showCamera = true
                        }

                        JOptionRow(
                            icon: "waveform",
                            title: "음성 파일로 요약",
                            subtitle: "m4a, mp3, wav 파일을 불러오세요"
                        ) {
                            showFilePicker = true
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack(spacing: JTheme.spaceS) {
                                JIconBadge(systemName: "photo.on.rectangle", size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("갤러리에서 선택")
                                        .font(JTheme.body().weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("저장된 사진을 불러오세요")
                                        .font(JTheme.caption())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, JTheme.spaceM)
                            .padding(.horizontal, JTheme.spaceM)
                            .background(JTheme.surface, in: RoundedRectangle(cornerRadius: JTheme.radiusM, style: .continuous))
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
                    .padding(.horizontal, JTheme.spaceM)

                    Spacer()

                    // 히스토리 버튼
                    NavigationLink(destination: HistoryView()) {
                        Label("기록 보기", systemImage: "clock")
                            .font(JTheme.caption().weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, JTheme.spaceL)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRecordView) {
                RecordView()
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if pendingImage != nil {
                    showResultView = true
                }
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
                case .success(let url):
                    Task { await transcribeAudioFile(url: url) }
                case .failure(let error):
                    transcribeError = error.localizedDescription
                    showTranscribeError = true
                }
            }
            .alert("변환 실패", isPresented: $showTranscribeError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(transcribeError ?? "음성 파일을 변환하지 못했습니다.")
            }
            .overlay {
                if isTranscribing {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: JTheme.spaceS) {
                            ProgressView().scaleEffect(1.5).tint(.white)
                            Text("음성 변환 중...").foregroundStyle(.white).font(JTheme.headline())
                        }
                        .padding(JTheme.spaceL)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: JTheme.radiusL))
                    }
                }
            }
        }
        .tint(JTheme.accent)
    }

    private func transcribeAudioFile(url: URL) async {
        isTranscribing = true
        defer { isTranscribing = false }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            audioTranscript = try await speechService.transcribeFile(url: url)
            print("[HomeView] 파일 변환 완료: \(audioTranscript.count)자")
            showAudioResult = true
        } catch {
            transcribeError = error.localizedDescription
            showTranscribeError = true
        }
    }
}
