import SwiftUI
import AVKit
import Combine
#if canImport(MediaPlayer)
import MediaPlayer
#endif
#if canImport(UIKit)
import UIKit
#endif

public struct StreamPlayerView: View {
    public let channel: ChannelItem
    public let onBack: () -> Void
    public let onNext: () -> Void
    public let onPrevious: () -> Void

    @EnvironmentObject private var viewModel: IptvViewModel

    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showControls = true
    @State private var controlsTimer: Timer?

    // Gestures State
    @State private var brightness: CGFloat = 0.5
    @State private var volume: Float = 0.5
    @State private var showBrightnessOverlay = false
    @State private var showVolumeOverlay = false
    @State private var forward10Animation = false
    @State private var replay10Animation = false

    // Player Options State
    @State private var videoGravity: AVLayerVideoGravity = .resizeAspect
    @State private var playbackRate: Float = 1.0
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isSeeking = false

    // Sheets
    @State private var showTmdbSheet = false
    @State private var showSubtitleSheet = false
    @State private var showCatchupSheet = false
    @State private var showSpeedMenu = false
    @State private var customSubtitleText: String? = nil

    // Intro / Next Episode
    @State private var showSkipIntro = false
    @State private var showNextEpisodeCard = false

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Video Player Layer
            if let player = player {
                CustomVideoPlayer(player: player, videoGravity: videoGravity)
                    .ignoresSafeArea()
            } else {
                ProgressView().tint(AppColors.liveRed)
            }

            // Custom Subtitle Overlay
            if let subText = customSubtitleText {
                VStack {
                    Spacer()
                    Text(subText)
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(8)
                        .padding(.bottom, showControls ? 110 : 30)
                }
            }

            // Touch Gestures Layer (Left = Brightness, Right = Volume, Double tap = Seek)
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Left Side: Brightness & -10s Seek
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    #if os(iOS)
                                    let delta = -value.translation.height / 300.0
                                    let newB = min(1.0, max(0.0, brightness + delta))
                                    UIScreen.main.brightness = newB
                                    brightness = newB
                                    showBrightnessOverlay = true
                                    #endif
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        showBrightnessOverlay = false
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            seek(by: -10)
                            withAnimation { replay10Animation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { replay10Animation = false }
                        }
                        .onTapGesture(count: 1) {
                            toggleControls()
                        }

