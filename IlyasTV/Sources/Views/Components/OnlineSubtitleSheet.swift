import SwiftUI

public struct OnlineSubtitleSheet: View {
    public let mediaTitle: String
    public let onSelectSubtitleUrl: (URL) -> Void
    public let onDismiss: () -> Void

    @State private var selectedLanguage = "tr"
    @State private var results: [SubtitleItem] = []
    @State private var isSearching = false
    @State private var downloadingSubId: String? = nil
    @State private var errorMessage: String? = nil

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Çevrimiçi Altyazı Arama")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("SubDL API Entegrasyonu")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Language Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SubtitleService.supportedLanguages) { lang in
                        Button(action: {
                            selectedLanguage = lang.code
                            performSearch()
                        }) {
                            Text(lang.name)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedLanguage == lang.code ? AppColors.liveRed : AppColors.cardDark)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                }
            }

            Divider().background(AppColors.borderDark)

            // Results List
            if isSearching {
                VStack(spacing: 12) {
                    ProgressView().tint(AppColors.liveRed)
                    Text("Altyazılar aranıyor...")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textMuted)
                    Text("Bu dilde altyazı bulunamadı")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Farklı bir dil seçebilir veya başlığı kontrol edebilirsiniz.")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List(results) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .lineLimit(2)
                            HStack {
                                Text(item.language)
                                    .font(.caption2)
                                    .foregroundColor(AppColors.brandAmber)
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textMuted)
                                Text(item.sourceName)
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        Spacer()

                        if downloadingSubId == item.id {
                            ProgressView().tint(AppColors.liveRed)
                        } else {
                            Button("İndir & Uygula") {
                                downloadAndApply(item: item)
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.liveRed)
                            .cornerRadius(8)
                        }
                    }
                    .listRowBackground(AppColors.surfaceDark)
                }
                .listStyle(PlainListStyle())
            }
        }
        .padding(20)
        .background(AppColors.backgroundDark)
        .presentationDetents([.fraction(0.65), .large])
        .onAppear {
            performSearch()
        }
    }

    private func performSearch() {
        isSearching = true
        results = []
        Task {
            let res = await SubtitleService.searchSubtitles(title: mediaTitle, languageCode: selectedLanguage)
            results = res
            isSearching = false
        }
    }

    private func downloadAndApply(item: SubtitleItem) {
        downloadingSubId = item.id
        Task {
            if let fileUrl = await SubtitleService.downloadSubtitleFile(item: item) {
                onSelectSubtitleUrl(fileUrl)
                onDismiss()
            }
            downloadingSubId = nil
        }
    }
}
