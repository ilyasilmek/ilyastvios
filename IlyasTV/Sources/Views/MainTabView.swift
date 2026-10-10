import SwiftUI
import AVFoundation

public struct MainTabView: View {
    @StateObject private var viewModel = IptvViewModel()
    @State private var selectedTab = 0

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                LiveTvScreen()
                    .tabItem {
                        Label("Canlı TV", systemImage: "tv.fill")
                    }
                    .tag(0)

                MoviesScreen()
                    .tabItem {
                        Label("Filmler", systemImage: "film.fill")
                    }
                    .tag(1)

                SeriesScreen()
                    .tabItem {
                        Label("Diziler", systemImage: "play.tv.fill")
                    }
                    .tag(2)

                DownloadsScreen()
                    .tabItem {
                        Label("İndirilenler", systemImage: "arrow.down.circle.fill")
                    }
                    .tag(3)

                SearchScreen()
                    .tabItem {
                        Label("Arama", systemImage: "magnifyingglass")
                    }
                    .tag(4)

                AccountScreen()
                    .tabItem {
                        Label("Hesap", systemImage: "person.crop.circle.fill")
                    }
                    .tag(5)
            }
            .tint(viewModel.brandStyle.primaryColor)

            // Toast Message Banner
            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.85)).shadow(radius: 8))
                    .padding(.bottom, 65)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                viewModel.toastMessage = nil
                            }
                        }
                    }
            }
        }
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
        #if os(iOS)
        .fullScreenCover(item: $viewModel.currentlyPlayingChannel) { channel in
            StreamPlayerView(
                channel: channel,
                onBack: { viewModel.stopPlayback() },
                onNext: { viewModel.playNextChannel() },
                onPrevious: { viewModel.playPreviousChannel() }
            )
            .environmentObject(viewModel)
        }
        #else
        .sheet(item: $viewModel.currentlyPlayingChannel) { channel in
            StreamPlayerView(
                channel: channel,
                onBack: { viewModel.stopPlayback() },
                onNext: { viewModel.playNextChannel() },
                onPrevious: { viewModel.playPreviousChannel() }
            )
            .environmentObject(viewModel)
        }
        #endif
        .sheet(isPresented: Binding<Bool>(
            get: { !viewModel.hasAcceptedDisclaimer },
            set: { _ in }
        )) {
            LegalDisclaimerSheet {
                viewModel.acceptDisclaimer()
            }
            .interactiveDismissDisabled(true)
        }
    }
}
