import SwiftUI

public struct SeriesScreen: View {
    @EnvironmentObject private var viewModel: IptvViewModel
    @State private var selectedTmdbTitle: String?

    let seriesColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()

                if viewModel.seriesChannels.isEmpty {
                    EmptyStateView(
                        title: "Dizi Kütüphanesi Boş",
                        subtitle: "M3U listenizdeki dizileri ve sezon bölümlerini buradan takip edebilirsiniz.",
                        iconName: "tv.and.mediabox.fill"
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.seriesCategories, id: \.self) { cat in
                                        Button(action: { viewModel.selectedSeriesCategory = cat }) {
                                            Text(cat)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(viewModel.selectedSeriesCategory == cat ? AppColors.liveRed : AppColors.surfaceDark)
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Series Grid
                            LazyVGrid(columns: seriesColumns, spacing: 16) {
                                ForEach(viewModel.filteredSeriesChannels) { series in
                                    ChannelGridCard(
                                        channel: series,
                                        isCurrentlyPlaying: viewModel.currentlyPlayingChannel?.id == series.id,
                                        onPlay: { viewModel.playChannel(series) },
                                        onToggleFavorite: { viewModel.toggleFavorite(series) },
                                        onInfoClick: { selectedTmdbTitle = series.name }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("🍿 Diziler")
            .sheet(item: Binding<IdentifiableString?>(
                get: { selectedTmdbTitle.map { IdentifiableString(id: $0) } },
                set: { selectedTmdbTitle = $0?.id }
            )) { str in
                TmdbDetailSheet(title: str.id, isSeries: true) {
                    selectedTmdbTitle = nil
                }
            }
        }
    }
}
