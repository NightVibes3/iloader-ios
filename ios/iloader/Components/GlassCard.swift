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
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
