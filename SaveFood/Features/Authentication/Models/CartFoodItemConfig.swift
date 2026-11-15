import Foundation
import simd
struct CartFoodItemConfig {
    let names: [String]
    let targetSize: Float
    let localPosition: SIMD3<Float>
    let rotationY: Float
    let tiltZ: Float
    let dropDelay: Float
    static let defaultItems: [CartFoodItemConfig] = [
        CartFoodItemConfig(
            names: ["Bread"],
            targetSize: 0.22,
            localPosition: SIMD3<Float>(-0.07, 0.02, -0.09),
            rotationY: 0.25,
            tiltZ: 0.08,
            dropDelay: 0.05
        ),
        CartFoodItemConfig(
            names: ["Roasted_Meat"],
            targetSize: 0.21,
            localPosition: SIMD3<Float>(0.06, 0.02, -0.08),
            rotationY: -0.35,
            tiltZ: -0.05,
            dropDelay: 0.22
        ),
        CartFoodItemConfig(
            names: ["Apple"],
            targetSize: 0.17,
            localPosition: SIMD3<Float>(-0.06, 0.01, 0.08),
            rotationY: 0.40,
            tiltZ: 0.06,
            dropDelay: 0.38
        ),
        CartFoodItemConfig(
            names: ["Carrot_Cake"],
            targetSize: 0.20,
            localPosition: SIMD3<Float>(0.06, 0.02, 0.09),
            rotationY: -0.30,
            tiltZ: 0.0,
            dropDelay: 0.54
        ),
        CartFoodItemConfig(
            names: ["Egg"],
            targetSize: 0.14,
            localPosition: SIMD3<Float>(0.00, 0.01, 0.00),
            rotationY: 0.15,
            tiltZ: -0.10,
            dropDelay: 0.70
        ),
        CartFoodItemConfig(
            names: ["Back_Yard_Burgers_-_Classic_Burger 2", "Back_Yard_Burgers_-_Classic_Burger"],
            targetSize: 0.22,
            localPosition: SIMD3<Float>(-0.07, 0.11, 0.04),
            rotationY: 0.20,
            tiltZ: 0.04,
            dropDelay: 0.88
        ),
        CartFoodItemConfig(
            names: ["Dairy_Milk_Cadbury_Milk_Chocolate_Bar"],
            targetSize: 0.21,
            localPosition: SIMD3<Float>(0.06, 0.12, -0.04),
            rotationY: -0.20,
            tiltZ: 0.18,
            dropDelay: 1.06
        ),
        CartFoodItemConfig(
            names: ["Apple"],
            targetSize: 0.17,
            localPosition: SIMD3<Float>(0.07, 0.11, 0.08),
            rotationY: -0.50,
            tiltZ: -0.08,
            dropDelay: 1.24
        ),
        CartFoodItemConfig(
            names: ["Roasted_Meat"],
            targetSize: 0.20,
            localPosition: SIMD3<Float>(-0.06, 0.11, -0.08),
            rotationY: 0.45,
            tiltZ: -0.06,
            dropDelay: 1.42
        ),
        CartFoodItemConfig(
            names: ["Coca_Cola_Bottle"],
            targetSize: 0.32,
            localPosition: SIMD3<Float>(-0.08, 0.24, -0.06),
            rotationY: 0.15,
            tiltZ: 0.05,
            dropDelay: 1.62
        ),
        CartFoodItemConfig(
            names: ["Pineapple"],
            targetSize: 0.30,
            localPosition: SIMD3<Float>(0.07, 0.23, -0.05),
            rotationY: -0.25,
            tiltZ: -0.06,
            dropDelay: 1.82
        ),
        CartFoodItemConfig(
            names: ["Back_Yard_Burgers_-_Classic_Burger 2", "Back_Yard_Burgers_-_Classic_Burger"],
            targetSize: 0.22,
            localPosition: SIMD3<Float>(-0.05, 0.21, 0.09),
            rotationY: 0.30,
            tiltZ: -0.04,
            dropDelay: 2.02
        ),
        CartFoodItemConfig(
            names: ["Bread"],
            targetSize: 0.21,
            localPosition: SIMD3<Float>(0.06, 0.20, 0.09),
            rotationY: -0.35,
            tiltZ: 0.10,
            dropDelay: 2.20
        ),
        CartFoodItemConfig(
            names: ["Carrot_Cake"],
            targetSize: 0.20,
            localPosition: SIMD3<Float>(0.00, 0.22, 0.01),
            rotationY: 0.10,
            tiltZ: 0.0,
            dropDelay: 2.38
        )
    ]
}
