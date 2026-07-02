import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(sort: \SummaryRecord.createdAt, order: .reverse) private var records: [SummaryRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "기록 없음",
                    systemImage: "clock",
                    description: Text("요약한 내용이 여기 저장돼요")
                )
            } else {
                List {
                    ForEach(records) { record in
                        NavigationLink(destination: HistoryDetailView(record: record)) {
                            HistoryRowView(record: record)
                        }
                    }
                    .onDelete(perform: deleteRecords)
                }
                .listStyle(.plain)
                .background(JTheme.background)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("기록")
        .toolbar {
            EditButton()
        }
        .tint(JTheme.accent)
    }

    private func deleteRecords(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

struct HistoryRowView: View {
    let record: SummaryRecord

    var body: some View {
        HStack(spacing: JTheme.spaceS) {
            JIconBadge(systemName: record.inputType == .audio ? "mic.fill" : "camera.fill", size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(JTheme.body().weight(.semibold))
                    .lineLimit(1)
                Text(record.summary)
                    .font(JTheme.caption())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct HistoryDetailView: View {
    let record: SummaryRecord

    var body: some View {
        ZStack {
            JTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: JTheme.spaceM) {
                    if let data = record.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: JTheme.radiusM, style: .continuous))
                    }

                    JCard {
                        VStack(alignment: .leading, spacing: JTheme.spaceXS) {
                            JSectionLabel(icon: "text.alignleft", text: "요약")
                            Text(record.summary)
                                .font(JTheme.body())
                        }
                    }

                    if !record.keyPoints.isEmpty {
                        JCard {
                            VStack(alignment: .leading, spacing: JTheme.spaceXS) {
                                JSectionLabel(icon: "list.bullet", text: "핵심 포인트")
                                ForEach(record.keyPoints, id: \.self) { point in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•").foregroundStyle(JTheme.accent)
                                        Text(point).font(JTheme.body())
                                    }
                                }
                            }
                        }
                    }

                    JCard {
                        DisclosureGroup("원문 보기") {
                            Text(record.originalText)
                                .font(JTheme.caption())
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }
                        .tint(.primary)
                    }
                }
                .padding(JTheme.spaceM)
            }
        }
        .navigationTitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
