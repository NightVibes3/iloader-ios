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

            // 2FA Overlay
            if accountService.requires2FA {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 24) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple], startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )

                    Text("Two-Factor Authentication")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Enter the 6-digit code sent to your trusted devices.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    // 2FA Code Input
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { index in
                            let codeArray = Array(accountService.tfaCode)
                            let char = index < codeArray.count ? String(codeArray[index]) : ""

                            Text(char)
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .frame(width: 44, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }

                    // Hidden text field for input
                    TextField("", text: $accountService.tfaCode)
                        .keyboardType(.numberPad)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onChange(of: accountService.tfaCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                accountService.tfaCode = String(newValue.prefix(6))
                            }
                            // Auto-submit when 6 digits entered
                            if newValue.count == 6 {
                                submit2FA()
                            }
                        }

                    if let error = accountService.loginError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: submit2FA) {
                        HStack {
                            if accountService.isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text(accountService.isLoggingIn ? "Verifying..." : "Verify Code")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            accountService.tfaCode.count == 6 ? Color.blue : Color.gray.opacity(0.3)
                        )
                        .cornerRadius(16)
                    }
                    .disabled(accountService.tfaCode.count != 6 || accountService.isLoggingIn)

                    Button("Cancel") {
                        accountService.requires2FA = false
                        accountService.tfaCode = ""
                    }
                    .foregroundColor(.gray)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: accountService.requires2FA)
    }

    private func performLogin() {
        Task {
            let result = await accountService.addAccount(
                email: email,
                password: password,
                anisetteServer: appState.anisetteServer
            )

            switch result {
            case .success(_):
                self.email = ""
                self.password = ""
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func submit2FA() {
        Task {
            let result = await accountService.verify2FA(code: accountService.tfaCode)

            switch result {
            case .success(_):
                accountService.tfaCode = ""
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
