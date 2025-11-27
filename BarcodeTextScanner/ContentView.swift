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
    }
    
    private var headerView: some View {
        VStack {
            Text(vm.headerText).padding(.top)
        }.padding(.horizontal)
    }
    
    private var bottomContainerView: some View {
        VStack {
            headerView
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let item = vm.recognizedItem {
                        switch item {
                        case .barcode(let barcode):
                            Text(barcode.payloadStringValue ?? "Unknown barcode")
                            
                        @unknown default:
                            Text("Unknown")
                        }
                    }
                }
                .padding()
            }
        }
    }
}
