import SwiftUI

struct RadonMonitorView: View {
    let onBack: () -> Void
    @State private var isScanning = false
    @State private var currentReading: Double = 0.0
    @State private var deviceStatus: DeviceStatus = .disconnected
    @State private var animationOffset: CGFloat = 0
    
    enum DeviceStatus {
        case disconnected, connecting, connected
        
        var title: String {
            switch self {
            case .disconnected: return "Device Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return .gray
            case .connecting: return .orange
            case .connected: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .disconnected: return "wifi.slash"
            case .connecting: return "wifi.circle"
            case .connected: return "wifi"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.051, green: 0.078, blue: 0.125),
                        Color(red: 0.098, green: 0.149, blue: 0.204)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Header Section
                        VStack(spacing: 20) {
                            Text("Radon Monitor")
                                .font(.custom("AeonikPro-Bold", size: 32))
                                .foregroundColor(.white)
                            
                            // Device Status
                            HStack(spacing: 12) {
                                Image(systemName: deviceStatus.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(deviceStatus.color)
                                
                                Text(deviceStatus.title)
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(deviceStatus.color)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(deviceStatus.color.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.top, 20)
                        
                        // Main Reading Display
                        VStack(spacing: 24) {
                            // Large Reading Circle
                            ZStack {
                                // Outer glow ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.3),
                                                Color(red: 0.298, green: 0.851, blue: 0.392).opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 8
                                    )
                                    .frame(width: 220, height: 220)
                                    .scaleEffect(isScanning ? 1.1 : 1.0)
                                    .opacity(isScanning ? 0.8 : 0.4)
                                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isScanning)
                                
                                // Inner circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 180, height: 180)
                                
                                // Reading content
                                VStack(spacing: 8) {
                                    Text("\(currentReading, specifier: "%.1f")")
                                        .font(.custom("AeonikPro-Bold", size: 48))
                                        .foregroundColor(.white)
                                    
                                    Text("pCi/L")
                                        .font(.custom("AeonikPro-Medium", size: 18))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Current Level")
                                        .font(.custom("AeonikPro-Regular", size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            // Safety Level Indicator
                            VStack(spacing: 12) {
                                Text(safetyMessage)
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(safetyColor)
                                    .multilineTextAlignment(.center)
                                
                                // Safety bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .fill(safetyColor)
                                            .frame(width: min(geometry.size.width * CGFloat(currentReading / 10.0), geometry.size.width), height: 8)
                                            .cornerRadius(4)
                                            .animation(.easeInOut(duration: 0.8), value: currentReading)
                                    }
                                }
                                .frame(height: 8)
                                .padding(.horizontal, 40)
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                toggleScanning()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: isScanning ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 20, weight: .bold))
                                    Text(isScanning ? "Stop Monitoring" : "Start Monitoring")
                                        .font(.custom("AeonikPro-Bold", size: 18))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isScanning ? Color.red : Color(red: 0.156, green: 0.459, blue: 0.737),
                                            isScanning ? Color.red.opacity(0.8) : Color(red: 0.098, green: 0.329, blue: 0.557)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                                .shadow(color: (isScanning ? Color.red : Color(red: 0.156, green: 0.459, blue: 0.737)).opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                simulateDeviceConnection()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bluetooth")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Connect Device")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                }
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(Color(red: 0.156, green: 0.459, blue: 0.737).opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Computed Properties
    
    private var safetyMessage: String {
        switch currentReading {
        case 0.0..<2.0:
            return "Safe Level"
        case 2.0..<4.0:
            return "Acceptable Level"
        case 4.0..<10.0:
            return "Action Recommended"
        default:
            return "High Level - Take Action"
        }
    }
    
    private var safetyColor: Color {
        switch currentReading {
        case 0.0..<2.0:
            return .green
        case 2.0..<4.0:
            return .yellow
        case 4.0..<10.0:
            return .orange
        default:
            return .red
        }
    }
    
    // MARK: - Functions
    
    private func toggleScanning() {
        isScanning.toggle()
        
        if isScanning {
            startSimulatedReading()
        } else {
            currentReading = 0.0
        }
    }
    
    private func startSimulatedReading() {
        guard isScanning else { return }
        
        // Simulate radon reading changes
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if !isScanning {
                timer.invalidate()
                return
            }
            
            // Generate realistic radon readings (0.0 - 8.0 pCi/L range)
            currentReading = Double.random(in: 0.5...6.5)
        }
    }
    
    private func simulateDeviceConnection() {
        deviceStatus = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            deviceStatus = .connected
        }
    }
}

#Preview {
    RadonMonitorView(onBack: {})
} 