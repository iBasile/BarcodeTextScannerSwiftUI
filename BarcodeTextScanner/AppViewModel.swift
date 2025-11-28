//
//  AppViewModel.swift
//  BarcodeTextScanner
//
//  Created by Alfian Losari on 6/25/22.
//

import AVKit
import Foundation
import SwiftUI
import VisionKit

enum DataScannerAccessStatusType {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvailable
    case scannerAvailable
    case scannerNotAvailable
}

struct ScanHistoryEntry: Identifiable, Codable {
    let id: UUID
    let code: String
    let message: String
    let success: Bool
    let date: Date
    
    init(code: String, message: String, success: Bool) {
        self.id = UUID()
        self.code = code
        self.message = message
        self.success = success
        self.date = Date()
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    
    @Published var dataScannerAccessStatus: DataScannerAccessStatusType = .notDetermined
    @Published var recognizedItem: RecognizedItem?
    
    // Server configuration
    @AppStorage("serverIP") var serverIP: String = ""
    @AppStorage("serverPort") var serverPort: String = "3000"
    
    // Scan state
    @Published var scannedCode: String?
    @Published var articleName: String?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // History
    @Published var scanHistory: [ScanHistoryEntry] = []
    
    var headerText: String {
        if isLoading {
            return "Envoi en cours..."
        } else if let articleName = articleName {
            return "✅ \(articleName)"
        } else if let errorMessage = errorMessage {
            return errorMessage
        } else if recognizedItem == nil {
            return "Scanning barcode"
        } else {
            return "Barcode recognized"
        }
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func requestDataScannerAccessStatus() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvailable
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            
        case .restricted, .denied:
            dataScannerAccessStatus = .cameraAccessNotGranted
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            } else {
                dataScannerAccessStatus = .cameraAccessNotGranted
            }
        
        default: break
            
        }
    }
    
    func handleScannedCode(_ code: String) {
        guard !serverIP.isEmpty else {
            self.errorMessage = "⚠️ Configurez l'IP dans les réglages"
            return
        }

        self.scannedCode = code
        self.articleName = nil
        self.errorMessage = nil
        self.isLoading = true

        guard let url = URL(string: "http://\(serverIP):\(serverPort)/addProductByBarcode") else {
            self.isLoading = false
            self.errorMessage = "⚠️ Configuration serveur invalide"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: ["barcode": code]) else {
            self.isLoading = false
            self.errorMessage = "⚠️ Erreur de préparation de la requête"
            return
        }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    let msg = "Erreur réseau : \(error.localizedDescription)"
                    self.errorMessage = msg
                    self.saveHistory(code: code, message: msg, success: false)
                    return
                }
                guard let data = data else {
                    let msg = "Pas de réponse du serveur"
                    self.errorMessage = msg
                    self.saveHistory(code: code, message: msg, success: false)
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let nom = json["nom"] as? String {
                        self.articleName = nom
                        self.saveHistory(code: code, message: nom, success: true)
                    } else if let errorMsg = json["error"] as? String {
                        self.errorMessage = "Article introuvable : \(errorMsg)"
                        self.saveHistory(code: code, message: errorMsg, success: false)
                    } else {
                        self.errorMessage = "Réponse invalide"
                        self.saveHistory(code: code, message: "Réponse invalide", success: false)
                    }
                } else {
                    self.errorMessage = "Réponse invalide"
                    self.saveHistory(code: code, message: "Réponse invalide", success: false)
                }
            }
        }.resume()
    }
    
    private func saveHistory(code: String, message: String, success: Bool) {
        let entry = ScanHistoryEntry(code: code, message: message, success: success)
        scanHistory.insert(entry, at: 0)
    }
    
    
}
