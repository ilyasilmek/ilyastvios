import SwiftUI

public struct SearchScreen: View {
    @EnvironmentObject private var viewModel: IptvViewModel

    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)
                        TextField("Kanal, film veya dizi ara...", text: $viewModel.searchQuery)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()

                        if !viewModel.searchQuery.isEmpty {
                            Button(action: { viewModel.searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(AppColors.cardDark)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Recent Searches
                    if viewModel.searchQuery.isEmpty && !viewModel.searchHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Son Aramalar")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Button("Temizle") {
                                    StorageManager.shared.clearSearchHistory()
                                }
                                .font(.caption)
                                .foregroundColor(AppColors.liveRed)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.searchHistory, id: \.self) { term in
                                        Button(action: { viewModel.searchQuery = term }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "clock")
                                                    .font(.caption2)
                                                Text(term)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppColors.surfaceDark)
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Search Results
                    if viewModel.searchQuery.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(AppColors.textMuted)
                            Text("Arama Yapın")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Tüm canlı kanallar, filmler ve diziler arasında arama yapabilirsiniz.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else if viewModel.globalSearchResults.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(AppColors.textMuted)
                            Text("Sonuç Bulunamadı")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("“\(viewModel.searchQuery)” ile eşleşen kanal veya video bulunamadı.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        List(viewModel.globalSearchResults) { item in
                            ChannelListCard(
                                channel: item,
                                isCurrentlyPlaying: viewModel.currentlyPlayingChannel?.id == item.id,
                                onPlay: {
                                    StorageManager.shared.addSearchQuery(viewModel.searchQuery)
                                    viewModel.playChannel(item)
                                },
                                onToggleFavorite: { viewModel.toggleFavorite(item) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("🔍 Arama")
        }
    }
}
