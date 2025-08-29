//
//  viewLanch.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/06.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import SwiftUI
import MessageUI
import StoreKit

class viewLanch: UIViewController {
    let tag = String("viewLanch - ")
    var savedDeviceName = String("")
    private var hasNavigatedToDeviceList = false
    
    // App Store Rating System
    private var appUsageTimer: Timer?
    private var appStartTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MyUtil.printProcess(inMsg: tag + "viewDidLoad - Starting app")

        // Apply dark mode setting on app start
        applyDarkModeOnStart()
        
        // Initialize app usage tracking for rating system
        initializeAppRatingSystem()

        // Listen for notification to return to welcome screen
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(returnToWelcomeNotification),
            name: NSNotification.Name("returnToWelcome"),
            object: nil
        )

        // Check if user has seen welcome screen before
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcomeScreen")
            
            if hasSeenWelcome {
                MyUtil.printProcess(inMsg: self.tag + "viewDidLoad - Returning user, going directly to main app")
                self.presentNewMainView()
            } else {
                MyUtil.printProcess(inMsg: self.tag + "viewDidLoad - New user, showing welcome screen")
                self.presentWelcomeScreen()
            }
        }
    }
    
    private func applyDarkModeOnStart() {
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goMonitor" {
            let nav = segue.destination as! UINavigationController
            let svc = nav.topViewController as! viewTabTop
            svc.flagScanMode = true
            svc.savedDeviceName = savedDeviceName
        }
    }
    
    // MARK: - SwiftUI Welcome Screen
    
    private func presentWelcomeScreen() {
        MyUtil.printProcess(inMsg: tag + "presentWelcomeScreen - SwiftUI only")
        
        // Create SwiftUI view directly to avoid import issues
        let welcomeView = createWelcomeView()
        let hostingController = UIHostingController(rootView: welcomeView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        // Present the SwiftUI welcome screen
        self.present(hostingController, animated: true, completion: nil)
    }
    
    private func presentDeviceList() {
        MyUtil.printProcess(inMsg: tag + "presentDeviceList - from SwiftUI button, using modern SwiftUI DeviceListView")
        
        // Use the same modern SwiftUI implementation as the new app flow
        self.presentNewMainView()
    }
    
    private func presentNewMainView() {
        MyUtil.printProcess(inMsg: tag + "presentNewMainView - Starting")
        
        let homeView = createHomeView()
        let hostingController = UIHostingController(rootView: homeView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        // Present new view directly from the current presented controller to avoid background flicker
        DispatchQueue.main.async {
            if let currentWelcomeController = self.presentedViewController {
                MyUtil.printProcess(inMsg: self.tag + "presentNewMainView - Presenting from welcome controller with slide transition")
                
                // Create custom transition for slide from right (appears as slide left)
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromRight
                transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                
                currentWelcomeController.view.window?.layer.add(transition, forKey: kCATransition)
                currentWelcomeController.present(hostingController, animated: false, completion: nil)
            } else {
                MyUtil.printProcess(inMsg: self.tag + "presentNewMainView - Presenting from self with slide transition")
                
                // Create custom transition for slide from right (appears as slide left)
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromRight
                transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                
                self.view.window?.layer.add(transition, forKey: kCATransition)
                self.present(hostingController, animated: false, completion: nil)
            }
        }
    }
    
    // BACKUP: Simple direct presentation if the above doesn't work
    private func presentNewMainViewDirect() {
        MyUtil.printProcess(inMsg: tag + "presentNewMainViewDirect - Backup method")
        
        let homeView = createHomeView()
        let hostingController = UIHostingController(rootView: homeView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        // Use same approach as main method
        DispatchQueue.main.async {
            if let currentlyPresented = self.presentedViewController {
                MyUtil.printProcess(inMsg: self.tag + "Direct method - presenting from current controller")
                currentlyPresented.present(hostingController, animated: true, completion: nil)
            } else {
                MyUtil.printProcess(inMsg: self.tag + "Direct method - presenting from self")
                self.present(hostingController, animated: true, completion: nil)
            }
        }
    }
    
    private func goBackToWelcome() {
        MyUtil.printProcess(inMsg: tag + "goBackToWelcome - from new implementation")
        
        DispatchQueue.main.async {
            MyUtil.printProcess(inMsg: self.tag + "goBackToWelcome - Dismissing to welcome screen with slide transition")
            
            // Create custom transition for slide right (back)
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            self.presentedViewController?.view.window?.layer.add(transition, forKey: kCATransition)
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    private func createWelcomeView() -> some View {
        MyUtil.printProcess(inMsg: tag + "createWelcomeView - Setting up closures")
        return WelcomeView(
            onNewApp: { [weak self] in
                MyUtil.printProcess(inMsg: self?.tag ?? "viewLanch" + "onNewApp closure called")
                // Mark that user has seen welcome screen
                UserDefaults.standard.set(true, forKey: "hasSeenWelcomeScreen")
                self?.presentNewMainView()
            },
            onOriginalApp: { [weak self] in
                MyUtil.printProcess(inMsg: self?.tag ?? "viewLanch" + "onOriginalApp closure called")
                // Mark that user has seen welcome screen
                UserDefaults.standard.set(true, forKey: "hasSeenWelcomeScreen")
                self?.presentDeviceList()
            }
        )
    }
    
    private func createHomeView() -> some View {
        MyUtil.printProcess(inMsg: tag + "createHomeView - Setting up closures")
        return InlineHomeView(onBack: { [weak self] in
            self?.goBackToWelcome()
        })
    }
    
    @objc private func returnToWelcomeNotification() {
        MyUtil.printProcess(inMsg: tag + "returnToWelcomeNotification - received, re-presenting welcome screen")
        
        // Reset the flag
        hasNavigatedToDeviceList = false
        
        // Small delay to ensure dismiss transition is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            MyUtil.printProcess(inMsg: self.tag + "returnToWelcomeNotification - presenting welcome screen")
            self.presentWelcomeScreen()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillAppear")
        super.viewWillAppear(animated)
    }
    
    // MARK: - App Store Rating System
    
    private func initializeAppRatingSystem() {
        appStartTime = Date()
        
        // Check if we should show rating prompt on app start (for weekly reminders)
        checkForWeeklyRatingReminder()
        
        // Start timer for initial 5-minute rating prompt
        appUsageTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: false) { [weak self] _ in
            self?.handleInitialRatingPrompt()
        }
        
        MyUtil.printProcess(inMsg: tag + "initializeAppRatingSystem - Rating system initialized")
    }
    
    private func handleInitialRatingPrompt() {
        let hasRated = UserDefaults.standard.bool(forKey: "hasRatedApp")
        let hasShownInitialPrompt = UserDefaults.standard.bool(forKey: "hasShownInitialRatingPrompt")
        
        // Only show initial prompt if user hasn't rated and we haven't shown initial prompt
        if !hasRated && !hasShownInitialPrompt {
            UserDefaults.standard.set(true, forKey: "hasShownInitialRatingPrompt")
            showAppStoreRating()
            MyUtil.printProcess(inMsg: tag + "handleInitialRatingPrompt - Showing initial rating prompt after 5 minutes")
        }
    }
    
    private func checkForWeeklyRatingReminder() {
        let hasRated = UserDefaults.standard.bool(forKey: "hasRatedApp")
        
        // Only check for weekly reminders if user hasn't rated
        if !hasRated {
            let lastRatingPromptDate = UserDefaults.standard.object(forKey: "lastRatingPromptDate") as? Date
            let now = Date()
            
            if let lastPromptDate = lastRatingPromptDate {
                // Check if a week has passed since last prompt
                let weekInSeconds: TimeInterval = 7 * 24 * 60 * 60
                if now.timeIntervalSince(lastPromptDate) >= weekInSeconds {
                    // Show rating prompt and update last prompt date
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.showAppStoreRating()
                        UserDefaults.standard.set(now, forKey: "lastRatingPromptDate")
                        MyUtil.printProcess(inMsg: self?.tag ?? "viewLanch" + "checkForWeeklyRatingReminder - Showing weekly rating reminder")
                    }
                }
            } else {
                // First time - set the date but don't show prompt (initial prompt will handle first time)
                UserDefaults.standard.set(now, forKey: "lastRatingPromptDate")
            }
        }
    }
    
    private func showAppStoreRating() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
                
                // Mark that user has been prompted (iOS will handle if they actually rated)
                // We assume if they've been prompted multiple times, they've likely rated
                let promptCount = UserDefaults.standard.integer(forKey: "ratingPromptCount")
                UserDefaults.standard.set(promptCount + 1, forKey: "ratingPromptCount")
                
                // After 3 prompts, assume user has either rated or doesn't want to rate
                if promptCount >= 2 { // This will be the 3rd prompt
                    UserDefaults.standard.set(true, forKey: "hasRatedApp")
                    MyUtil.printProcess(inMsg: self.tag + "showAppStoreRating - User has been prompted 3 times, stopping future prompts")
                }
                
                MyUtil.printProcess(inMsg: self.tag + "showAppStoreRating - Requested App Store review")
            }
        }
    }
    
    // Public method to mark user as having rated (can be called from settings or other places)
    func markUserAsRated() {
        UserDefaults.standard.set(true, forKey: "hasRatedApp")
        appUsageTimer?.invalidate()
        MyUtil.printProcess(inMsg: tag + "markUserAsRated - User marked as having rated the app")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        appUsageTimer?.invalidate()
    }


    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        super.viewWillDisappear(animated)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        MyUtil.printProcess(inMsg: tag + "didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Inline HomeView
struct InlineHomeView: View {
    let onBack: () -> Void
    @State private var selectedTab = 0
    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background based on dark mode
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ] : [
                        Color(red: 0.894, green: 0.929, blue: 0.957),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                TabView(selection: $selectedTab) {
                    // Devices Tab
                    InlineDevicesContentView(showSettings: $showSettings)
                        .tabItem {
                            Image(systemName: selectedTab == 0 ? "sensor.tag.radiowaves.forward.fill" : "sensor.tag.radiowaves.forward")
                            Text("Devices")
                        }
                        .tag(0)
                    
                    // Data Tab
                    InlineDataContentView()
                        .tabItem {
                            Image(systemName: selectedTab == 1 ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                            Text("Data")
                        }
                        .tag(1)
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
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            InlineSettingsView()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Inline Devices Content View
struct InlineDevicesContentView: View {
    @Binding var showSettings: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Embed the actual DeviceListView content without navigation chrome
            DeviceListView(
                onBack: {
                    // This won't be used since we're embedding it
                },
                onDeviceSelected: { peripheral, bleController in
                    MyUtil.printProcess(inMsg: "InlineDevicesContentView - Device selected: \(peripheral.realName)")
                    // TODO: Implement navigation to monitoring view in future update
                    // For now, this provides the infrastructure for device selection
                },
                showInlineHeader: true,
                onSettingsPressed: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showSettings = true
                }
            )
            .navigationBarHidden(true) // Hide the DeviceListView's own navigation
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Inline Data Content View
struct InlineDataContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var savedDataManager = SavedDataManager.shared
    @State private var showingDeleteAlert = false
    @State private var dataToDelete: SavedLogData?
    @State private var showingExportAlert = false
    @State private var showingExportSuccess = false
    @State private var selectedExportData: SavedLogData?
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: isDarkMode ? [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ] : [
                    Color(red: 0.894, green: 0.929, blue: 0.957),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if savedDataManager.savedData.isEmpty {
                // Empty state
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        
                        VStack(spacing: 8) {
                            Text("Data & Analytics")
                                .font(.custom("AeonikPro-Bold", size: 28))
                                .foregroundColor(.primary)
                            
                            Text("View your saved measurement data")
                                .font(.custom("AeonikPro-Regular", size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("No saved data yet")
                            .font(.custom("AeonikPro-Medium", size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("Connect to a device and save measurement data to view it here")
                            .font(.custom("AeonikPro-Regular", size: 14))
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            } else {
                // Data list
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Text("Saved Data")
                                .font(.custom("AeonikPro-Bold", size: 24))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("\(savedDataManager.savedData.count) saved measurement\(savedDataManager.savedData.count == 1 ? "" : "s")")
                                .font(.custom("AeonikPro-Regular", size: 16))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // List of saved data
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(savedDataManager.savedData.reversed()) { logData in
                                SavedDataCard(
                                    logData: logData,
                                    onExport: { data in
                                        selectedExportData = data
                                        showingExportAlert = true
                                    },
                                    onDelete: { data in
                                        dataToDelete = data
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .alert("Delete Data", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let data = dataToDelete {
                    savedDataManager.deleteLogData(data)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let data = dataToDelete {
                Text("Are you sure you want to delete '\(data.name)'?")
            }
        }
        .alert("Export Data", isPresented: $showingExportAlert) {
            Button("Export CSV") {
                if let data = selectedExportData {
                    exportSavedData(data)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let data = selectedExportData {
                Text("Export '\(data.name)' to CSV file")
            }
        }
        .alert("Export Complete", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            Text("Data has been exported successfully")
        }
    }
    
    private func exportSavedData(_ logData: SavedLogData) {
        let csvData = savedDataManager.exportLogData(logData)
        
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = "\(logData.name)_\(DateFormatter.dateFormatted(logData.savedDate)).csv"
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            do {
                try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
                showingExportSuccess = true
                MyUtil.printProcess(inMsg: "InlineDataContentView - Exported saved data to: \(fileURL.path)")
            } catch {
                MyUtil.printProcess(inMsg: "InlineDataContentView - Export error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Saved Data Card
struct SavedDataCard: View {
    let logData: SavedLogData
    let onExport: (SavedLogData) -> Void
    let onDelete: (SavedLogData) -> Void
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingChartView = false
    
    var body: some View {
        Button(action: {
            showingChartView = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and actions
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(logData.name)
                            .font(.custom("AeonikPro-Bold", size: 18))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(logData.deviceName)
                            .font(.custom("AeonikPro-Medium", size: 14))
                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            onExport(logData)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                        }
                        .onTapGesture {
                            // Prevent card tap when export is pressed
                        }
                        
                        Button(action: {
                            onDelete(logData)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .onTapGesture {
                            // Prevent card tap when delete is pressed
                        }
                    }
                }
                
                // Essential information only
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Saved \(logData.formattedSavedDate)")
                            .font(.custom("AeonikPro-Regular", size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(logData.formattedMeasurementPeriod)
                            .font(.custom("AeonikPro-Regular", size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .fullScreenCover(isPresented: $showingChartView) {
            SavedDataChartView(logData: logData)
        }
    }
}

// MARK: - Inline Settings View
struct InlineSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAboutUs = false
    @State private var showGetHelp = false
    @State private var showFeatureRequest = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings List
                List {
                    Section {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showAboutUs = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(width: 24, height: 24)
                                
                                Text("About Us")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showGetHelp = true
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(width: 24, height: 24)
                                
                                Text("Get Help")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showFeatureRequest = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                    .frame(width: 24, height: 24)
                                
                                Text("Request a Feature")
                                    .font(.custom("AeonikPro-Medium", size: 16))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "moon")
                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                .frame(width: 24, height: 24)
                            
                            Text("Dark Mode")
                                .font(.custom("AeonikPro-Medium", size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $isDarkMode)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.156, green: 0.459, blue: 0.737)))
                                .onChange(of: isDarkMode) { newValue in
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    
                                    // Apply dark mode to the entire app
                                    applyDarkModeToApp(isDark: newValue)
                                }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Appearance")
                            .font(.custom("AeonikPro-Regular", size: 14))
                    }
                    
                                Section {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    requestAppStoreRating()
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                            .frame(width: 24, height: 24)
                        
                        Text("Rate RadonEye")
                            .font(.custom("AeonikPro-Medium", size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("App & Device")
                    .font(.custom("AeonikPro-Regular", size: 14))
            }
                }
                .listStyle(InsetGroupedListStyle())
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
            .onAppear {
                // Apply the saved dark mode setting when the view appears
                applyDarkModeToApp(isDark: isDarkMode)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .fullScreenCover(isPresented: $showAboutUs) {
            InlineAboutUsView()
        }
        .fullScreenCover(isPresented: $showGetHelp) {
            InlineGetHelpView()
        }
        .fullScreenCover(isPresented: $showFeatureRequest) {
            InlineFeatureRequestView()
        }
    }
    
    private func applyDarkModeToApp(isDark: Bool) {
        // Apply dark mode to all windows in the app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
        }
        
        // Force refresh of all views by posting a notification
        NotificationCenter.default.post(name: NSNotification.Name("DarkModeChanged"), object: isDark)
    }
    
    private func requestAppStoreRating() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            
            // Mark user as having been prompted to rate
            UserDefaults.standard.set(true, forKey: "hasRatedApp")
            
            MyUtil.printProcess(inMsg: "InlineSettingsView - Manual App Store rating requested")
        }
    }
}

// MARK: - About Us View
struct InlineAboutUsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ] : [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // About Us Card with improved styling
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with improved typography
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About Us")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Empowering safer homes through intelligent radon detection")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                            
                            // Ecosense Logo with improved presentation
                            HStack {
                                Spacer()
                                Image("Ecosense_Logo 1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 50)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                Spacer()
                            }
                            
                            // Content sections with improved spacing and typography
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Our Mission")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("To deliver a family of the world's best radon detectors by leveraging ion chamber technology and user friendly data communications to become a part of your safer and smarter home. We are committed to reducing the alarming toll of radon-caused lung cancer deaths, which currently stands at 24,000 per year across North America.\n\n**About Ecosense**\n\nEcosense delivers peace of mind through intelligent, highly accurate radon detection technology for homes, schools, assisted living facilities, and commercial buildings. Our patented ion chamber sensors combined with advanced processing software provide the industry's first accurate radon readings in minutes—not days.\n\nWe're driven to safeguard indoor air quality and counter the threat of deadly radon gas, the leading cause of lung cancer among non-smokers. Based in Silicon Valley, Ecosense is transforming radon monitoring with real-time intelligence that protects the spaces where people live, learn, and work.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            
                            // Contact section with improved styling
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Get in Touch")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "globe")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .frame(width: 16, height: 16)
                                            Text("ecosense.io")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color(red: 0.95, green: 0.97, blue: 1.0))
                                        )
                                    }
                                    
                                    Button(action: {
                                        showEmailAlert(email: "support@ecosense.io")
                                    }) {
                                        HStack {
                                            Image(systemName: "envelope")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .frame(width: 16, height: 16)
                                            Text("support@ecosense.io")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color(red: 0.95, green: 0.97, blue: 1.0))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                        
                        // Social and legal section with improved styling
                        VStack(alignment: .leading, spacing: 20) {
                            // Social Media Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Connect With Us")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 16) {
                                    Button(action: {
                                        if let url = URL(string: "https://www.facebook.com/ecosense.io/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image("facebook")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .colorInvert()
                                            Text("Facebook")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                    }
                                    
                                    Button(action: {
                                        if let url = URL(string: "https://youtu.be/jzhCfKRLVNI") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image("youtube")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .colorInvert()
                                            Text("YouTube")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                    }
                                }
                            }
                            
                            // Footer Links with improved styling
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io/policies/privacy-policy") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Privacy Policy")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            .underline()
                                    }
                                    
                                    Text(" • ")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io/policies/terms-of-service") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Terms of Service")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            .underline()
                                    }
                                }
                                
                                Text("© 2025 Ecosense, Inc. All rights reserved")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(24)
                        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color(red: 0.97, green: 0.97, blue: 0.97))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { 
                    dismiss() 
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Get Help View
struct InlineGetHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ] : [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Get Help Card with improved styling
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with improved typography
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Get Help")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Find answers and support when you need it most")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                            
                            // Quick Guide and FAQ Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Resources")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Button(action: {
                                        if let url = URL(string: "https://link.ecosense.io/rd200-guide") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "book.fill")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .frame(width: 20, height: 20)
                                            Text("RadonEye Quick Guide")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color(red: 0.95, green: 0.97, blue: 1.0))
                                        )
                                    }
                                    
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io/pages/rd200-faq-en") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "questionmark.circle.fill")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .frame(width: 20, height: 20)
                                            Text("Frequently Asked Questions")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color(red: 0.95, green: 0.97, blue: 1.0))
                                        )
                                    }
                                }
                            }
                            
                            // Contact Information Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Contact Us")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "globe")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .frame(width: 18, height: 18)
                                            Text("ecosense.io")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            Spacer()
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color(red: 0.95, green: 0.97, blue: 1.0))
                                        )
                                    }
                                    
                                    Button(action: {
                                        showEmailAlert(email: "support@ecosense.io")
                                    }) {
                                        HStack {
                                            Image(systemName: "envelope")
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                                .frame(width: 18, height: 18)
                                            Text("support@ecosense.io")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            Spacer()
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color(red: 0.95, green: 0.97, blue: 1.0))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                        
                        // International Support Section
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("International Support")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    // Europe Section
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Europe")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Text("For support, contact your local distributor, Ecosense Support at support@ecosense.io, or RadonTec at support@radontec.de.")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .lineSpacing(2)
                                    }
                                    
                                    // Other Regions Section
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Other Global Regions")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Text("For all other international regions, reach out to your local distributor or contact Ecosense Support at support@ecosense.io.")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .lineSpacing(2)
                                    }
                                }
                            }
                            
                            // Footer Links
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io/policies/privacy-policy") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Privacy Policy")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            .underline()
                                    }
                                    
                                    Text(" • ")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        if let url = URL(string: "https://ecosense.io/policies/terms-of-service") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Terms of Service")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
                                            .underline()
                                    }
                                }
                                
                                Text("© 2025 Ecosense, Inc. All rights reserved")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(24)
                        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color(red: 0.97, green: 0.97, blue: 0.97))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { 
                    dismiss() 
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Feature Request View
struct InlineFeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = "Feature Request"
    @State private var requestTitle = ""
    @State private var requestDescription = ""
    @State private var userEmail = ""
    @State private var showingEmailAlert = false
    @State private var emailError = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private let categories = [
        "Feature Request",
        "Bug Report", 
        "UI/UX Improvement",
        "Performance Enhancement",
        "General Feedback"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: isDarkMode ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ] : [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Feature Request Card
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Request a Feature")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Help us improve RadonEye by sharing your ideas")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                            
                            // Category Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Menu {
                                    ForEach(categories, id: \.self) { category in
                                        Button(category) {
                                            selectedCategory = category
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                                }
                            }
                            
                            // Title Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                TextField("Brief description of your request", text: $requestTitle)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            // Description Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                TextEditor(text: $requestDescription)
                                    .frame(minHeight: 120)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            // Email Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Email (Optional)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                TextField("email@example.com", text: $userEmail)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            // Submit Button
                            Button(action: {
                                submitFeatureRequest()
                            }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.white)
                                        .frame(width: 18, height: 18)
                                    Text("Submit Request")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.156, green: 0.459, blue: 0.737))
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .disabled(requestTitle.isEmpty || requestDescription.isEmpty)
                            .opacity(requestTitle.isEmpty || requestDescription.isEmpty ? 0.6 : 1.0)
                        }
                        .padding(24)
                        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.17) : Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") { 
                    dismiss() 
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.156, green: 0.459, blue: 0.737))
            )
            .alert("Email Error", isPresented: $showingEmailAlert) {
                Button("OK") { }
            } message: {
                Text(emailError)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func submitFeatureRequest() {
        let subject = "[RadonEye App] \(selectedCategory): \(requestTitle)"
        
        var body = """
        Category: \(selectedCategory)
        Title: \(requestTitle)
        
        Description:
        \(requestDescription)
        
        """
        
        if !userEmail.isEmpty {
            body += "\nUser Email: \(userEmail)"
        }
        
        body += "\n\n---\nSent from RadonEye iOS App"
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.setToRecipients(["support@ecosense.io"])
            mailComposer.setSubject(subject)
            mailComposer.setMessageBody(body, isHTML: false)
            
            // Present the mail composer
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(mailComposer, animated: true)
            }
        } else {
            emailError = "Email is not available on this device. Please send your request to support@ecosense.io"
            showingEmailAlert = true
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



