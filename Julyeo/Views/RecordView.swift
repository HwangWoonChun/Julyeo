import SwiftUI

struct RecordView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechService()
    @State private var showResult = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            ZStack {
                JTheme.background.ignoresSafeArea()

                VStack(spacing: JTheme.spaceL) {
                    Spacer()

                    // 녹음 상태 애니메이션
                    ZStack {
                        if speechService.isRecording {
                            Circle()
                                .fill(JTheme.danger.opacity(0.15))
                                .frame(width: 140, height: 140)
                                .scaleEffect(speechService.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: speechService.isRecording)
                        }
                        Circle()
                            .fill(speechService.isRecording ? JTheme.danger : JTheme.accentSoftStrong)
                            .frame(width: 100, height: 100)
                        Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(speechService.isRecording ? .white : JTheme.accent)
                    }
                    .onTapGesture {
                        Task { await toggleRecording() }
                    }

                    Text(speechService.isRecording ? "탭하여 중지" : "탭하여 녹음 시작")
                        .font(JTheme.body())
                        .foregroundStyle(.secondary)

                    // 실시간 텍스트
                    if !speechService.transcript.isEmpty {
                        ScrollView {
                            Text(speechService.transcript)
                                .font(JTheme.body())
                                .padding(JTheme.spaceM)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .background(JTheme.surface, in: RoundedRectangle(cornerRadius: JTheme.radiusM, style: .continuous))
                        .padding(.horizontal, JTheme.spaceM)
                    }

                    Spacer()
                }
                .padding(.bottom, JTheme.spaceL)
            }
            .navigationTitle("녹음")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showResult) {
                ResultView(inputType: .audio, transcript: speechService.transcript)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        speechService.stopRecording()
                        dismiss()
                    }
                }
                if !speechService.transcript.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("요약하기") {
                            speechService.stopRecording()
                            showResult = true
                        }
                        .fontWeight(.semibold)
                        .tint(JTheme.accent)
                    }
                }
            }
            .alert("마이크 권한 필요", isPresented: $permissionDenied) {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) {}
            }
            .onChange(of: speechService.isRecording) { _, isRecording in
                print("[RecordView] isRecording 변경: \(isRecording), transcript: \(speechService.transcript.count)자")
            }
        }
        .tint(JTheme.accent)
    }

    private func toggleRecording() async {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            let granted = await speechService.requestPermission()
            if granted {
                speechService.startRecording()
            } else {
                permissionDenied = true
            }
        }
    }
}
