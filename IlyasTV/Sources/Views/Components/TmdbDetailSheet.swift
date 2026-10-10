import SwiftUI

public struct TmdbDetailSheet: View {
    public let title: String
    public let isSeries: Bool
    public let onDismiss: () -> Void

    @State private var metadata: TmdbMetadata?
    @State private var isLoading = true

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Bar
                HStack {
                    Text("Yapım Detayları")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(AppColors.liveRed)
                        Text("TMDb bilgileri getiriliyor...")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let meta = metadata {
                    // Backdrop or Poster
                    if let backdrop = meta.backdropUrl ?? meta.posterUrl, let url = URL(string: backdrop) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image {
                                img.resizable()
                                    .scaledToFill()
                                    .frame(height: 180)
                                    .clipped()
                                    .cornerRadius(14)
                            }
                        }
                    }

                    // Title & Rating
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meta.title)
                                .font(.title3.bold())
                                .foregroundColor(.white)

                            if let year = meta.releaseYear {
                                Text(year)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(AppColors.brandAmber)
                            Text(String(format: "%.1f", meta.rating))
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.cardDark)
                        .cornerRadius(10)
                    }

                    // Genres
                    if !meta.genres.isEmpty {
                        HStack {
                            ForEach(meta.genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption2.bold())
                                    .foregroundColor(AppColors.brandAmber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColors.brandAmber.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                    }

                    // Overview
                    Text("Özet")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    Text(meta.overview ?? "Özet açıklaması hazırlanıyor.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(4)

                    // Trailer Button
                    if let trailer = meta.trailerUrl, let url = URL(string: trailer) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                Text("Fragmanı YouTube'da İzle")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "film")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textMuted)
                        Text("TMDb Bilgisi Bulunamadı")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("TMDb API anahtarı girilmemiş veya arama sonucunda yapım eşleşmedi.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(24)
        }
        .background(AppColors.backgroundDark)
        .presentationDetents([.fraction(0.7), .large])
        .task {
            metadata = await TmdbService.shared.getMetadata(title: title, isSeries: isSeries)
            isLoading = false
        }
    }
}
