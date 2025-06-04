import SwiftUI

struct AppTitleFont: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 24, weight: .semibold, design: .rounded))
    }
}

struct AppSectionTitleFont: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 18, weight: .semibold, design: .rounded))
    }
}

struct AppBodyFont: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 15, weight: .regular, design: .rounded))
    }
}

struct AppCaptionFont: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 13, weight: .regular, design: .rounded))
    }
}

extension View {
    func appTitle() -> some View { self.modifier(AppTitleFont()) }
    func appSectionTitle() -> some View { self.modifier(AppSectionTitleFont()) }
    func appBody() -> some View { self.modifier(AppBodyFont()) }
    func appCaption() -> some View { self.modifier(AppCaptionFont()) }
} 