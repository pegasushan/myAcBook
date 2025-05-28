import StoreKit
import Foundation

class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var isAdRemoved: Bool = UserDefaults.standard.bool(forKey: "isPremiumUser")
    var product: Product?

    func purchase() async {
        // ...
    }

    func restore() async {
        // ...
    }

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ["remove_ads"])
            self.product = storeProducts.first
            if let product = self.product {
                print("✅ 상품 불러오기 성공: \(product.displayName)")
            } else {
                print("⚠️ 상품 목록은 받아왔지만 'remove_ads' 상품 없음")
            }
        } catch {
            print("❌ 상품 불러오기 실패: \(error)")
        }
    }
}
