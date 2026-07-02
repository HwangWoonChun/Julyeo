import SwiftUI

// MARK: - 줄여줘 디자인 시스템
// 미니멀 & 클린 무드. 단일 accent(teal)로 통일하고,
// 색상보다 아이콘/타이포 위계로 정보를 구분한다.

enum JTheme {

    // MARK: Colors
    static let accent = Color(hex: "0F6E56")          // 딥 틸 — 아이콘/브랜드와 통일
    static let accentSoft = Color(hex: "0F6E56").opacity(0.10)
    static let accentSoftStrong = Color(hex: "0F6E56").opacity(0.16)

    static let danger = Color(hex: "C0392B")           // 녹음 중 등 명확한 경고 상태 전용

    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)

    // MARK: Radius
    static let radiusL: CGFloat = 22
    static let radiusM: CGFloat = 16
    static let radiusS: CGFloat = 12

    // MARK: Spacing
    static let spaceXS: CGFloat = 6
    static let spaceS: CGFloat = 12
    static let spaceM: CGFloat = 20
    static let spaceL: CGFloat = 32
    static let spaceXL: CGFloat = 48

    // MARK: Typography
    static func title() -> Font { .system(size: 30, weight: .bold, design: .rounded) }
    static func headline() -> Font { .system(size: 17, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// MARK: - 공용 카드 컨테이너
struct JCard<Content: View>: View {
    var padding: CGFloat = JTheme.spaceM
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(JTheme.surface, in: RoundedRectangle(cornerRadius: JTheme.radiusM, style: .continuous))
    }
}

// MARK: - 아이콘 배지 (원형 tint 배경 + 심볼)
struct JIconBadge: View {
    let systemName: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(JTheme.accentSoft)
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(JTheme.accent)
        }
    }
}

// MARK: - 홈 화면 입력 옵션 행 (통일된 스타일)
struct JOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: JTheme.spaceS) {
                JIconBadge(systemName: icon, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(JTheme.body().weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
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
            .background(
                JTheme.surface,
                in: RoundedRectangle(cornerRadius: JTheme.radiusM, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 섹션 라벨 (요약, 핵심 포인트 등)
struct JSectionLabel: View {
    let icon: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(JTheme.headline())
        } icon: {
            Image(systemName: icon)
        }
        .foregroundStyle(JTheme.accent)
    }
}

// MARK: - 프라이머리 필 버튼
struct JPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(JTheme.headline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(JTheme.accent, in: RoundedRectangle(cornerRadius: JTheme.radiusM, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
