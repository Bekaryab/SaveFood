import SwiftUI
import RealityKit
import UIKit
import simd
@MainActor
private final class CartAnimationState {
    var subscription: EventSubscription?
    var cartEntity: Entity?
    var cartCenterY: Float = -0.05
    var foodItems: [(entity: Entity, config: CartFoodItemConfig)] = []
    var isPaused: Bool = false
}
@available(iOS 18.0, *)
struct FoodFloatingAnimationView: View {
    var isPaused: Bool = false
    @State private var animState = CartAnimationState()
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 36
            camera.look(
                at: SIMD3<Float>(0, -0.03, 0),
                from: SIMD3<Float>(0, 0.15, 1.92),
                relativeTo: nil
            )
            content.add(camera)
            // MARK: - Studio Lighting
            let keyLight = DirectionalLight()
            keyLight.light = DirectionalLightComponent(color: .white, intensity: 2400)
            keyLight.look(at: .zero, from: SIMD3<Float>(-1.4, 2.4, 2.5), relativeTo: nil)
            content.add(keyLight)
            let warmFill = PointLight()
            warmFill.light = PointLightComponent(
                color: UIColor(red: 1.0, green: 0.97, blue: 0.90, alpha: 1.0),
                intensity: 1500,
                attenuationRadius: 6
            )
            warmFill.position = [1.4, 1.0, 2.2]
            content.add(warmFill)

            let rimLight = PointLight()
            rimLight.light = PointLightComponent(
                color: UIColor(red: 0.85, green: 1.0, blue: 0.88, alpha: 1.0),
                intensity: 1100,
                attenuationRadius: 5
            )
            rimLight.position = [0.0, 1.5, -1.6]
            content.add(rimLight)
            let floorY: Float = -0.45
            let shadowMesh = MeshResource.generatePlane(width: 0.88, depth: 0.64, cornerRadius: 0.32)
            var shadowMat = UnlitMaterial(color: UIColor(red: 0.12, green: 0.28, blue: 0.14, alpha: 0.16))
            shadowMat.blending = .transparent(opacity: .init(floatLiteral: 0.16))
            let shadowPlane = ModelEntity(mesh: shadowMesh, materials: [shadowMat])
            shadowPlane.position = SIMD3<Float>(1.50, floorY + 0.005, 0.0)
            content.add(shadowPlane)
            let cartRoot = Entity()
            cartRoot.position = SIMD3<Float>(1.50, -0.05, 0.0)
            content.add(cartRoot)
            animState.cartEntity = cartRoot
            let basketContainer = Entity()
            cartRoot.addChild(basketContainer)
            Task { @MainActor in
                if let normalizedCart = await ThreeDModelCache.shared.loadNormalizedModel(
                    named: ["Metal_Shopping_Cart"],
                    targetSize: 0.92
                ) {
                    let cartModel = normalizedCart.template
                    let cartExtents = normalizedCart.extents
                    animState.cartCenterY = floorY + (cartExtents.y * 0.5)
                    cartRoot.addChild(cartModel)
                }
                for config in CartFoodItemConfig.defaultItems {
                    if let entry = await ThreeDModelCache.shared.loadNormalizedModel(
                        named: config.names,
                        targetSize: config.targetSize
                    ) {
                        let item = entry.template
                        item.scale = SIMD3<Float>(repeating: 0.0001)
                        basketContainer.addChild(item)
                        animState.foodItems.append((entity: item, config: config))
                    }
                }
                await ThreeDModelCache.shared.preloadAuthCarouselModels()
            }
            var elapsed: Float = 0
            let driveInEnd: Float = 1.15
            let turnToCameraEnd: Float = 1.65
            let fillStartTime: Float = 1.70
            let fallSingleDuration: Float = 0.62
            let turnToLeftStart: Float = 4.90
            let turnToLeftEnd: Float = 5.40
            let driveOutEnd: Float = 6.60
            let emptyWaitDuration: Float = 3.00
            let totalCycle = driveOutEnd + emptyWaitDuration
            let rightOffscreenX: Float = 1.50
            let leftOffscreenX: Float = -1.60
            let drivingLeftYaw: Float = -Float.pi / 2
            let stoppedCenterYaw: Float = -0.22
            animState.subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                guard !animState.isPaused, let cart = animState.cartEntity else { return }

                let dt = min(Float(event.deltaTime), 0.05)
                elapsed += dt

                let t = elapsed.truncatingRemainder(dividingBy: totalCycle)

                var currentCartX: Float = 0.0
                var currentCartYaw: Float = stoppedCenterYaw
                var currentCartTiltZ: Float = 0.0
                var cartBounce: Float = 0.0

