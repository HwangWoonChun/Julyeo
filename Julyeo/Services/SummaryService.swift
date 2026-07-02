import Foundation
import FoundationModels

struct SummaryResult {
    let title: String
    let summary: String
    let keyPoints: [String]
}

actor SummaryService {

    private var languageModel: SystemLanguageModel {
        SystemLanguageModel(useCase: .general)
    }

    private var generationOptions: GenerationOptions {
        GenerationOptions(temperature: 0.4, maximumResponseTokens: 1024)
    }

    func summarize(text: String) async throws -> SummaryResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummaryError.emptyText
        }

        try validateModel()

        let session = LanguageModelSession(
            model: languageModel,
            instructions: """
            당신은 텍스트 요약 전문가입니다.
            주어진 내용을 간결하게 요약하고 핵심 포인트를 추출합니다.
            모든 응답은 한국어로 작성하세요.
            """
        )

        // 제목 생성
        let titleResponse = try await session.respond(
            to: "다음 내용의 제목을 한 줄로 만들어주세요 (20자 이내):\n\(text.prefix(500))",
            options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 50)
        )
        let title = titleResponse.content.trimmingCharacters(in: .whitespacesAndNewlines)

        // 요약 생성
        let summaryResponse = try await session.respond(
            to: "다음 내용을 3~5문장으로 요약해주세요:\n\(text)",
            options: generationOptions
        )
        let summary = summaryResponse.content.trimmingCharacters(in: .whitespacesAndNewlines)

        // 핵심 포인트 추출
        let keyPointsResponse = try await session.respond(
            to: "다음 내용에서 핵심 포인트를 3~5개 bullet point로 추출해주세요. 각 항목은 줄바꿈으로 구분하고 '•' 기호로 시작하세요:\n\(text)",
            options: generationOptions
        )
        let keyPoints = keyPointsResponse.content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("•") || $0.hasPrefix("-") || $0.hasPrefix("·") }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "•-· ")) }
            .filter { !$0.isEmpty }

        return SummaryResult(
            title: title.isEmpty ? "요약 \(Date().formatted(date: .abbreviated, time: .omitted))" : title,
            summary: summary,
            keyPoints: keyPoints
        )
    }

    private func validateModel() throws {
        switch SystemLanguageModel.default.availability {
        case .available: return
        case .unavailable(.appleIntelligenceNotEnabled):
            throw SummaryError.appleIntelligenceDisabled
        case .unavailable(.deviceNotEligible):
            throw SummaryError.deviceNotEligible
        default:
            throw SummaryError.modelUnavailable
        }
    }
}

enum SummaryError: LocalizedError {
    case emptyText
    case modelUnavailable
    case appleIntelligenceDisabled
    case deviceNotEligible

    var errorDescription: String? {
        switch self {
        case .emptyText: return "요약할 내용이 없습니다."
        case .modelUnavailable: return "AI 모델을 사용할 수 없습니다."
        case .appleIntelligenceDisabled: return "Apple Intelligence가 비활성화되어 있습니다."
        case .deviceNotEligible: return "이 기기는 Apple Intelligence를 지원하지 않습니다."
        }
    }
}
