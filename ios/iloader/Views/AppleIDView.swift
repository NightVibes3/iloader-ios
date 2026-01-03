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

                // Saved Accounts List
                if !accountService.accounts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SAVED ACCOUNTS")
                            .font(.caption2.bold())
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        ForEach(accountService.accounts) { account in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(account.appleId)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        if appState.loggedInAs == account.appleId {
                                            Text("Active")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                    }

                                    Spacer()

                                    if appState.loggedInAs != account.appleId {
                                        Button("Switch") {
                                            accountService.switchAccount(to: account.appleId)
                                        }
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.3))
                                        .cornerRadius(8)
                                    }

                                    Button(action: {
                                        accountService.removeAccount(email: account.appleId)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                        }
                    }
                }

                // Header for Form
                if accountService.accounts.isEmpty || !appState.loggedInAs!.isEmpty {  // Show form if no accounts or explicitly adding (logic adjustment needed if "Adding" state exists, but for now show below list)
                    Text("ADD ACCOUNT")
                        .font(.caption2.bold())
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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
                        Text(accountService.isLoggingIn ? "Verifying..." : "Add Account")
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
            let result = await accountService.addAccount(
                email: email,
                password: password,
                anisetteServer: appState.anisetteServer
            )

            switch result {
            case .success(let email):
                // Account added and switched automatically
                self.email = ""
                self.password = ""
            // Don't dismiss immediately so they can see it added, or dismiss?
            // dismiss()
            // Let's keep it open to show the list updated
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
