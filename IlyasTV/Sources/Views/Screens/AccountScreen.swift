import SwiftUI
import UniformTypeIdentifiers

public struct AccountScreen: View {
    @EnvironmentObject private var viewModel: IptvViewModel

    @State private var selectedTab = 0 // 0: Xtream, 1: M3U Link, 2: M3U File
    @State private var xtreamServer = ""
    @State private var xtreamUser = ""
    @State private var xtreamPass = ""

    @State private var m3uName = ""
    @State private var m3uUrl = ""

    @State private var showFilePicker = false
    @State private var showLegalDisclaimer = false
    @State private var showDeleteAllAlert = false

    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Active Account Overview Card
                        if let acc = viewModel.latestAccountInfo {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(acc.username ?? "IPTV Kullanıcısı")
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                        Text(acc.serverHost ?? "Sunucu")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Text(acc.status)
                                        .font(.caption.bold())
                                        .foregroundColor(acc.isExpired ? .red : AppColors.brandGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background((acc.isExpired ? Color.red : AppColors.brandGreen).opacity(0.15))
                                        .cornerRadius(8)
                                }

                                Divider().background(AppColors.borderDark)

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Kalan Süre")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text(acc.remainingTimeText)
                                            .font(.caption.bold())
                                            .foregroundColor(AppColors.brandAmber)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Bitiş Tarihi")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textSecondary)
                                        Text(acc.expirationDateText)
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(20)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.surfaceDark))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.borderDark, lineWidth: 1))
                            .padding(.horizontal)
                        }

                        // 2. Add Playlist / Connect Account Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Yeni Playlist / IPTV Hesabı Ekle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            Picker("", selection: $selectedTab) {
                                Text("Xtream Codes").tag(0)
                                Text("M3U URL").tag(1)
                                Text("Dosya Yükle").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)

                            VStack(spacing: 12) {
                                if selectedTab == 0 {
                                    // Xtream Input
                                    TextField("Sunucu Adresi (örn: http://iptv.tv:8080)", text: $xtreamServer)
                                        .autocorrectionDisabled()
                                        .padding(12)
                                        .background(AppColors.cardDark)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)

                                    TextField("Kullanıcı Adı", text: $xtreamUser)
                                        .autocorrectionDisabled()
                                        .padding(12)
                                        .background(AppColors.cardDark)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)

                                    SecureField("Şifre", text: $xtreamPass)
                                        .padding(12)
                                        .background(AppColors.cardDark)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)

                                    Button(action: {
                                        viewModel.importXtreamAccount(server: xtreamServer, user: xtreamUser, pass: xtreamPass)
                                    }) {
                                        HStack {
                                            Image(systemName: "link")
                                            Text("Xtream Hesabını Bağla")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.liveRed)
                                        .cornerRadius(12)
                                    }
                                } else if selectedTab == 1 {
                                    // M3U URL Input
                                    TextField("Liste Adı (İsteğe bağlı)", text: $m3uName)
                                        .padding(12)
                                        .background(AppColors.cardDark)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)

                                    TextField("M3U / M3U8 Bağlantısı (http...)", text: $m3uUrl)
                                        .autocorrectionDisabled()
                                        .padding(12)
                                        .background(AppColors.cardDark)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)

                                    Button(action: {
                                        viewModel.importPlaylistFromUrl(name: m3uName, url: m3uUrl)
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.doc.fill")
                                            Text("M3U Linkini İndir & Kaydet")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.liveRed)
                                        .cornerRadius(12)
                                    }
                                } else {
                                    // M3U File Picker
                                    VStack(spacing: 12) {
                                        Button(action: { showFilePicker = true }) {
                                            HStack {
                                                Image(systemName: "doc.badge.plus")
                                                Text(".m3u veya .m3u8 Dosyası Seç")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(AppColors.brandBlue)
                                            .cornerRadius(12)
                                        }
                                    }
                                }

                                if case .loading = viewModel.importState {
                                    HStack {
                                        ProgressView().tint(AppColors.liveRed)
                                        Text("Liste indiriliyor ve ayrıştırılıyor...")
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding(.top, 6)
                                } else if case .success(let msg, _) = viewModel.importState {
                                    Text("✅ \(msg)")
                                        .font(.caption.bold())
                                        .foregroundColor(AppColors.brandGreen)
                                        .padding(.top, 4)
                                } else if case .error(let err) = viewModel.importState {
                                    Text("❌ \(err)")
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(18)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.surfaceDark))
                            .padding(.horizontal)
                        }

                        // 3. Playlists Management Section
                        if !viewModel.playlists.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Kayıtlı Oynatma Listeleri (\(viewModel.playlists.count))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                ForEach(viewModel.playlists) { pl in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(pl.name)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            HStack(spacing: 8) {
                                                Text("\(pl.channelCount) İçerik")
                                                    .font(.caption2)
                                                    .foregroundColor(AppColors.brandAmber)
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundColor(AppColors.textMuted)
                                                Text("\(pl.liveCount) Canlı / \(pl.movieCount) Film")
                                                    .font(.caption2)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                        }
                                        Spacer()

                                        Button(action: { viewModel.refreshPlaylist(playlistId: pl.id) }) {
                                            Image(systemName: "arrow.clockwise")
                                                .foregroundColor(AppColors.brandBlue)
                                                .padding(6)
                                        }

                                        Button(action: { viewModel.deletePlaylist(id: pl.id) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(AppColors.liveRed)
                                                .padding(6)
                                        }
                                    }
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.surfaceDark))
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // 4. TMDb & Player Settings Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Ayarlar & Özelleştirme")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            VStack(spacing: 16) {
                                // Buffer Option
                                HStack {
                                    Text("Arabellek Modu")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("", selection: $viewModel.bufferSetting) {
                                        ForEach(BufferOption.allCases, id: \.self) { opt in
                                            Text(opt.label).tag(opt)
                                        }
                                    }
                                    .tint(AppColors.brandAmber)
                                }

                                // Theme Brand Style
                                HStack {
                                    Text("Tema Rengi")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("", selection: $viewModel.brandStyle) {
                                        ForEach(ThemeBrandStyle.allCases, id: \.self) { style in
                                            Text(style.title).tag(style)
                                        }
                                    }
                                    .tint(AppColors.liveRed)
                                }

                                // TMDb API Key Input
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("TMDb API Anahtarı")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    TextField("API Anahtarı (Opsiyonel)", text: $viewModel.tmdbApiKey)
                                        .autocorrectionDisabled()
                                        .padding(10)
                                        .background(AppColors.cardDark)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    Text("Film ve dizi afişleri, özet ve puanlarını çekmek için.")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                }

                                Divider().background(AppColors.borderDark)

                                // Legal Disclaimer Button
                                Button(action: { showLegalDisclaimer = true }) {
                                    HStack {
                                        Image(systemName: "checkmark.shield")
                                        Text("Yasal Uyarı & Sorumluluk Reddi")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                }
                            }
                            .padding(18)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.surfaceDark))
                            .padding(.horizontal)
                        }

                        // 5. Data Reset Section
                        VStack(spacing: 10) {
                            Button("Favorileri Temizle") {
                                viewModel.clearAllFavorites()
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(AppColors.cardDark)
                            .cornerRadius(10)

                            Button("İzleme Geçmişini Temizle") {
                                viewModel.clearWatchHistory()
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(AppColors.cardDark)
                            .cornerRadius(10)

                            Button("Tüm Verileri ve Listeleri Sıfırla") {
                                showDeleteAllAlert = true
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.liveRed)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(AppColors.liveRed.opacity(0.15))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("⚙️ Hesap & Ayarlar")
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.item]) { result in
                switch result {
                case .success(let url):
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let content = try? String(contentsOf: url) {
                            viewModel.importPlaylistContent(name: url.deletingPathExtension().lastPathComponent, content: content, isFile: true)
                        }
                    }
                case .failure(let err):
                    viewModel.importState = .error(message: "Dosya açılamadı: \(err.localizedDescription)")
                }
            }
            .sheet(isPresented: $showLegalDisclaimer) {
                LegalDisclaimerSheet {
                    showLegalDisclaimer = false
                }
            }
            .alert("Tüm Veriler Silinsin mi?", isPresented: $showDeleteAllAlert) {
                Button("İptal", role: .cancel) {}
                Button("Tümünü Sil", role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text("Kayıtlı tüm oynatma listeleri, indirmeler ve ayarlar cihazınızdan silinecektir.")
            }
        }
    }
}
