import SwiftUI

struct HomeView: View {
    let onBack: () -> Void
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showDeviceList = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeContentView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)
                
                // Devices Tab
                DevicesContentView(showDeviceList: $showDeviceList)
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "sensor.tag.radiowaves.forward.fill" : "sensor.tag.radiowaves.forward")
                        Text("Devices")
                    }
                    .tag(1)
                
                // Data Tab
                DataContentView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                        Text("Data")
                    }
                    .tag(2)
            }
            .accentColor(Color(red: 0.156, green: 0.459, blue: 0.737))
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
                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Home Content View
struct HomeContentView: View {
    var body: some View {
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
            
            ScrollView {
                VStack(spacing: 30) {
                    // About Us Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About Us")
                            .font(.custom("AeonikPro-Bold", size: 28))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("WHO ARE WE")
                                .font(.custom("AeonikPro-Bold", size: 18))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text("Ecosense is an innovator in the radon monitoring industry providing people peace of mind through its intelligent and highly accurate radon detectors for homes, educational campuses, assisted living centers, community centers and commercial buildings. The company's smart real-time radon monitors integrate a patented high accuracy ion chamber detection technology together with state-of-art analysis and processing software capable of delivering the first accurate radon result in minutes not days.\n\nEcosense is based in the heart of Silicon Valley, California.")
                                .font(.custom("AeonikPro-Regular", size: 16))
                                .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                .lineSpacing(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ecosense, Inc. (USA)")
                                .font(.custom("AeonikPro-Bold", size: 18))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            Text("Customer support:")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        }
                        
                        // Buttons Section
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                if let url = URL(string: "https://ecosense.io") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("https://ecosense.io")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button(action: {
                                showEmailAlert(email: "support@ecosense.io")
                            }) {
                                Text("support@ecosense.io")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button(action: {
                                showEmailAlert(email: "marketing@ecosense.io")
                            }) {
                                Text("Referral program:")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Social Media Section
                        HStack(spacing: 20) {
                            Button(action: {
                                if let url = URL(string: "https://www.facebook.com/ecosense.io/") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image("facebook")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    Text("Facebook")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                }
                            }
                            
                            Button(action: {
                                if let url = URL(string: "https://youtu.be/jzhCfKRLVNI") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image("youtube")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    Text("YouTube")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                }
                            }
                        }
                        
                        // Footer Links
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button(action: {
                                    if let url = URL(string: "https://ecosense.io/policies/privacy-policy") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Privacy policy")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        .underline()
                                }
                                
                                Text(" and ")
                                    .font(.custom("AeonikPro-Regular", size: 16))
                                    .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                
                                Button(action: {
                                    if let url = URL(string: "https://ecosense.io/policies/terms-of-service") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("terms of use")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        .underline()
                                }
                            }
                            
                            Text("© \(Calendar.current.component(.year, from: Date())) Ecosense, Inc. All rights reserved")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    // Get Help Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Get Help")
                            .font(.custom("AeonikPro-Bold", size: 28))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        // Quick Guide and FAQ
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                if let url = URL(string: "https://link.ecosense.io/rd200-guide") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("• RadonEye Quick Guide")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .underline()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button(action: {
                                if let url = URL(string: "https://ecosense.io/pages/rd200-faq-en") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("• Frequently Asked Questions")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .underline()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("• Website: ")
                                    .font(.custom("AeonikPro-Regular", size: 15))
                                    .foregroundColor(.black)
                                
                                Button(action: {
                                    if let url = URL(string: "https://ecosense.io") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("ecosense.io")
                                        .font(.custom("AeonikPro-Medium", size: 15))
                                        .foregroundColor(Color(red: 0.21, green: 0.49, blue: 0.75))
                                        .underline()
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("• Email: ")
                                    .font(.custom("AeonikPro-Regular", size: 15))
                                    .foregroundColor(.black)
                                
                                Button(action: {
                                    showEmailAlert(email: "support@ecosense.io")
                                }) {
                                    Text("support@ecosense.io")
                                        .font(.custom("AeonikPro-Medium", size: 15))
                                        .foregroundColor(Color(red: 0.21, green: 0.49, blue: 0.75))
                                        .underline()
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // International Support Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("• ")
                                    .font(.custom("AeonikPro-Regular", size: 16))
                                    .foregroundColor(.black)
                                
                                Text("For Customers Outside the U.S. and Canada")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            }
                            
                            Text("• Europe")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("For support, contact your local distributor, Ecosense Support at ")
                                        .font(.custom("AeonikPro-Regular", size: 14))
                                        .foregroundColor(.black)
                                    
                                    Button(action: {
                                        showEmailAlert(email: "support@ecosense.io")
                                    }) {
                                        Text("support@ecosense.io")
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(.black)
                                            .underline()
                                    }
                                }
                                
                                HStack {
                                    Text(", or RadonTec at ")
                                        .font(.custom("AeonikPro-Regular", size: 14))
                                        .foregroundColor(.black)
                                    
                                    Button(action: {
                                        showEmailAlert2(email: "support@radontec.de")
                                    }) {
                                        Text("support@radontec.de")
                                            .font(.custom("AeonikPro-Medium", size: 14))
                                            .foregroundColor(.black)
                                            .underline()
                                    }
                                    
                                    Text(".")
                                        .font(.custom("AeonikPro-Regular", size: 14))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Text("• Other Global Regions")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            
                            HStack {
                                Text("For all other international regions, reach out to your local distributor or contact Ecosense Support at ")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(.black)
                                
                                Button(action: {
                                    showEmailAlert(email: "support@ecosense.io")
                                }) {
                                    Text("support@ecosense.io")
                                        .font(.custom("AeonikPro-Medium", size: 14))
                                        .foregroundColor(.black)
                                        .underline()
                                }
                                
                                Text(".")
                                    .font(.custom("AeonikPro-Regular", size: 14))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        // Footer Section
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                if let url = URL(string: "https://ecosense.io") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("https://ecosense.io")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            HStack {
                                Button(action: {
                                    if let url = URL(string: "https://ecosense.io/policies/privacy-policy") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Privacy policy")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        .underline()
                                }
                                
                                Text(" and ")
                                    .font(.custom("AeonikPro-Regular", size: 16))
                                    .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                                
                                Button(action: {
                                    if let url = URL(string: "https://ecosense.io/policies/terms-of-service") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("terms of use")
                                        .font(.custom("AeonikPro-Medium", size: 16))
                                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        .underline()
                                }
                            }
                            
                            Text("© \(Calendar.current.component(.year, from: Date())) Ecosense, Inc. All rights reserved")
                                .font(.custom("AeonikPro-Regular", size: 14))
                                .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    // Feature Cards
                    VStack(spacing: 20) {
                        FeatureCard(
                            icon: "sensor.tag.radiowaves.forward.fill",
                            title: "Real-time Monitoring",
                            description: "Continuous radon level detection with instant alerts",
                            color: Color(red: 0.156, green: 0.459, blue: 0.737)
                        )
                        
                        FeatureCard(
                            icon: "wifi",
                            title: "Wireless Connectivity",
                            description: "Seamless Bluetooth connection to your devices",
                            color: Color.green
                        )
                        
                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Data Visualization",
                            description: "Beautiful charts and comprehensive analytics",
                            color: Color.orange
                        )
                        
                        FeatureCard(
                            icon: "shield.checkered",
                            title: "Health Protection",
                            description: "Keep your family safe with accurate measurements",
                            color: Color.red
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Quick Stats or Recent Activity Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Quick Access")
                                .font(.custom("AeonikPro-Bold", size: 20))
                                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            QuickActionCard(
                                icon: "plus.circle.fill",
                                title: "Add Device",
                                color: Color(red: 0.156, green: 0.459, blue: 0.737)
                            )
                            
                            QuickActionCard(
                                icon: "chart.bar.fill",
                                title: "View Data",
                                color: Color.green
                            )
                            
                            QuickActionCard(
                                icon: "info.circle.fill",
                                title: "Learn More",
                                color: Color.orange
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Devices Content View
struct DevicesContentView: View {
    @Binding var showDeviceList: Bool
    
    var body: some View {
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
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "sensor.tag.radiowaves.forward.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                    
                    VStack(spacing: 8) {
                        Text("Device Management")
                            .font(.custom("AeonikPro-Bold", size: 28))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        Text("Connect and monitor your RadonEye devices")
                            .font(.custom("AeonikPro-Regular", size: 16))
                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Main Action Button
                VStack(spacing: 16) {
                    Button(action: {
                        print("🟢 HomeView: Start Monitoring button pressed")
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
                    
                    Text("Tap to scan for nearby RadonEye devices")
                        .font(.custom("AeonikPro-Regular", size: 14))
                        .foregroundColor(Color(red: 0.576, green: 0.576, blue: 0.576))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Data Content View
struct DataContentView: View {
    var body: some View {
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
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                    
                    VStack(spacing: 8) {
                        Text("Data & Analytics")
                            .font(.custom("AeonikPro-Bold", size: 28))
                            .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                        
                        Text("View your measurement history and trends")
                            .font(.custom("AeonikPro-Regular", size: 16))
                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Data Overview Cards
                VStack(spacing: 16) {
                    DataOverviewCard(
                        title: "Recent Measurements",
                        value: "No Data",
                        unit: "",
                        icon: "clock.fill",
                        color: Color.blue
                    )
                    
                    DataOverviewCard(
                        title: "Average Level",
                        value: "No Data",
                        unit: "",
                        icon: "chart.bar.fill",
                        color: Color.green
                    )
                    
                    DataOverviewCard(
                        title: "Peak Reading",
                        value: "No Data",
                        unit: "",
                        icon: "arrow.up.circle.fill",
                        color: Color.red
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Info text
                VStack(spacing: 8) {
                    Text("Connect to a device to view data")
                        .font(.custom("AeonikPro-Medium", size: 16))
                        .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                    
                    Text("Your measurement history and analytics will appear here")
                        .font(.custom("AeonikPro-Regular", size: 14))
                        .foregroundColor(Color(red: 0.576, green: 0.576, blue: 0.576))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

// MARK: - Feature Card
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

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
                         Text(title)
                .font(.custom("AeonikPro-Medium", size: 14))
                .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Data Overview Card
struct DataOverviewCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AeonikPro-Medium", size: 14))
                    .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.custom("AeonikPro-Bold", size: 20))
                        .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.custom("AeonikPro-Bold", size: 24))
                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.173))
                    .padding(.top, 20)
                
                Text("Settings functionality will be implemented here")
                    .font(.custom("AeonikPro-Regular", size: 16))
                    .foregroundColor(Color(red: 0.376, green: 0.376, blue: 0.376))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { 
                    dismiss() 
                }
                .font(.custom("AeonikPro-Medium", size: 16))
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
        }
    }
} 

// MARK: - Helper Functions
private func showEmailAlert(email: String) {
    let alert = UIAlertController(
        title: "Support",
        message: "Please email us at \(email)",
        preferredStyle: .alert
    )
    
    let sendAction = UIAlertAction(title: "Send", style: .default) { _ in
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    let closeAction = UIAlertAction(title: "Close", style: .default)
    
    alert.addAction(closeAction)
    alert.addAction(sendAction)
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.rootViewController?.present(alert, animated: true)
    }
}

private func showEmailAlert2(email: String) {
    let alert = UIAlertController(
        title: "Support",
        message: "Please email us at \(email)",
        preferredStyle: .alert
    )
    
    let sendAction = UIAlertAction(title: "Send", style: .default) { _ in
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    let closeAction = UIAlertAction(title: "Close", style: .default)
    
    alert.addAction(closeAction)
    alert.addAction(sendAction)
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.rootViewController?.present(alert, animated: true)
    }
} 