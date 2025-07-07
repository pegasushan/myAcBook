import StoreKit
import Foundation

class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var isAdRemoved: Bool = UserDefaults.standard.bool(forKey: "isAdRemoved")
    var product: Product?

    func purchase() async {
        let storeProducts = try? await Product.products(for: ["remove_ads_v2"])
        self.product = storeProducts?.first
        guard self.product != nil else {
            print("❌ product 가 nil 입니다.")
            return
        }
        // 실제 구매 로직...
        UserDefaults.standard.set(true, forKey: "isAdRemoved")
        isAdRemoved = true
    }

    func restore() async {
        // 복원 시에도 Product ID를 'remove_ads_v2'로 사용
        let purchased = UserDefaults.standard.bool(forKey: "isAdRemoved")
        isAdRemoved = purchased
    }

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ["remove_ads_v2"])
            self.product = storeProducts.first
            if self.product != nil {
                print("✅ 상품 불러오기 성공")
            } else {
                print("❌ product 가 nil 입니다.")
            }
        } catch {
            print("❌ 상품 불러오기 실패: \(error)")
        }
    }
}
