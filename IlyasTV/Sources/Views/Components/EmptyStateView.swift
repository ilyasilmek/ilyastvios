import SwiftUI

public struct EmptyStateView: View {
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let buttonText: String?
    public let onActionClick: (() -> Void)?

    public init(
        title: String,
        subtitle: String,
        iconName: String = "tv",
        buttonText: String? = nil,
        onActionClick: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.buttonText = buttonText
        self.onActionClick = onActionClick
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(AppColors.brandAmber)
                .padding()
                .background(Circle().fill(AppColors.cardDark))

            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let btn = buttonText, let action = onActionClick {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(btn)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppColors.liveRed)
                    .cornerRadius(12)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
