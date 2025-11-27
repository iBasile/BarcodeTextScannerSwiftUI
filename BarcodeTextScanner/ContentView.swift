//
//  ContentView.swift
//  BarcodeTextScanner
//
//  Created by Alfian Losari on 6/25/22.
//

import SwiftUI
import VisionKit

struct ContentView: View {
    
    @EnvironmentObject var vm: AppViewModel
    @State private var showSettings = false
    
    var body: some View {
        switch vm.dataScannerAccessStatus {
        case .scannerAvailable:
            mainView
        case .cameraNotAvailable:
            Text("Your device doesn't have a camera")
        case .scannerNotAvailable:
            Text("Your device doesn't have support for scanning barcode with this app")
        case .cameraAccessNotGranted:
            Text("Please provide access to the camera in settings")
        case .notDetermined:
            Text("Requesting camera access")
        }
    }
    
    private var mainView: some View {
        DataScannerView(recognizedItem: $vm.recognizedItem)
        .background { Color.gray.opacity(0.3) }
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            bottomContainerView
                .background(.ultraThinMaterial)
                .presentationDetents([.medium, .fraction(0.25)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let controller = windowScene.windows.first?.rootViewController?.presentedViewController else {
                        return
                    }
                    controller.view.backgroundColor = .clear
                }
        }
        .onChange(of: vm.recognizedItem) { newItem in
            if let item = newItem {
                switch item {
                case .barcode(let barcode):
                    if let code = barcode.payloadStringValue {
                        vm.handleScannedCode(code)
                    }
                @unknown default:
                    break
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(vm)
        }
    }
    
    private var headerView: some View {
        VStack {
            HStack {
                Text(vm.headerText)
                    .font(.headline)
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                }
            }
            .padding(.top)
            
            if vm.isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
        }.padding(.horizontal)
    }
    
    private var bottomContainerView: some View {
        VStack {
            headerView
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let code = vm.scannedCode {
                        HStack {
                            Text("Code: \(code)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !vm.scanHistory.isEmpty {
                        Text("Historique")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(vm.scanHistory) { entry in
                            HStack {
                                Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(entry.success ? .green : .red)
                                VStack(alignment: .leading) {
                                    Text(entry.code)
                                        .font(.caption)
                                    Text(entry.message)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration serveur")) {
                    TextField("Adresse IP", text: $vm.serverIP)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Port", text: $vm.serverPort)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
        }
    }
}
