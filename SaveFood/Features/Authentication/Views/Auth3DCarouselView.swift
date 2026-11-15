import SwiftUI
import RealityKit
import UIKit
import simd
@MainActor
private final class CarouselAnimationState {
    var subscription: EventSubscription?
    var slides: [Entity] = []
}
@available(iOS 18.0, *)
struct Auth3DCarouselView: View {
    @State private var carouselState = CarouselAnimationState()
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 35
            camera.look(
                at: SIMD3<Float>(0, -0.02, 0),
                from: SIMD3<Float>(0, 0.12, 1.85),
                relativeTo: nil
            )
            content.add(camera)
            let keyLight = DirectionalLight()
            keyLight.light = DirectionalLightComponent(color: .white, intensity: 2400)
            keyLight.look(at: .zero, from: SIMD3<Float>(-1.4, 2.2, 2.4), relativeTo: nil)
            content.add(keyLight)
            let warmFill = PointLight()
            warmFill.light = PointLightComponent(
                color: UIColor(red: 1.0, green: 0.97, blue: 0.90, alpha: 1.0),
                intensity: 1500,
                attenuationRadius: 6
            )
            warmFill.position = [1.4, 1.0, 2.0]
            content.add(warmFill)
            let rimLight = PointLight()
            rimLight.light = PointLightComponent(
                color: UIColor(red: 0.85, green: 1.0, blue: 0.88, alpha: 1.0),
                intensity: 1100,
                attenuationRadius: 5
            )
            rimLight.position = [0.0, 1.4, -1.5]
            content.add(rimLight)
            let shadowMesh = MeshResource.generatePlane(width: 0.76, depth: 0.46, cornerRadius: 0.23)
            var shadowMat = UnlitMaterial(color: UIColor(red: 0.12, green: 0.28, blue: 0.14, alpha: 0.14))
            shadowMat.blending = .transparent(opacity: .init(floatLiteral: 0.14))
            let shadowPlane = ModelEntity(mesh: shadowMesh, materials: [shadowMat])
            shadowPlane.position = SIMD3<Float>(0.0, -0.36, 0.0)
            content.add(shadowPlane)
            let slideContainer = Entity()
            content.add(slideContainer)
            var loadedSlides: [Entity] = []
            for (idx, spec) in ThreeDModelCache.authCarouselSpecs.enumerated() {
                if let cached = ThreeDModelCache.shared.getInstantNormalizedModel(
                    named: spec.name,
                    targetSize: spec.targetSize
                ) {
                    let model = cached.template
                    model.position = idx == 0 ? .zero : SIMD3<Float>(1.25, 0, 0)
                    model.scale = SIMD3<Float>(repeating: idx == 0 ? 1.0 : 0.0001)
                    slideContainer.addChild(model)
                    loadedSlides.append(model)
                } else if let entry = await ThreeDModelCache.shared.loadNormalizedModel(
                    named: [spec.name],
                    targetSize: spec.targetSize
                ) {
                    let model = entry.template
                    model.position = idx == 0 ? .zero : SIMD3<Float>(1.25, 0, 0)
                    model.scale = SIMD3<Float>(repeating: idx == 0 ? 1.0 : 0.0001)
                    slideContainer.addChild(model)
                    loadedSlides.append(model)
                }
            }
            carouselState.slides = loadedSlides
            var elapsed: Float = 0
            let holdDuration: Float = 2.0
            let transitionDuration: Float = 0.65
            let stepDuration = holdDuration + transitionDuration
            let enterFromRightX: Float = 1.25
            let exitToLeftX: Float = -1.25
            carouselState.subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let slides = carouselState.slides
                guard !slides.isEmpty else { return }
                let count = slides.count
                let totalCycle = Float(count) * stepDuration
                let dt = min(Float(event.deltaTime), 0.05)
                elapsed += dt
                let cycleTime = elapsed.truncatingRemainder(dividingBy: totalCycle)
                let currentIndex = Int(cycleTime / stepDuration) % count
                let nextIndex = (currentIndex + 1) % count
                let stepTime = cycleTime.truncatingRemainder(dividingBy: stepDuration)
                let gentleFloatY = sin(elapsed * 2.4) * 0.018
                let gentleRockYaw = sin(elapsed * 1.6) * 0.18

                for (index, entity) in slides.enumerated() {
                    if stepTime < holdDuration {
                        if index == currentIndex {
                            entity.position = SIMD3<Float>(0.0, gentleFloatY, 0.0)
                            entity.scale = SIMD3<Float>(repeating: 1.0)
                            entity.orientation =
                                simd_quatf(angle: 0.06, axis: SIMD3<Float>(1, 0, 0)) *
                                simd_quatf(angle: gentleRockYaw, axis: SIMD3<Float>(0, 1, 0))
                        } else {
                            entity.scale = SIMD3<Float>(repeating: 0.0001)
                        }
                    } else {
                        let rawP = (stepTime - holdDuration) / transitionDuration
                        let p = rawP * rawP * (3.0 - 2.0 * rawP)

                        if index == currentIndex {
                            let x = 0.0 + (exitToLeftX - 0.0) * p
                            let scale = max(0.0001, 1.0 - p * 0.45)
                            entity.position = SIMD3<Float>(x, gentleFloatY, -p * 0.25)
                            entity.scale = SIMD3<Float>(repeating: scale)
                            entity.orientation =
                                simd_quatf(angle: 0.06, axis: SIMD3<Float>(1, 0, 0)) *
                                simd_quatf(angle: gentleRockYaw - p * 0.5, axis: SIMD3<Float>(0, 1, 0))
                        } else if index == nextIndex {
                            let x = enterFromRightX + (0.0 - enterFromRightX) * p
                            let scale = max(0.0001, 0.55 + p * 0.45)
                            entity.position = SIMD3<Float>(x, gentleFloatY, -(1.0 - p) * 0.25)
                            entity.scale = SIMD3<Float>(repeating: scale)
                            entity.orientation =
                                simd_quatf(angle: 0.06, axis: SIMD3<Float>(1, 0, 0)) *
                                simd_quatf(angle: (1.0 - p) * 0.5 + gentleRockYaw, axis: SIMD3<Float>(0, 1, 0))
                        } else {
                            entity.scale = SIMD3<Float>(repeating: 0.0001)
                        }
                    }
                }

                let shadowPulse: Float
                if stepTime < holdDuration {
                    shadowPulse = 1.0 - gentleFloatY * 1.5
                } else {
                    let rawP = (stepTime - holdDuration) / transitionDuration
                    shadowPulse = 1.0 - sin(rawP * .pi) * 0.25
                }
                shadowPlane.scale = SIMD3<Float>(shadowPulse, 1.0, shadowPulse)
            }
        }
        .id("PersistentAuth3DCarousel")
    }
}
