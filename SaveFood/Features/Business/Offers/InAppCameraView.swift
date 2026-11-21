import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

final class InAppCameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {

    @Published var isAuthorized = false
    @Published var isCameraUnavailable = false
    @Published var isFlashEnabled = false
    @Published var isCapturing = false
    @Published var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.savefood.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var currentPosition: AVCaptureDevice.Position = .back
    private var isConfigured = false
    private var captureCompletion: ((UIImage) -> Void)?

    func checkPermissionsAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isAuthorized = true }
            configureAndStartSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if !granted {
                        self.errorMessage = "Разрешите доступ к камере в настройках iPhone, чтобы фотографировать товары."
                    }
                }
                if granted {
                    self.configureAndStartSession()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.errorMessage = "Доступ к камере запрещён. Включите его в Настройках или выберите фото из галереи."
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isCameraUnavailable = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let nextPosition: AVCaptureDevice.Position = (self.currentPosition == .back) ? .front : .back
            guard let nextDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: nextPosition),
                  let nextInput = try? AVCaptureDeviceInput(device: nextDevice) else {
                return
            }

            self.session.beginConfiguration()
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            if self.session.canAddInput(nextInput) {
                self.session.addInput(nextInput)
                self.currentPosition = nextPosition
            }
            self.session.commitConfiguration()
        }
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        guard !isCapturing else { return }
        DispatchQueue.main.async {
            self.isCapturing = true
        }
        captureCompletion = completion

        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            if self.photoOutput.supportedFlashModes.contains(.on) {
                settings.flashMode = self.isFlashEnabled ? .on : .off
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isCapturing = false
        }

        if let error {
            DispatchQueue.main.async {
                self.errorMessage = "Не удалось сделать снимок: \(error.localizedDescription)"
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.errorMessage = "Не удалось обработать фотографию."
            }
            return
        }

        DispatchQueue.main.async {
            let callback = self.captureCompletion
            self.captureCompletion = nil
            callback?(image)
        }
    }

    private func configureAndStartSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input),
                      self.session.canAddOutput(self.photoOutput) else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        self.isCameraUnavailable = true
                    }
                    return
                }

                self.session.addInput(input)
                self.session.addOutput(self.photoOutput)
                self.session.commitConfiguration()
                self.isConfigured = true
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
}

private struct CameraPreviewLayerView: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // Безопасное приведение, так как layerClass задан выше
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

struct InAppCameraView: View {

    var onPhotoCaptured: (UIImage) -> Void
    var onCancel: () -> Void

    @StateObject private var camera = InAppCameraController()
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let primaryGreen = Color(red: 0.08, green: 0.30, blue: 0.15)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.isAuthorized && !camera.isCameraUnavailable {
                CameraPreviewLayerView(session: camera.session)
                    .ignoresSafeArea()
            } else {
                cameraUnavailableView
            }

            VStack {
                // Верхняя панель: закрыть, вспышка, смена камеры
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.48)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Сфотографируйте товар")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.45)))

                    Spacer()

                    if camera.isAuthorized && !camera.isCameraUnavailable {
                        Button {
                            camera.isFlashEnabled.toggle()
                        } label: {
                            Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(camera.isFlashEnabled ? .yellow : .white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.48)))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                if let errorMessage = camera.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.82)))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                // Нижняя панель: Галерея | Кнопка съёмки | Поворот камеры
                HStack(spacing: 42) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Галерея")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                    }

                    Button {
                        camera.capturePhoto { image in
                            camera.stopSession()
                            onPhotoCaptured(image)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4.5)
                                .frame(width: 78, height: 78)

                            Circle()
                                .fill(camera.isCapturing ? Color.gray : Color.white)
                                .frame(width: 64, height: 64)

                            if camera.isCapturing {
                                ProgressView()
                                    .tint(primaryGreen)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!camera.isAuthorized || camera.isCameraUnavailable || camera.isCapturing)

                    Button {
                        camera.switchCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!camera.isAuthorized || camera.isCameraUnavailable)
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            camera.checkPermissionsAndStart()
        }
        .onDisappear {
            camera.stopSession()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        camera.stopSession()
                        onPhotoCaptured(image)
                    }
                }
            }
        }
    }

    private var cameraUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 46))
                .foregroundStyle(.white.opacity(0.75))

            Text("Камера недоступна")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Вы можете выбрать фотографию товара из галереи или открыть настройки доступа к камере.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Button {
                    UIApplication.shared.open(settingsURL)
                } label: {
                    Text("Открыть настройки")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 44)
                        .background(Capsule().fill(primaryGreen))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
