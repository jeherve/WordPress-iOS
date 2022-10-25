import SwiftUI

struct JetpackPromptView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(makeFont())
            .foregroundColor(color)
            .padding(Constants.textInsets)
            .accessibility(hidden: true)
    }

    private func makeFont() -> Font {
        return .system(size: Constants.fontSize, weight: .bold).leading(.tight)
    }

    private enum Constants {
        static let textInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let fontSize: CGFloat = 40
    }
}
