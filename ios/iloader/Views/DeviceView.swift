import SwiftUI

struct DeviceView: View {
    let deviceName: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Device Icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "iphone")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(deviceName ?? "Detection Error")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text("iPhone 15 Pro")
                        .font(.caption)
                    Circle().frame(width: 3, height: 3)
                    Text("iOS 17.5")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlassCard {
                DeviceView(deviceName: "My iPhone")
            }
            .padding()
        }
    }
}
