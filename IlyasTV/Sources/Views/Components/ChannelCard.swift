import SwiftUI

public struct ChannelGridCard: View {
    public let channel: ChannelItem
    public let isCurrentlyPlaying: Bool
    public let onPlay: () -> Void
    public let onToggleFavorite: () -> Void
    public let onInfoClick: (() -> Void)?

    public init(
        channel: ChannelItem,
        isCurrentlyPlaying: Bool = false,
        onPlay: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onInfoClick: (() -> Void)? = nil
    ) {
        self.channel = channel
        self.isCurrentlyPlaying = isCurrentlyPlaying
        self.onPlay = onPlay
        self.onToggleFavorite = onToggleFavorite
        self.onInfoClick = onInfoClick
    }

    public var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Image / Poster
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardDark)

                        if let imgUrl = channel.posterUrl ?? channel.logoUrl, let url = URL(string: imgUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: channel.streamType == "LIVE" ? .fit : .fill)
                                        .padding(channel.streamType == "LIVE" ? 8 : 0)
                                case .failure(_), .empty:
                                    Image(systemName: channel.streamType == "LIVE" ? "tv" : "film")
                                        .font(.title)
                                        .foregroundColor(AppColors.textMuted)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: channel.streamType == "LIVE" ? "tv" : "film")
                                .font(.title)
                                .foregroundColor(AppColors.textMuted)
                        }

                        if isCurrentlyPlaying {
                            ZStack {
                                Color.black.opacity(0.6)
                                HStack(spacing: 4) {
                                    Circle().fill(AppColors.liveRed).frame(width: 8, height: 8)
                                    Text("Oynatılıyor")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(height: channel.streamType == "LIVE" ? 110 : 160)
                    .clipped()
                    .cornerRadius(12)

                    // Favorite Button
                    Button(action: onToggleFavorite) {
                        Image(systemName: channel.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(channel.isFavorite ? AppColors.liveRed : .white.opacity(0.8))
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(6)
                }

                // Title & Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack {
                        Text(channel.groupTitle)
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        Text(channel.quality)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.brandAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.brandAmber.opacity(0.15))
                            .cornerRadius(4)
                    }

                    if channel.playbackPositionMs > 0 && channel.durationMs > 0 {
                        ProgressView(value: Double(channel.playbackPositionMs), total: Double(channel.durationMs))
                            .tint(AppColors.liveRed)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.surfaceDark))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCurrentlyPlaying ? AppColors.liveRed : AppColors.borderDark, lineWidth: isCurrentlyPlaying ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct ChannelListCard: View {
    public let channel: ChannelItem
    public let isCurrentlyPlaying: Bool
    public let onPlay: () -> Void
    public let onToggleFavorite: () -> Void
    public let onInfoClick: (() -> Void)?

    public init(
        channel: ChannelItem,
        isCurrentlyPlaying: Bool = false,
        onPlay: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onInfoClick: (() -> Void)? = nil
    ) {
        self.channel = channel
        self.isCurrentlyPlaying = isCurrentlyPlaying
        self.onPlay = onPlay
        self.onToggleFavorite = onToggleFavorite
        self.onInfoClick = onInfoClick
    }

    public var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.cardDark)

                    if let imgUrl = channel.logoUrl ?? channel.posterUrl, let url = URL(string: imgUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fit).padding(4)
                            default:
                                Image(systemName: "tv").foregroundColor(AppColors.textMuted)
                            }
                        }
                    } else {
                        Image(systemName: "tv").foregroundColor(AppColors.textMuted)
                    }
                }
                .frame(width: 54, height: 54)
                .cornerRadius(10)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(isCurrentlyPlaying ? AppColors.liveRed : .white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(channel.groupTitle)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(AppColors.textMuted)

                        Text(channel.quality)
                            .font(.caption2.bold())
                            .foregroundColor(AppColors.brandAmber)
                    }
                }

                Spacer()

                // Actions
                if let onInfo = onInfoClick {
                    Button(action: onInfo) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.textSecondary)
                            .padding(6)
                    }
                }

                Button(action: onToggleFavorite) {
                    Image(systemName: channel.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(channel.isFavorite ? AppColors.liveRed : AppColors.textSecondary)
                        .padding(6)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.surfaceDark))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isCurrentlyPlaying ? AppColors.liveRed : AppColors.borderDark, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