                if t < driveInEnd {
                    let p = t / driveInEnd
                    let smoothP = easeOutCubic(p)
                    currentCartX = rightOffscreenX + (0.0 - rightOffscreenX) * smoothP
                    currentCartYaw = drivingLeftYaw
                    currentCartTiltZ = sin(p * .pi) * 0.025

                } else if t < turnToCameraEnd {
                    let p = (t - driveInEnd) / (turnToCameraEnd - driveInEnd)
                    let turnP = smoothstep(p)
                    currentCartX = 0.0
                    currentCartYaw = drivingLeftYaw + (stoppedCenterYaw - drivingLeftYaw) * turnP

                } else if t < turnToLeftStart {
                    currentCartX = 0.0
                    currentCartYaw = stoppedCenterYaw

                } else if t < turnToLeftEnd {
                    let p = (t - turnToLeftStart) / (turnToLeftEnd - turnToLeftStart)
                    let turnP = smoothstep(p)
                    currentCartX = 0.0
                    currentCartYaw = stoppedCenterYaw + (drivingLeftYaw - stoppedCenterYaw) * turnP

                } else if t < driveOutEnd {
                    let p = (t - turnToLeftEnd) / (driveOutEnd - turnToLeftEnd)
                    let moveP = easeInCubic(p)
                    currentCartX = 0.0 + (leftOffscreenX - 0.0) * moveP
                    currentCartYaw = drivingLeftYaw
                    currentCartTiltZ = -sin(min(1.0, p * 1.4) * .pi) * 0.03

                } else {
                    currentCartX = rightOffscreenX
                    currentCartYaw = drivingLeftYaw
                }

                for entry in animState.foodItems {
                    let item = entry.entity
                    let cfg = entry.config
                    let itemStartTime = fillStartTime + cfg.dropDelay
                    let localTime = t - itemStartTime

                    if t >= driveOutEnd || localTime <= 0 {
                        item.scale = SIMD3<Float>(repeating: 0.0001)
                    } else if localTime < fallSingleDuration {
                        let p = localTime / fallSingleDuration
                        let dropCurve = easeOutBackLanding(p)

                        let startY = cfg.localPosition.y + 1.05
                        let currentY = startY + (cfg.localPosition.y - startY) * dropCurve

                        item.position = SIMD3<Float>(
                            cfg.localPosition.x,
                            currentY,
                            cfg.localPosition.z
                        )

                        let spin = (1.0 - min(1.0, p * 1.25)) * 0.5
                        item.orientation =
                            simd_quatf(angle: cfg.rotationY + spin, axis: SIMD3<Float>(0, 1, 0)) *
                            simd_quatf(angle: cfg.tiltZ, axis: SIMD3<Float>(0, 0, 1))

                        let appearScale = min(1.0, p * 3.5)
                        item.scale = SIMD3<Float>(repeating: appearScale)

                        if p > 0.68 {
                            let hitP = (p - 0.68) / 0.32
                            cartBounce += sin(hitP * .pi) * 0.03
                        }
                    } else {
                        item.position = cfg.localPosition
                        item.orientation =
                            simd_quatf(angle: cfg.rotationY, axis: SIMD3<Float>(0, 1, 0)) *
                            simd_quatf(angle: cfg.tiltZ, axis: SIMD3<Float>(0, 0, 1))
                        item.scale = SIMD3<Float>(repeating: 1.0)
                    }
                }

                let clampedBounce = min(0.065, cartBounce)
                let scaleY = 1.0 - clampedBounce
                let scaleXZ = 1.0 + (clampedBounce * 0.45)

                cart.position = SIMD3<Float>(
                    currentCartX,
                    animState.cartCenterY - (clampedBounce * 0.028),
                    0.0
                )
                cart.scale = SIMD3<Float>(scaleXZ, scaleY, scaleXZ)
                cart.orientation =
                    simd_quatf(angle: 0.05, axis: SIMD3<Float>(1, 0, 0)) *
                    simd_quatf(angle: currentCartYaw, axis: SIMD3<Float>(0, 1, 0)) *
                    simd_quatf(angle: currentCartTiltZ, axis: SIMD3<Float>(0, 0, 1))

                shadowPlane.position = SIMD3<Float>(currentCartX, floorY + 0.005, 0.0)
                shadowPlane.scale = SIMD3<Float>(scaleXZ, 1.0, scaleXZ)
            }
        }
        .onChange(of: isPaused) { _, newValue in
            animState.isPaused = newValue
        }
    }

    private func smoothstep(_ x: Float) -> Float {
        let t = max(0.0, min(1.0, x))
        return t * t * (3.0 - 2.0 * t)
    }

    private func easeOutCubic(_ x: Float) -> Float {
        let t = max(0.0, min(1.0, x))
        let inv = 1.0 - t
        return 1.0 - (inv * inv * inv)
    }

    private func easeInCubic(_ x: Float) -> Float {
        let t = max(0.0, min(1.0, x))
        return t * t * t
    }

    private func easeOutBackLanding(_ t: Float) -> Float {
        let clamped = max(0.0, min(1.0, t))
        if clamped < 0.78 {
            let norm = clamped / 0.78
            return norm * norm * (3.0 - 2.0 * norm)
        } else {
            let bounceT = (clamped - 0.78) / 0.22
            let bounce = sin(bounceT * .pi) * 0.03
            return 1.0 - bounce
        }
    }
}
