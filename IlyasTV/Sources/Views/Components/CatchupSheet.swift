import SwiftUI

public struct CatchupSheet: View {
    public let channel: ChannelItem
    public let onDismiss: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("⏪ Catch-Up (Geçmiş Yayınlar)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            VStack(spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.brandAmber)

                Text("Yayın Akışı (EPG) Bilgisi Bulunmuyor")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("Bu kanal için geçmiş yayın akışı listesi henüz mevcut değil. XMLTV / EPG sağlayıcısı entegrasyonu tamamlandığında geçmiş programlar burada listelenecektir.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)

            Button("Kapat", action: onDismiss)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.cardDark)
                .cornerRadius(12)
        }
        .padding(24)
        .background(AppColors.surfaceDark)
        .presentationDetents([.fraction(0.45)])
    }
}
