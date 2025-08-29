import SwiftUI

struct NewMainView: View {
    let onBack: () -> Void
    @State private var showDeviceList = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.894, green: 0.929, blue: 0.957),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    HStack {
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            onBack()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                            }
                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            // Header
                            VStack(spacing: 16) {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                
                                Text("RadonEye")
                                    .font(.custom("AeonikPro-Bold", size: 32))
                                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                                
                                Text("New SwiftUI Implementation")
                                    .font(.custom("AeonikPro-Regular", size: 18))
                                    .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                            }
                            .padding(.top, 40)
                            
                            // Feature cards
                            VStack(spacing: 20) {
                                FeatureCard(
                                    icon: "sensor.tag.radiowaves.forward.fill",
                                    title: "Real-time Monitoring",
                                    description: "Monitor radon levels continuously with precision sensors",
                                    color: Color(red: 0.156, green: 0.459, blue: 0.737)
                                )
                                
                                FeatureCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Data Analytics",
                                    description: "Beautiful charts and detailed analytics for your data",
                                    color: Color(red: 0.298, green: 0.851, blue: 0.392)
                                )
                                
                                FeatureCard(
                                    icon: "wifi",
                                    title: "Wireless Connection",
                                    description: "Connect seamlessly via Bluetooth Low Energy",
                                    color: Color(red: 0.737, green: 0.157, blue: 0.180)
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Navigation Button
                            VStack(spacing: 16) {
                                Button(action: {
                                    print("🟢 NewMainView: Start Monitoring button pressed")
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    showDeviceList = true
                                }) {
                                    HStack(spacing: 12) {
                                        Text("Start Monitoring")
                                            .font(.custom("AeonikPro-Bold", size: 18))
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.156, green: 0.459, blue: 0.737),
                                                Color(red: 0.098, green: 0.329, blue: 0.557)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(28)
                                    .shadow(color: Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 20)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showDeviceList) {
                DeviceListView(
                    onBack: {
                        showDeviceList = false
                    },
                    onDeviceSelected: { _, _ in
                        // Device selection is handled internally by DeviceListView
                    }
                )
            }
        }
    }
    
    struct FeatureCard: View {
        let icon: String
        let title: String
        let description: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.custom("AeonikPro-Bold", size: 18))
                        .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    Text(description)
                        .font(.custom("AeonikPro-Regular", size: 14))
                        .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
    
}
