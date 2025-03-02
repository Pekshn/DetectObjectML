//
//  ContentView.swift
//  DetectObjectML
//
//  Created by Petar  on 2.3.25..
//

import SwiftUI
import CoreML
import PhotosUI
import Vision

struct Observation {
    let label: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}

struct ContentView: View {
    
    @State private var probs: [String: Double] = [: ]
    @State private var uiImage: UIImage? = UIImage(named: "stop-sign")
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isCameraSelected: Bool = false
    @State private var detectedObjects: [Observation] = []
    
    let model = try! YOLOv3Tiny(configuration: MLModelConfiguration())
    
    private var overlayView: some View {
        GeometryReader { proxy in
            Path { path in
                for observation in detectedObjects {
                    let rect = VNImageRectForNormalizedRect(observation.boundingBox, Int(proxy.size.width), Int(proxy.size.height))
                    let cgRect = CGRect(x: rect.origin.x, y: proxy.size.height - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
                    path.addRect(cgRect)
                }
            }
            .stroke(Color.green, lineWidth: 5)
        }
    }
    
    var body: some View {
        VStack {
            Image(uiImage: uiImage!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .overlay(overlayView)
                
            HStack {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                   Text("Select a Photo")
                }
                
                Button("Camera") {
                    isCameraSelected = true
                }.buttonStyle(.bordered)
            }
            
            Button("Predict") {
                
                let mlModel = model.model
                guard let vnCoreMLModel = try? VNCoreMLModel(for: mlModel) else { return }
                let request = VNCoreMLRequest(model: vnCoreMLModel) { request, error in
                    guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                    self.detectedObjects = results.map { result in
                        guard let label = result.labels.first?.identifier else {
                            return Observation(label: "", confidence: VNConfidence.zero, boundingBox: .zero) }
                        let confidence = result.labels.first?.confidence ?? 0
                        let boundingBox = result.boundingBox
                        print("label: \(label)")
                        print("confidence: \(confidence)")
                        print("boundingBox: \(boundingBox)")
                        let observation = Observation(label: label, confidence: confidence, boundingBox: boundingBox)
                        return observation
                    }
                }
                
                guard let image = uiImage else { return }
                let resizedImage = image.resizeTo(to: CGSize(width: 416, height: 416))
                guard let pixelBuffer = resizedImage.toCVPixelBuffer() else { return }
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    print(error.localizedDescription)
                }
                
            }.buttonStyle(.borderedProminent)
            
            ObservationListView(observations: detectedObjects)
        }
        .onChange(of: selectedPhotoItem, initial: false, { oldValue, newValue in
            detectedObjects = []
            selectedPhotoItem?.loadTransferable(type: Data.self, completionHandler: { result in
                switch result {
                    case .success(let data):
                        if let data {
                            uiImage = UIImage(data: data)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            })
        })
        .fullScreenCover(isPresented: $isCameraSelected, content: {
            ImagePicker(image: $uiImage, sourceType: .camera)
        })
        .padding()
    }
}

#Preview {
    ContentView()
}
