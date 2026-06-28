import SwiftUI

extension ContentView {
    var moodSection: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 20) {
                MoodCardView()
                Spacer(minLength: 0)
            }
            .zIndex(1)

            RunningCompanionView()
                .zIndex(2)
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
    }
}

struct RunningCompanionView: View {
    @AppStorage("companionAnimal") private var companionRaw = CompanionAnimal.default.rawValue

    @State private var position: CGPoint = CGPoint(x: 100, y: 100)
    @State private var isFacingRight: Bool = false
    @State private var containerSize: CGSize = .zero
    @State private var isHopping = false

    private let moveDuration: TimeInterval = 2.6
    private let moveTimer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    private var animal: CompanionAnimal {
        CompanionAnimal(rawValue: companionRaw) ?? .default
    }

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    containerSize = geometry.size
                    position = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    startHopping()
                    moveToNextPoint()
                }
                .onChange(of: geometry.size) { _, newSize in
                    containerSize = newSize
                    if position == .zero {
                        position = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
                    }
                }
                .allowsHitTesting(false)

            CompanionAnimalView(animal: animal)
                .frame(width: 96, height: 108)
                .scaleEffect(x: isFacingRight ? 1 : -1, y: 1)
                .rotationEffect(.degrees(isHopping ? 3 : -3))
                .offset(y: isHopping ? -10 : 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    moveToNextPoint()
                }
                .position(position)
                .opacity(containerSize == .zero ? 0 : 1)
                .animation(.linear(duration: moveDuration), value: position)
        }
        .onReceive(moveTimer) { _ in
            moveToNextPoint()
        }
    }

    private func startHopping() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            isHopping = true
        }
    }

    private func moveToNextPoint() {
        guard containerSize.width > 0, containerSize.height > 0 else { return }

        let horizontalMargin: CGFloat = 48
        let verticalMargin: CGFloat = 44
        let minX = min(horizontalMargin, containerSize.width / 2)
        let maxX = max(minX, containerSize.width - horizontalMargin)
        let minY = min(verticalMargin, containerSize.height / 2)
        let maxY = max(minY, containerSize.height - verticalMargin)

        var nextPoint = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )

        for _ in 0..<8 {
            let candidate = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: CGFloat.random(in: minY...maxY)
            )
            let distance = sqrt(pow(candidate.x - position.x, 2) + pow(candidate.y - position.y, 2))
            if distance > 90 {
                nextPoint = candidate
                break
            }
        }

        isFacingRight = nextPoint.x > position.x
        position = nextPoint
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
