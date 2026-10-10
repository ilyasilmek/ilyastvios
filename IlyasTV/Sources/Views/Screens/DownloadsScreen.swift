import SwiftUI

public struct DownloadsScreen: View {
    @EnvironmentObject private var viewModel: IptvViewModel

    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()

                if viewModel.downloads.isEmpty && !viewModel.pvrRecordingState.isRecording {
                    EmptyStateView(
                        title: "İndirilen veya Kaydedilen Medya Yok",
                        subtitle: "VOD filmlerini veya canlı TV yayınlarını (PVR) internetsiz izlemek için kaydedebilirsiniz.",
                        iconName: "arrow.down.circle.fill"
                    )
                } else {
                    List {
                        // Active PVR Recording Live Banner
                        if viewModel.pvrRecordingState.isRecording, let ch = viewModel.pvrRecordingState.channel {
                            Section(header: Text("Canlı Yayın Kaydı").foregroundColor(AppColors.brandAmber)) {
                                HStack(spacing: 12) {
                                    Circle().fill(Color.red).frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("🔴 \(ch.name)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(viewModel.pvrRecordingState.elapsedSecondsFormatted) • \(viewModel.pvrRecordingState.recordedBytesFormatted)")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Button("Durdur") {
                                        viewModel.stopPvrRecording()
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.liveRed)
                                    .cornerRadius(8)
                                }
                                .padding(.vertical, 6)
                                .listRowBackground(AppColors.surfaceDark)
                            }
                        }

                        // Completed / In Progress Downloads
                        Section(header: Text("Kayıtlar ve İndirilenler (\(viewModel.downloads.count))").foregroundColor(AppColors.textSecondary)) {
                            ForEach(viewModel.downloads) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.streamType == "PVR" ? "record.circle.fill" : "film.fill")
                                        .font(.title2)
                                        .foregroundColor(item.streamType == "PVR" ? AppColors.liveRed : AppColors.brandAmber)
                                        .frame(width: 44, height: 44)
                                        .background(AppColors.cardDark)
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .lineLimit(1)

                                        HStack(spacing: 6) {
                                            Text(item.groupTitle)
                                                .font(.caption2)
                                                .foregroundColor(AppColors.textSecondary)

                                            if item.status == .downloading {
                                                Text("• %\(item.progressPercent)")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(AppColors.brandAmber)
                                            } else if item.status == .completed {
                                                Text("• Tamamlandı")
                                                    .font(.caption2)
                                                    .foregroundColor(AppColors.brandGreen)
                                            }
                                        }

                                        if item.status == .downloading {
                                            ProgressView(value: Double(item.progressPercent), total: 100.0)
                                                .tint(AppColors.brandAmber)
                                        }
                                    }

                                    Spacer()

                                    if item.status == .completed {
                                        Button(action: { viewModel.playChannel(item.toChannelItem()) }) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(AppColors.liveRed)
                                        }
                                    }

                                    Button(action: { viewModel.deleteDownload(item) }) {
                                        Image(systemName: "trash")
                                            .font(.body)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding(.vertical, 6)
                                .listRowBackground(AppColors.surfaceDark)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("📥 İndirilenler")
        }
    }
}
