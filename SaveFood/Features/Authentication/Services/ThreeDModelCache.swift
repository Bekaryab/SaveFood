import Foundation
import RealityKit
import simd
@MainActor
final class ThreeDModelCache {
    static let shared = ThreeDModelCache()
    struct NormalizedEntry {
        let template: Entity
        let extents: SIMD3<Float>
    }
    private var rawCache: [String: Entity] = [:]
    private var normalizedCache: [String: NormalizedEntry] = [:]
    private var isPreloadingAuth = false
    private var isPreloadingCart = false
    static let authCarouselSpecs: [(name: String, targetSize: Float)] = [
        ("Small_Store", 0.74),
        ("Red_Glossy_Percent_Icon_3D_-_Claymorphism_Style", 0.68),
        ("Map_Pointer_3D_Icon", 0.70)
    ]
    private init() {}
    func warmUpCartImmediately() async {
        guard !isPreloadingCart else { return }
        isPreloadingCart = true
        _ = await loadNormalizedModel(named: ["Metal_Shopping_Cart"], targetSize: 0.92)
    }
    func loadRawModel(named names: [String]) async -> Entity? {
        for name in names {
            if let cached = rawCache[name] {
                return cached.clone(recursive: true)
            }
        }
        for name in names {
            if let loaded = await fetchFromBundle(named: name) {
                rawCache[name] = loaded
                return loaded.clone(recursive: true)
            }
        }
        return nil
    }
    func loadNormalizedModel(named names: [String], targetSize: Float) async -> NormalizedEntry? {
        let cacheKey = "\(names.first ?? "")_\(targetSize)"
        if let cached = normalizedCache[cacheKey] {
            return NormalizedEntry(
                template: cached.template.clone(recursive: true),
                extents: cached.extents
            )
        }
        guard let raw = await loadRawModel(named: names) else { return nil }
        let normalized = Self.normalize(raw, targetSize: targetSize)
        normalizedCache[cacheKey] = normalized
        return NormalizedEntry(
            template: normalized.template.clone(recursive: true),
            extents: normalized.extents
        )
    }
    func preloadAuthCarouselModels() async {
        guard !isPreloadingAuth else { return }
        isPreloadingAuth = true
        for spec in Self.authCarouselSpecs {
            _ = await loadNormalizedModel(named: [spec.name], targetSize: spec.targetSize)
        }
    }
    func getInstantNormalizedModel(named name: String, targetSize: Float) -> NormalizedEntry? {
        let cacheKey = "\(name)_\(targetSize)"
        guard let cached = normalizedCache[cacheKey] else { return nil }
        return NormalizedEntry(
            template: cached.template.clone(recursive: true),
            extents: cached.extents
        )
    }
    private func fetchFromBundle(named name: String) async -> Entity? {
        if let entity = try? await Entity(named: name, in: .main) {
            return entity
        }
        let subdirectories = ["RegisterResources", "3DModels 2", "Resources/RegisterResources", "Resources/3DModels 2"]
        for dir in subdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: dir),
               let entity = try? await Entity(contentsOf: url) {
                return entity
            }
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "usdz"),
           let entity = try? await Entity(contentsOf: url) {
            return entity
        }
        return nil
    }
    static func normalize(_ model: Entity, targetSize: Float) -> NormalizedEntry {
        let outerContainer = Entity()
        let innerPivot = Entity()
        let clonedModel = model.clone(recursive: true)
        innerPivot.addChild(clonedModel)
        outerContainer.addChild(innerPivot)
        let bounds = innerPivot.visualBounds(relativeTo: innerPivot)
        let extents = bounds.extents
        let maxDimension = max(extents.x, max(extents.y, extents.z))
        guard maxDimension > 0.0001 else {
            return NormalizedEntry(
                template: outerContainer,
                extents: SIMD3<Float>(repeating: targetSize)
            )
        }
        let scaleFactor = targetSize / maxDimension
        innerPivot.scale = SIMD3<Float>(repeating: scaleFactor)
        innerPivot.position = -bounds.center * scaleFactor
        return NormalizedEntry(
            template: outerContainer,
            extents: extents * scaleFactor
        )
    }
}
