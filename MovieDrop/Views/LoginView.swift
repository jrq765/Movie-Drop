import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21))
                    
                    Text("MovieDrop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Discover. Share. Watch.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        authService.login(email: email, password: password)
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(authService.isLoading ? "Signing In..." : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.97, green: 0.33, blue: 0.21))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 30)
                
                // Register Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    
                    Button("Sign Up") {
                        showingRegister = true
                    }
                    .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21))
                }
                
                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
