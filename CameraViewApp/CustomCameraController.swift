//
//  CustomCameraController.swift
//  CameraViewApp
//
//  Created by Anthony Odu on 26/11/2024.
//

import Foundation
import SwiftUI
import AVFoundation


// MARK: - SwiftUI Wrapper
struct CustomCameraRepresentable: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var videoFile: URL?
    @Binding var takePicture: Bool
    @Binding var startRecording: Bool
    @Binding var switchCamera: Bool
    
    func makeUIViewController(context: Context) -> CustomCameraController {
        let controller = CustomCameraController()
        controller.cameraDelegate = context.coordinator
        controller.videoDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ cameraViewController: CustomCameraController, context: Context) {
        if takePicture {
            cameraViewController.takePicture()
        }
        
        if startRecording {
            cameraViewController.takeVideo()
        }
        
        if switchCamera {
            cameraViewController.swapCamera()
        }
        
        if !startRecording {
            cameraViewController.stopVideo()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
        let parent: CustomCameraRepresentable
        
        init(_ parent: CustomCameraRepresentable) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            parent.takePicture = false
            guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
                print("Error capturing photo: \(String(describing: error))")
                return
            }
            parent.image = image
        }
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            parent.startRecording = false
            if let error = error {
                print("Error recording video: \(error.localizedDescription)")
                return
            }
            parent.videoFile = outputFileURL
        }
    }
}

// MARK: - UIKit Camera Controller
class CustomCameraController: UIViewController {
    var captureSession = AVCaptureSession()
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var currentDevice: AVCaptureDevice?
    var videoDeviceInput: AVCaptureDeviceInput!
    let photoOutput = AVCapturePhotoOutput()
    let movieOutput = AVCaptureMovieFileOutput()
    var usingFrontCamera = false
    var cameraDelegate: AVCapturePhotoCaptureDelegate?
    var videoDelegate: AVCaptureFileOutputRecordingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAuthorization()
        setupCamera()
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let camera = self.getCurrentCamera() else {
                print("No camera available")
                return
            }
            
            do {
                self.videoDeviceInput = try AVCaptureDeviceInput(device: camera)
                self.captureSession.beginConfiguration()
                
                if self.captureSession.canAddInput(self.videoDeviceInput) {
                    self.captureSession.addInput(self.videoDeviceInput)
                }
                
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                }
                
                if self.captureSession.canAddOutput(self.movieOutput) {
                    self.captureSession.addOutput(self.movieOutput)
                }
                
                self.captureSession.commitConfiguration()
                
                // Ensure UI updates are on the main thread.
                DispatchQueue.main.async {
                    self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.cameraPreviewLayer?.videoGravity = .resizeAspectFill
                    self.cameraPreviewLayer?.frame = self.view.bounds
                    
                    if let previewLayer = self.cameraPreviewLayer {
                        self.view.layer.addSublayer(previewLayer)
                    }
                }
                
                // Start the session in the background thread
                self.captureSession.startRunning()
            } catch {
                print("Error setting up camera: \(error)")
            }
        }
    }
    
    
    private func getCurrentCamera() -> AVCaptureDevice? {
        let position: AVCaptureDevice.Position = usingFrontCamera ? .front : .back
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
    
    func swapCamera() {
        
        usingFrontCamera.toggle()
        
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }

        // Remove existing input
        if let currentInput = videoDeviceInput {
            captureSession.removeInput(currentInput)
        }

        // Switch to the correct camera
        let newPosition: AVCaptureDevice.Position = usingFrontCamera ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newDeviceInput = try? AVCaptureDeviceInput(device: newDevice) else {
            print("Error: Unable to create device input for position: \(newPosition)")
            return
        }

        // Add the new input
        if captureSession.canAddInput(newDeviceInput) {
            captureSession.addInput(newDeviceInput)
            videoDeviceInput = newDeviceInput
        } else {
            print("Error: Cannot add input to capture session")
            return
        }
        
        // Ensure the photo output is still valid
        if !captureSession.outputs.contains(photoOutput) {
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            } else {
                print("Error: Cannot add photo output to capture session")
                return
            }
        }
    }

    
    func takePicture() {
        let settings = AVCapturePhotoSettings()
       // settings.flashMode = videoDeviceInput.device.isFlashAvailable ? .auto : .off
        photoOutput.capturePhoto(with: settings, delegate: cameraDelegate!)
    }
    
    func takeVideo() {
        if !movieOutput.isRecording {
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mp4")!)
            movieOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: videoDelegate!)
        } else {
            movieOutput.stopRecording()
        }
        
       
    }
    
    func stopVideo() {
        movieOutput.stopRecording()
    }
    
    private func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("Camera access denied")
                }
            }
        default:
            print("Camera access denied")
        }
    }
}

