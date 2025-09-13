import SwiftUI

struct IntroView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.97, green: 0.33, blue: 0.21), // MovieDrop orange
                    Color(red: 0.9, green: 0.2, blue: 0.1)     // Darker orange
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo/Icon
                VStack(spacing: 20) {
                    // App Icon placeholder - you can replace this with your actual logo
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "film.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21))
                    }
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // App Name
                    Text("MovieDrop")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: isAnimating)
                    
                    // Tagline
                    Text("Discover. Share. Watch.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(1.0), value: isAnimating)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Loading...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0).delay(1.5), value: isAnimating)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            
            // Show intro for 3 seconds then transition to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showMainApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
    }
}

#Preview {
    IntroView()
}
