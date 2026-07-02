import SwiftUI
import SwiftData

struct ResultView: View {

    let inputType: InputType
    var transcript: String = ""
    var image: UIImage? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .extracting
    @State private var extractedText: String = ""
    @State private var result: SummaryResult?
    @State private var errorMessage: String?
    @State private var saved = false
    @State private var showErrorAlert = false

    private let ocrService = OCRService()
    private let summaryService = SummaryService()

    enum Phase {
        case extracting, summarizing, done, error
    }

    var body: some View {
        ZStack {
            JTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: JTheme.spaceM) {
                    switch phase {
                    case .extracting:
                        loadingView(message: inputType == .image ? "텍스트 인식 중..." : "텍스트 준비 중...")

                    case .summarizing:
                        loadingView(message: "AI가 요약하는 중...")

                    case .done:
                        if let result {
                            doneView(result: result)
                        }

                    case .error:
                        errorView()
                    }
                }
                .padding(JTheme.spaceM)
            }
        }
        .navigationTitle("요약 결과")
        .navigationBarTitleDisplayMode(.inline)
        .alert("요약 실패", isPresented: $showErrorAlert) {
            Button("다시 시도") { Task { await process() } }
            Button("닫기", role: .cancel) { dismiss() }
        } message: {
            Text(errorMessage ?? "오류가 발생했습니다. 다시 시도해주세요.")
        }
        .toolbar {
            if phase == .done && !saved {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveRecord() }
                        .tint(JTheme.accent)
                }
            }
        }
        .task { await process() }
        .tint(JTheme.accent)
    }

    // MARK: - Sub Views

    private func loadingView(message: String) -> some View {
        VStack(spacing: JTheme.spaceM) {
            Spacer(minLength: 100)
            ZStack {
                Circle()
                    .stroke(JTheme.accent.opacity(0.15), lineWidth: 6)
                    .frame(width: 80, height: 80)
                ProgressView()
                    .scaleEffect(2)
                    .tint(JTheme.accent)
            }
            VStack(spacing: 6) {
                Text(message)
                    .font(JTheme.headline())
                Text(phase == .extracting ? "잠시만 기다려주세요" : "Foundation Models 처리 중...")
                    .font(JTheme.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func doneView(result: SummaryResult) -> some View {
        VStack(alignment: .leading, spacing: JTheme.spaceM) {
            // 제목
            Text(result.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Divider()

            // 요약
            JCard {
                VStack(alignment: .leading, spacing: JTheme.spaceXS) {
                    JSectionLabel(icon: "text.alignleft", text: "요약")
                    Text(result.summary)
                        .font(JTheme.body())
                }
            }

            // 핵심 포인트
            if !result.keyPoints.isEmpty {
                JCard {
                    VStack(alignment: .leading, spacing: JTheme.spaceXS) {
                        JSectionLabel(icon: "list.bullet", text: "핵심 포인트")
                        ForEach(result.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(JTheme.accent)
                                Text(point)
                                    .font(JTheme.body())
                            }
                        }
                    }
                }
            }

            // 원문 보기
            JCard {
                DisclosureGroup("원문 보기") {
                    Text(extractedText)
                        .font(JTheme.caption())
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .tint(.primary)
            }

            // 공유 버튼
            ShareLink(item: shareText(result: result)) {
                Label("공유하기", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(JPrimaryButtonStyle())

            if saved {
                Label("저장됨", systemImage: "checkmark.circle.fill")
                    .font(JTheme.caption().weight(.medium))
                    .foregroundStyle(JTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func errorView() -> some View {
        VStack(spacing: JTheme.spaceS) {
            Spacer(minLength: 80)
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(errorMessage ?? "오류가 발생했습니다")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("다시 시도") {
                Task { await process() }
            }
            .buttonStyle(.borderedProminent)
            .tint(JTheme.accent)
            Spacer()
        }
    }

    // MARK: - Logic

    private func process() async {
        do {
            // 1. 텍스트 추출
            phase = .extracting
            if inputType == .image, let image {
                extractedText = try await ocrService.recognizeText(from: image)
                print("[Julyeo] OCR 결과 (\(extractedText.count)자):\n\(extractedText)")
            } else {
                extractedText = transcript
                print("[Julyeo] 음성 인식 결과 (\(extractedText.count)자):\n\(extractedText)")
            }

            // 2. 요약
            phase = .summarizing
            let summaryResult = try await summaryService.summarize(text: extractedText)
            result = summaryResult
            phase = .done

            print("[Julyeo] === 요약 완료 ===")
            print("[Julyeo] 제목: \(summaryResult.title)")
            print("[Julyeo] 요약: \(summaryResult.summary)")
            print("[Julyeo] 핵심 포인트(\(summaryResult.keyPoints.count)개):")
            summaryResult.keyPoints.enumerated().forEach { print("[Julyeo]   \($0+1). \($1)") }
            print("[Julyeo] 원문 길이: \(extractedText.count)자")

        } catch {
            errorMessage = error.localizedDescription
            phase = .error
            showErrorAlert = true
        }
    }

    private func saveRecord() {
        guard let result else { return }
        let record = SummaryRecord(
            inputType: inputType,
            title: result.title,
            originalText: extractedText,
            summary: result.summary,
            keyPoints: result.keyPoints,
            imageData: image?.jpegData(compressionQuality: 0.7)
        )
        modelContext.insert(record)
        saved = true
    }

    private func shareText(result: SummaryResult) -> String {
        """
        📝 \(result.title)

        【요약】
        \(result.summary)

        【핵심 포인트】
        \(result.keyPoints.map { "• \($0)" }.joined(separator: "\n"))

        — Julyeo 줄여줘
        """
    }
}
