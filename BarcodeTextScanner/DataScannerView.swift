//
//  DataScannerView.swift
//  BarcodeTextScanner
//
//  Created by Alfian Losari on 6/25/22.
//

import Foundation
import SwiftUI
import VisionKit

struct DataScannerView: UIViewControllerRepresentable {
    
    @Binding var recognizedItem: RecognizedItem?
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItem: $recognizedItem)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        @Binding var recognizedItem: RecognizedItem?

        init(recognizedItem: Binding<RecognizedItem?>) {
            self._recognizedItem = recognizedItem
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            print("didTapOn \(item)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if let firstItem = addedItems.first {
                recognizedItem = firstItem
            }
            print("didAddItems \(addedItems)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let currentItem = recognizedItem,
               removedItems.contains(where: { $0.id == currentItem.id }) {
                recognizedItem = nil
            }
            print("didRemovedItems \(removedItems)")
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("became unavailable with error \(error.localizedDescription)")
        }
        
    }
    
}
