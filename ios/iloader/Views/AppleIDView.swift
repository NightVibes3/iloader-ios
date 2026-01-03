import SwiftUI

struct AppleIDView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject var accountService = AccountService.shared
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color(hex: "0f172a").ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple ID")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Sign in to manage your certificates and sideload apps.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EMAIL")
                                    .font(.caption2.bold())
                                    .foregroundColor(.gray)
                                TextField("appleid@example.com", text: $email)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                            }

                            Divider().background(.white.opacity(0.1))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("PASSWORD")
                                    .font(.caption2.bold())
                                    .foregroundColor(.gray)
                                SecureField("Required", text: $password)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .textContentType(.password)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ANISETTE SERVER")
                            .font(.caption2.bold())
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        GlassCard {
                            HStack {
                                Text("Current:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(appState.anisetteServer)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                if showingError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()

                Button(action: performLogin) {
                    HStack {
                        if accountService.isLoggingIn {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text(accountService.isLoggingIn ? "Signing In..." : "Sign In")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.blue
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(email.isEmpty || password.isEmpty || accountService.isLoggingIn)

                Text(
                    "Your credentials are sent directly to Apple (or your chosen anisette server) and are never stored on iloader servers."
                )
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(24)
        }
    }

    private func performLogin() {
        Task {
            let result = await accountService.login(
                email: email,
                password: password,
                anisetteServer: appState.anisetteServer,
                save: true
            )

            switch result {
            case .success(let email):
                appState.loggedInAs = email
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}
struct AppleIDView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlassCard {
                AppleIDView()
            }
            .padding()
        }
    }
}
