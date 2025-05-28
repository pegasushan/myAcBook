//
//  PurchaseManager.swift
//  myAcBook
//
//  Created by 한상욱 on 5/19/25.
//

import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    @Published var isAdRemoved: Bool = UserDefaults.standard.bool(forKey: "isAdRemoved")
    private var product: Product?

    init() {
        Task {
            await loadProduct()
        }
    }

    func loadProduct() async {
        do {
            print("🔹 loadProduct() 실행됨")
            let storeProducts = try await Product.products(for: ["remove_ads"])
            product = storeProducts.first

            if let product = product {
                print("✅ 제품 로드됨: \(product.displayName)")
            } else {
                print("❌ product 가 nil 입니다.")
            }
        } catch {
            print("🔴 제품 로딩 실패:", error)
        }
    }

    func purchase() async {
        guard let product else { return }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(_):
                UserDefaults.standard.set(true, forKey: "isAdRemoved")
                isAdRemoved = true
                print("✅ 광고 제거 구매 완료")
            default:
                print("🟡 구매 취소 또는 미확정 상태")
            }
        } catch {
            print("🔴 구매 실패:", error)
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            let purchased = UserDefaults.standard.bool(forKey: "isAdRemoved")
            isAdRemoved = purchased
            print("✅ 구매 복원 완료")
        } catch {
            print("🔴 복원 실패:", error)
        }
    }
}