                    // Right Side: Volume & +10s Seek
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    #if os(iOS)
                                    let delta = Float(-value.translation.height / 300.0)
                                    let newV = min(1.0, max(0.0, volume + delta))
                                    setSystemVolume(newV)
                                    volume = newV
                                    showVolumeOverlay = true
                                    #endif
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        showVolumeOverlay = false
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            seek(by: 10)
                            withAnimation { forward10Animation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { forward10Animation = false }
                        }
                        .onTapGesture(count: 1) {
                            toggleControls()
                        }
                }
            }

            // Double Tap Seek Ripple Overlays
            if replay10Animation {
                HStack {
                    VStack(spacing: 6) {
                        Image(systemName: "gobackward.10").font(.system(size: 40))
                        Text("-10 sn").font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .padding(.leading, 60)
                    Spacer()
                }
            }

            if forward10Animation {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "goforward.10").font(.system(size: 40))
                        Text("+10 sn").font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .padding(.trailing, 60)
                }
            }

            // Gesture Level Overlays (Brightness / Volume)
            if showBrightnessOverlay {
                VStack(spacing: 8) {
                    Image(systemName: "sun.max.fill").font(.title)
                    ProgressView(value: Double(brightness), total: 1.0).frame(width: 100)
                }
                .foregroundColor(.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.75)))
            }

            if showVolumeOverlay {
                VStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill").font(.title)
                    ProgressView(value: Double(volume), total: 1.0).frame(width: 100)
                }
                .foregroundColor(.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.75)))
            }

            // Binge-Watch: Skip Intro Button (+85s)
            if showSkipIntro {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: skipIntro) {
                            HStack(spacing: 6) {
                                Image(systemName: "forward.end.fill")
                                Text("Jeneriği Atla (+85sn)")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.85))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.brandAmber, lineWidth: 1.5))
                            .cornerRadius(10)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, showControls ? 100 : 40)
                    }
                }
            }

            // Binge-Watch: Next Episode Alert Card
            if showNextEpisodeCard, let nextEp = viewModel.getNextEpisode() {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sıradaki Bölüm")
                                .font(.caption2.bold())
                                .foregroundColor(AppColors.brandAmber)
                            Text(nextEp.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Button("Hemen Geç") {
                                viewModel.playNextEpisode()
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.liveRed)
                            .cornerRadius(8)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.surfaceDark).shadow(radius: 10))
                        .padding(.trailing, 24)
                        .padding(.bottom, showControls ? 100 : 40)
                    }
                }
            }

            // Player Controls Overlay
            if showControls {
                VStack {
                    // Top Bar
                    HStack(spacing: 14) {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(channel.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                if channel.streamType == "LIVE" {
                                    HStack(spacing: 4) {
                                        Circle().fill(AppColors.liveRed).frame(width: 6, height: 6)
                                        Text("CANLI")
                                            .font(.caption2.bold())
                                            .foregroundColor(AppColors.liveRed)
                                    }
                                }
                                Text(channel.groupTitle)
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        Spacer()

                        // PVR Live Recording Button
                        if channel.streamType == "LIVE" {
                            Button(action: { viewModel.togglePvrRecording(channel: channel) }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(viewModel.pvrRecordingState.isRecording ? Color.red : Color.gray)
                                        .frame(width: 8, height: 8)
                                    Text(viewModel.pvrRecordingState.isRecording ? viewModel.pvrRecordingState.elapsedSecondsFormatted : "REC")
                                        .font(.caption2.bold())
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.7)))
                            }
                        }

                        // Catch-Up Button (for Live)
                        if channel.streamType == "LIVE" {
                            Button(action: { showCatchupSheet = true }) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                        }

                        // Subtitles Button
                        Button(action: { showSubtitleSheet = true }) {
                            Image(systemName: "captions.bubble")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }

                        // Aspect Ratio Toggle
                        Button(action: toggleAspectRatio) {
                            Image(systemName: videoGravity == .resizeAspect ? "viewfinder" : "aspectratio.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }

                        // TMDb Info Button
                        Button(action: { showTmdbSheet = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // Center Play / Pause / Skip
                    HStack(spacing: 40) {
                        Button(action: onPrevious) {
                            Image(systemName: "backward.end.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }

                        Button(action: togglePlayPause) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Circle().fill(AppColors.liveRed))
                        }

                        Button(action: onNext) {
                            Image(systemName: "forward.end.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    // Bottom Bar: Progress Slider & Options
                    VStack(spacing: 8) {
                        if channel.streamType != "LIVE" && duration > 0 {
                            HStack {
                                Text(formatTime(currentTime))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(.white)

                                Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                                    isSeeking = editing
                                    if !editing {
                                        let target = CMTime(seconds: currentTime, preferredTimescale: 600)
                                        player?.seek(to: target)
                                    }
                                })
                                .tint(AppColors.liveRed)

                                Text(formatTime(duration))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        HStack {
                            // Favorite
                            Button(action: { viewModel.toggleFavorite(channel) }) {
                                Image(systemName: channel.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(channel.isFavorite ? AppColors.liveRed : .white)
                            }

                            // Speed Selector
                            Menu {
                                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                                    Button("\(String(format: "%.2fx", rate))") {
                                        playbackRate = Float(rate)
                                        player?.rate = Float(rate)
                                    }
                                }
                            } label: {
                                Text("\(String(format: "%.1fx", playbackRate))")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.2)))
                            }

                            Spacer()

                            // Download VOD
                            if channel.streamType != "LIVE" {
                                Button(action: { viewModel.downloadChannel(channel) }) {
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .background(
                        LinearGradient(colors: [Color.clear, Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    )
                }
            }
        }
        .onAppear {
            setupPlayer()
            #if os(iOS)
            brightness = UIScreen.main.brightness
            volume = AVAudioSession.sharedInstance().outputVolume
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            player?.pause()
            player = nil
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .sheet(isPresented: $showTmdbSheet) {
            TmdbDetailSheet(title: channel.name, isSeries: channel.streamType == "SERIES") {
                showTmdbSheet = false
            }
        }
        .sheet(isPresented: $showSubtitleSheet) {
            OnlineSubtitleSheet(mediaTitle: channel.name, onSelectSubtitleUrl: { fileUrl in
                loadLocalSubtitle(fileUrl)
            }, onDismiss: {
                showSubtitleSheet = false
            })
        }
        .sheet(isPresented: $showCatchupSheet) {
            CatchupSheet(channel: channel) {
                showCatchupSheet = false
            }
        }
    }

    private func setupPlayer() {
        guard let url = URL(string: channel.streamUrl) else { return }
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        // Kaldığı yerden devam et
        if channel.playbackPositionMs > 5000 {
            let resumeSec = Double(channel.playbackPositionMs) / 1000.0
            avPlayer.seek(to: CMTime(seconds: resumeSec, preferredTimescale: 600))
        }

        avPlayer.play()
        isPlaying = true
        resetControlsTimer()

        // Time Observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
            guard !isSeeking else { return }
            let sec = time.seconds
            currentTime = sec
            if let dur = avPlayer.currentItem?.duration.seconds, !dur.isNaN && dur > 0 {
                duration = dur
                viewModel.updatePlaybackProgress(channelId: channel.id, positionMs: Int64(sec * 1000), durationMs: Int64(dur * 1000))

                // Binge-Watch Skip Intro (ilk 2 dakikada göster)
                showSkipIntro = channel.streamType == "SERIES" && sec >= 5 && sec <= 120

                // Binge-Watch Next Episode (son 35 saniyede göster)
                showNextEpisodeCard = channel.streamType == "SERIES" && dur - sec <= 35 && dur > 60
            }
        }
    }

    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            player?.rate = playbackRate
            isPlaying = true
        }
        resetControlsTimer()
    }

    private func seek(by seconds: Double) {
        guard let p = player else { return }
        let target = CMTime(seconds: max(0, p.currentTime().seconds + seconds), preferredTimescale: 600)
        p.seek(to: target)
        resetControlsTimer()
    }

    private func skipIntro() {
        seek(by: 85)
        showSkipIntro = false
    }

    private func toggleAspectRatio() {
        videoGravity = (videoGravity == .resizeAspect) ? .resizeAspectFill : .resizeAspect
    }

    private func toggleControls() {
        withAnimation { showControls.toggle() }
        if showControls { resetControlsTimer() }
    }

    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation { showControls = false }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let s = Int(seconds)
        let hrs = s / 3600
        let mins = (s % 3600) / 60
        let secs = s % 60
        return hrs > 0 ? String(format: "%02d:%02d:%02d", hrs, mins, secs) : String(format: "%02d:%02d", mins, secs)
    }

    private func setSystemVolume(_ val: Float) {
        #if canImport(MediaPlayer) && os(iOS)
        let volumeView = MPVolumeView()
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                slider.value = val
            }
        }
        #endif
    }

    private func loadLocalSubtitle(_ fileUrl: URL) {
        guard let text = try? String(contentsOf: fileUrl) else { return }
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let firstSub = lines.first(where: { !$0.contains("-->") && Int($0) == nil }) {
            customSubtitleText = firstSub
        }
    }
}

// Custom AVPlayer View for iOS & macOS
#if os(iOS)
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = videoGravity
        controller.allowsPictureInPicturePlayback = true
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.videoGravity = videoGravity
    }
}
#elseif os(macOS)
struct CustomVideoPlayer: NSViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
#endif
