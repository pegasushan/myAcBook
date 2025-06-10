import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color("SectionBGColor")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)

                Text(NSLocalizedString("app_title", comment: "앱 타이틀"))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("HighlightColor"))
                    .appTitle()
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.6)) {
                    self.scale = 1.0
                    self.opacity = 1.0
                }
            }
        }
    }
}
