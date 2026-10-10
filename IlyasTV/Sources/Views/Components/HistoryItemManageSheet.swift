import SwiftUI

public struct HistoryItemManageSheet: View {
    public let channel: ChannelItem
    public let onDismiss: () -> Void
    public let onPlay: () -> Void
    public let onMoveToTop: () -> Void
    public let onRemove: () -> Void
    public let onResetProgress: () -> Void
    public let onToggleFavorite: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                if let logo = channel.logoUrl ?? channel.posterUrl, let url = URL(string: logo) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFit()
                        } else {
                            Image(systemName: "tv").foregroundColor(AppColors.textMuted)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(AppColors.cardDark)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("İzleme Geçmişi Yönetimi")
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
            .padding(.top, 8)

            Divider().background(AppColors.borderDark)

            // Options List
            VStack(spacing: 10) {
                Button(action: { onDismiss(); onPlay() }) {
                    Label("Şimdi Oynat", systemImage: "play.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppColors.cardDark)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { onDismiss(); onMoveToTop() }) {
                    Label("En Başa Taşı", systemImage: "arrow.up.to.line")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppColors.cardDark)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { onDismiss(); onToggleFavorite() }) {
                    Label(channel.isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle", systemImage: channel.isFavorite ? "heart.slash" : "heart.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppColors.cardDark)
                        .foregroundColor(channel.isFavorite ? .white : AppColors.liveRed)
                        .cornerRadius(12)
                }

                if channel.playbackPositionMs > 0 {
                    Button(action: { onDismiss(); onResetProgress() }) {
                        Label("İlerlemeyi Sıfırla (00:00)", systemImage: "gobackward")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(AppColors.cardDark)
                            .foregroundColor(AppColors.brandAmber)
                            .cornerRadius(12)
                    }
                }

                Button(action: { onDismiss(); onRemove() }) {
                    Label("Geçmişten Kaldır", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppColors.cardDark)
                        .foregroundColor(AppColors.liveRed)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(AppColors.surfaceDark)
        .presentationDetents([.fraction(0.55), .medium])
    }
}
