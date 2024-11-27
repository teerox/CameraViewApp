import SwiftUI
import AVKit


struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var capturedVideo: URL? = nil
    @State private var switchCamera = false
    @State private var takePicture = false
    @State private var startRecording = false
    @State private var recordingStartTime: Date?      
    @State private var isPressingDown: Bool = false
    
    var body: some View {
        ZStack {
            // If an image is captured, display it
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }
            // If a video is captured, placeholder for displaying the video
            else if let capturedVideo = capturedVideo {
                // Play captured video
                // VideoPlayerView(videoURL: capturedVideo)
                VideoPlayerView(fileUrl: capturedVideo)
                    .ignoresSafeArea()
            }
            // Camera preview (live feed)
            else {
                CustomCameraRepresentable(
                    image: $capturedImage,
                    videoFile: $capturedVideo,
                    takePicture: $takePicture,
                    startRecording: $startRecording,
                    switchCamera: $switchCamera
                )
            }
            
            // Top Bar
            VStack {
                HStack {
                    Button(action: {
                        // Action to close the camera
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Action for settings/options
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Bottom Bar
                HStack {
                    // Flashlight button
                    Button(action: {
                        // Add flashlight toggle logic here
                    }) {
                        Image(systemName: "bolt")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                            .padding()
                    }
                    
                    Spacer()
                    
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .fill(startRecording ? Color.red : Color.white)
                                .frame(width: 70, height: 70)
                        }
                    }
                    .onTapGesture {
                        if !startRecording {
                            takePicture = true
                        }
                    }
                    
                    .onLongPressGesture(minimumDuration: 0.3){
                        self.isPressingDown = true
                        print("started")
                        startRecording = true
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded{ _ in
                                if self.isPressingDown{
                                    print("ended")
                                    startRecording = false
                                    self.isPressingDown = false
                                }
                            }
                    )
                    Spacer()
                    
                    // Switch camera button
                    Button(action: {
                        // Toggle between front and back cameras
                        switchCamera.toggle()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var fileUrl: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let avpController = AVPlayerViewController()
        let player = AVPlayer(url: fileUrl)
        avpController.player = player
        // Automatically play the video as soon as the player is ready
        player.play()
        return avpController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // This method is called when the SwiftUI view is updated.
        // You can update the AVPlayerViewController if needed (e.g., for changes in the file URL).
    }
}
