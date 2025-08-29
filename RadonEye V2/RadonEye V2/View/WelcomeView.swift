import SwiftUI

struct WelcomeView: View {
    let onNewApp: () -> Void
    let onOriginalApp: () -> Void
    
    @State private var animateArrow = false
    @State private var animateFeatures = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.97, green: 0.98, blue: 0.97),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Text("RadonEye")
                                .font(.system(size: 36, weight: .light, design: .default))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                            
                            Text("Professional Radon Monitoring")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.4))
                            
                            HStack(spacing: 8) {
                                Text("Powered by")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                
                                Image("lol")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 20)
                            }
                        }
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 60)
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : -20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateFeatures)
                    
                    Spacer()
                    
                    // Key Features - Horizontal Layout
                    HStack(spacing: 40) {
                        FeatureColumn(
                            icon: "wave.3.right",
                            title: "Real-Time",
                            subtitle: "Instant"
                        )
                        
                        FeatureColumn(
                            icon: "chart.xyaxis.line",
                            title: "Analytics",
                            subtitle: "Track trends"
                        )
                        
                        FeatureColumn(
                            icon: "shield.checkered",
                            title: "Protection",
                            subtitle: "Stay safe"
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Action Button (single button, centered)
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onNewApp()
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .offset(x: animateArrow ? 3 : 0)
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true),
                                    value: animateArrow
                                )
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.3, green: 0.5, blue: 0.3))
                        )
                    }
                    .opacity(animateFeatures ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateFeatures)
                    .padding(.horizontal, 40)
                    

                }
            }
        }
        .onAppear {
            animateFeatures = true
            animateArrow = true
        }
    }
}

// MARK: - Floating Particle
struct FloatingParticle: View {
    let delay: Double
    let geometry: GeometryProxy
    
    @State private var animate = false
    @State private var opacity = 0.0
    
    var body: some View {
        Circle()
            .fill(Color(red: 0.3, green: 0.5, blue: 0.3).opacity(0.1))
            .frame(width: 4, height: 4)
            .offset(
                x: animate ? geometry.size.width * 0.8 : geometry.size.width * 0.2,
                y: animate ? geometry.size.height * 0.2 : geometry.size.height * 0.8
            )
            .opacity(opacity)
            .animation(
                Animation.easeInOut(duration: 6.0 + delay)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: animate
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    animate = true
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Feature Column
struct FeatureColumn: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Base circle (static)
                Circle()
                    .fill(Color(red: 0.3, green: 0.5, blue: 0.3).opacity(0.1))
                    .frame(width: 44, height: 44)
                
                // Static ring
                Circle()
                    .stroke(Color(red: 0.3, green: 0.5, blue: 0.3).opacity(0.2), lineWidth: 1)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.3))
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.2))
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            }
        }
    }
}

#Preview {
    WelcomeView(
        onNewApp: {},
        onOriginalApp: {}
    )
}