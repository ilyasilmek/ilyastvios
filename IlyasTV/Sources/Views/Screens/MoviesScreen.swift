import SwiftUI

public struct MoviesScreen: View {
    @EnvironmentObject private var viewModel: IptvViewModel
    @State private var selectedTmdbTitle: String?

    let movieColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()

                if viewModel.movieChannels.isEmpty {
                    EmptyStateView(
                        title: "Film (VOD) Kütüphanesi Boş",
                        subtitle: "M3U oynatma listenizdeki filmleri burada izleyebilir ve cihazınıza indirebilirsiniz.",
                        iconName: "film.fill"
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Continue Watching Section
                            let continueList = viewModel.continueWatchingList.filter { $0.streamType == "MOVIE" }
                            if !continueList.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(AppColors.liveRed)
                                        Text("Kaldığın Yerden Devam Et")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(continueList) { movie in
                                                VStack(alignment: .leading, spacing: 6) {
                                                    ZStack(alignment: .bottom) {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(AppColors.cardDark)
                                                        if let p = movie.posterUrl ?? movie.logoUrl, let url = URL(string: p) {
                                                            AsyncImage(url: url) { phase in
                                                                if let img = phase.image {
                                                                    img.resizable().scaledToFill().clipped()
                                                                }
                                                            }
                                                        }
                                                        if movie.durationMs > 0 {
                                                            ProgressView(value: Double(movie.playbackPositionMs), total: Double(movie.durationMs))
                                                                .tint(AppColors.liveRed)
                                                                .padding(.bottom, 2)
                                                        }
                                                    }
                                                    .frame(width: 120, height: 75)
                                                    .cornerRadius(10)

                                                    Text(movie.name)
                                                        .font(.caption2.bold())
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                        .frame(width: 120, alignment: .leading)
                                                }
                                                .onTapGesture {
                                                    viewModel.playChannel(movie)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            // Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.movieCategories, id: \.self) { cat in
                                        Button(action: { viewModel.selectedMovieCategory = cat }) {
                                            Text(cat)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(viewModel.selectedMovieCategory == cat ? AppColors.liveRed : AppColors.surfaceDark)
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Movie Grid
                            LazyVGrid(columns: movieColumns, spacing: 16) {
                                ForEach(viewModel.filteredMovieChannels) { movie in
                                    ChannelGridCard(
                                        channel: movie,
                                        isCurrentlyPlaying: viewModel.currentlyPlayingChannel?.id == movie.id,
                                        onPlay: { viewModel.playChannel(movie) },
                                        onToggleFavorite: { viewModel.toggleFavorite(movie) },
                                        onInfoClick: { selectedTmdbTitle = movie.name }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("🎬 Filmler")
            .sheet(item: Binding<IdentifiableString?>(
                get: { selectedTmdbTitle.map { IdentifiableString(id: $0) } },
                set: { selectedTmdbTitle = $0?.id }
            )) { str in
                TmdbDetailSheet(title: str.id, isSeries: false) {
                    selectedTmdbTitle = nil
                }
            }
        }
    }
}

public struct IdentifiableString: Identifiable {
    public let id: String
}
