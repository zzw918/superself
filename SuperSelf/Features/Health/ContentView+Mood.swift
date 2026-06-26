import SwiftUI

extension ContentView {
    var moodSection: some View {
        VStack(spacing: 20) {
            MoodCardView()
        }
    }
}

struct MoodCardView: View {
    @StateObject private var jokeService = JokeService.shared
    @State private var cardScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Label("开心一刻", systemImage: "face.smiling")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                Spacer()
                if jokeService.isLoading {
                    ProgressView()
                        .tint(.orange)
                }
            }

            Text(jokeService.currentJoke)
                .font(.title3.weight(.medium))
                .lineSpacing(8)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.opacity(0.85))
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.horizontal, 10)
                .animation(.easeInOut, value: jokeService.currentJoke)

            Text("点击卡片获取新心情")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .orange.opacity(0.08), radius: 15, x: 0, y: 6)
        .scaleEffect(cardScale)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cardScale = 0.96
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    cardScale = 1.0
                }
            }
            Task {
                await jokeService.fetchJoke()
            }
        }
    }
}
