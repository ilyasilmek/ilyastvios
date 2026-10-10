import SwiftUI

public struct LegalDisclaimerSheet: View {
    public let onAccept: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(AppColors.brandAmber)
                .padding(.top, 10)

            Text("Yasal Uyarı & Sorumluluk Reddi")
                .font(.title2.bold())
                .foregroundColor(.white)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("• **İlyasTV**, kullanıcının kendi sağladığı yasal M3U / IPTV bağlantılarını ve medya akışlarını oynatmak üzere geliştirilmiş bağımsız bir medya oynatıcı arayüzüdür.")
                    Text("• Uygulama bünyesinde telif hakkına tabi hiçbir canlı TV yayını, film, dizi veya ses içeriği barındırılmaz, dağıtılmaz ya da sunulmaz.")
                    Text("• Eklenen içeriklerin telif hakları ve yasal sorumluluğu tamamen oynatma listesini ekleyen kullanıcıya aittir.")
                    Text("• Uygulama, korsan veya yetkisiz içerik dağıtımını hiçbir şekilde desteklemez.")
                }
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .padding()
                .background(AppColors.cardDark)
                .cornerRadius(14)
            }

            Button(action: onAccept) {
                Text("Okudum, Anladım ve Kabul Ediyorum")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.liveRed)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(AppColors.backgroundDark)
    }
}
