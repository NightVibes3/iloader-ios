import SwiftUI

struct AppleIDView: View {
    @Binding var loggedInAs: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Icon
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 48, height: 48)
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let email = loggedInAs {
                    Text(email)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Developer Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not Signed In")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Enter Apple ID to start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                if loggedInAs != nil {
                    loggedInAs = nil
                } else {
                    // Logic to show login sheet
                }
            }) {
                Text(loggedInAs != nil ? "Sign Out" : "Sign In")
                    .font(.footnote).bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(loggedInAs != nil ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(loggedInAs != nil ? .red : .blue)
            }
        }
    }
}

struct AppleIDView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlassCard {
                AppleIDView(loggedInAs: .constant("nab138@example.com"))
            }
            .padding()
        }
    }
}
