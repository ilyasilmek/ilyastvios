import SwiftUI

public struct LiveTvScreen: View {
    @EnvironmentObject private var viewModel: IptvViewModel
    @State private var selectedHistoryChannel: ChannelItem?

    let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()

                if viewModel.liveChannels.isEmpty {
                    EmptyStateView(
                        title: "Canlı TV Kanalları Bulunamadı",
                        subtitle: "Canlı yayınları izlemek için IPTV linkinizi (.m3u / Xtream) girin veya dosyanızı yükleyin.",
                        iconName: "tv.fill",
                        buttonText: "+ Liste / Hesap Ekle",
                        onActionClick: {
                            // Account tab selection
                        }
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Watch History Section (Son İzlenenler)
                            if !viewModel.watchHistoryList.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(AppColors.brandAmber)
                                        Text("Son İzlenen Kanallar")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(viewModel.watchHistoryList.prefix(10)) { ch in
                                                VStack(alignment: .leading, spacing: 6) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(AppColors.cardDark)
                                                        if let logo = ch.logoUrl, let url = URL(string: logo) {
                                                            AsyncImage(url: url) { phase in
                                                                if let img = phase.image {
                                                                    img.resizable().scaledToFit().padding(6)
                                                                } else {
                                                                    Image(systemName: "tv").foregroundColor(AppColors.textMuted)
                                                                }
                                                            }
                                                        } else {
                                                            Image(systemName: "tv").foregroundColor(AppColors.textMuted)
                                                        }
                                                    }
                                                    .frame(width: 90, height: 60)
                                                    .cornerRadius(10)

                                                    Text(ch.name)
                                                        .font(.caption2.bold())
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                        .frame(width: 90, alignment: .leading)
                                                }
                                                .onTapGesture {
                                                    viewModel.playChannel(ch)
                                                }
                                                .onLongPressGesture {
                                                    selectedHistoryChannel = ch
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            // Categories Filter Bar
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.liveCategories, id: \.self) { cat in
                                        Button(action: { viewModel.selectedLiveCategory = cat }) {
                                            Text(cat)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(viewModel.selectedLiveCategory == cat ? AppColors.liveRed : AppColors.surfaceDark)
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(AppColors.borderDark, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // View Mode Toggle (Grid vs List) & Count
                            HStack {
                                Text("\(viewModel.filteredLiveChannels.count) Kanal")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                Spacer()

                                Button(action: {
                                    viewModel.viewMode = (viewModel.viewMode == .grid) ? .list : .grid
                                }) {
                                    Image(systemName: viewModel.viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(AppColors.cardDark)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)

                            // Channels List / Grid
                            if viewModel.viewMode == .grid {
                                LazyVGrid(columns: gridColumns, spacing: 14) {
                                    ForEach(viewModel.filteredLiveChannels) { ch in
                                        ChannelGridCard(
                                            channel: ch,
                                            isCurrentlyPlaying: viewModel.currentlyPlayingChannel?.id == ch.id,
                                            onPlay: { viewModel.playChannel(ch) },
                                            onToggleFavorite: { viewModel.toggleFavorite(ch) }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(viewModel.filteredLiveChannels) { ch in
                                        ChannelListCard(
                                            channel: ch,
                                            isCurrentlyPlaying: viewModel.currentlyPlayingChannel?.id == ch.id,
                                            onPlay: { viewModel.playChannel(ch) },
                                            onToggleFavorite: { viewModel.toggleFavorite(ch) }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("📺 Canlı TV")
            .sheet(item: $selectedHistoryChannel) { ch in
                HistoryItemManageSheet(
                    channel: ch,
                    onDismiss: { selectedHistoryChannel = nil },
                    onPlay: { viewModel.playChannel(ch) },
                    onMoveToTop: { viewModel.moveWatchHistoryToTop(channelId: ch.id) },
                    onRemove: { viewModel.removeFromWatchHistory(channelId: ch.id) },
                    onResetProgress: { viewModel.resetPlaybackProgress(channelId: ch.id) },
                    onToggleFavorite: { viewModel.toggleFavorite(ch) }
                )
            }
        }
    }
}
