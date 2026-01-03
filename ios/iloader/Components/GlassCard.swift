import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 16

    init(hPadding: CGFloat = 16, vPadding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.horizontalPadding = hPadding
        self.verticalPadding = vPadding
    }

    var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                ZStack {
                    // Frosted glass base
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)

                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Inner glow/shine at top
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
}
