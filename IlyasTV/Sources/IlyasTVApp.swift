import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@main
struct IlyasTVApp: App {
    init() {
        configureAudioSession()
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }

    private func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .duckOthers])
        } catch {
            print("Audio session configuration error: \(error.localizedDescription)")
        }
        #endif
    }

    private func setupAppearance() {
        #if canImport(UIKit) && !os(macOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 22/255, alpha: 1.0)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 15/255, green: 15/255, blue: 18/255, alpha: 1.0)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        #endif
    }
}
