import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var isLogin = true
    @State private var username = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var email = ""
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]), 
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 100)
                        Image(systemName: "heart.text.square.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animate ? 1.0 : 0.8)
                    
                    Text("PetPulse")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
                .padding(.top, 40)
                
               
                VStack(spacing: 20) {
                    Text(isLogin ? "Login" : "Sign Up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 15) {
                        CustomTextField(icon: "person", placeholder: "Username", text: $username)
                        
                        if !isLogin {
                            CustomTextField(icon: "person.text.rectangle", placeholder: "Full Name", text: $fullName)
                            CustomTextField(icon: "envelope", placeholder: "Email", text: $email)
                                .keyboardType(.emailAddress)
                        }
                        
                        CustomSecureField(icon: "lock", placeholder: "Password", text: $password)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        withAnimation {
                            if isLogin {
                                viewModel.login(username: username, password: password)
                            } else {
                                viewModel.register(username: username, fullName: fullName, email: email, password: password)
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isLogin ? "Get Started" : "Create Account")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                    
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(uiColor: .systemBackground).opacity(0.9))
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal)
                
                Button(action: { 
                    withAnimation(.spring()) {
                        isLogin.toggle() 
                    }
                }) {
                    Text(isLogin ? "Don't have an account? **Register**" : "Already have an account? **Login**")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animate = true
            }
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }
}
