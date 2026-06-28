import SwiftUI

/// 心情页里陪伴用户的小动物。12 生肖统一为"软萌玩偶"风格：
/// 圆润的坐姿全身、柔和渐变体现立体感、大亮眼、腮红，部分还抱着标志性小道具。
/// 全部用矢量绘制，背景透明、任意分辨率清晰、整组风格一致。
enum CompanionAnimal: String, CaseIterable, Identifiable, Hashable {
    case rat, ox, tiger, rabbit, dragon, snake, horse, goat, monkey, rooster, dog, pig

    var id: String { rawValue }

    static let `default`: CompanionAnimal = .pig

    var name: String {
        switch self {
        case .rat: return "鼠"
        case .ox: return "牛"
        case .tiger: return "虎"
        case .rabbit: return "兔"
        case .dragon: return "龙"
        case .snake: return "蛇"
        case .horse: return "马"
        case .goat: return "羊"
        case .monkey: return "猴"
        case .rooster: return "鸡"
        case .dog: return "狗"
        case .pig: return "猪"
        }
    }

    var bodyRGB: (Double, Double, Double) {
        switch self {
        case .rat: return (0.74, 0.70, 0.66)
        case .ox: return (0.80, 0.66, 0.52)
        case .tiger: return (0.98, 0.69, 0.36)
        case .rabbit: return (1.00, 0.98, 0.98)
        case .dragon: return (0.55, 0.80, 0.55)
        case .snake: return (0.62, 0.80, 0.50)
        case .horse: return (0.84, 0.60, 0.39)
        case .goat: return (1.00, 0.99, 0.97)
        case .monkey: return (0.66, 0.45, 0.33)
        case .rooster: return (1.00, 0.90, 0.50)
        case .dog: return (0.93, 0.83, 0.66)
        case .pig: return (1.00, 0.78, 0.82)
        }
    }

    var featureRGB: (Double, Double, Double) {
        switch self {
        case .rat: return (0.97, 0.78, 0.80)
        case .ox: return (0.42, 0.30, 0.22)
        case .tiger: return (0.32, 0.22, 0.18)
        case .rabbit: return (0.98, 0.80, 0.83)
        case .dragon: return (0.97, 0.83, 0.38)
        case .snake: return (0.96, 0.94, 0.78)
        case .horse: return (0.40, 0.27, 0.18)
        case .goat: return (0.86, 0.82, 0.74)
        case .monkey: return (0.95, 0.82, 0.68)
        case .rooster: return (0.93, 0.33, 0.30)
        case .dog: return (0.64, 0.49, 0.34)
        case .pig: return (0.97, 0.60, 0.66)
        }
    }

    var bodyColor: Color { Self.color(bodyRGB) }
    var featureColor: Color { Self.color(featureRGB) }

    static func color(_ c: (Double, Double, Double)) -> Color {
        Color(red: c.0, green: c.1, blue: c.2)
    }
}

/// 把 CompanionAnimal 画成统一软萌玩偶风格的矢量小动物，背景透明、任意分辨率清晰。
struct CompanionAnimalView: View {
    let animal: CompanionAnimal

    var body: some View {
        Canvas { context, size in
            CompanionAnimalRenderer.draw(animal, in: context, size: size)
        }
    }
}

private enum CompanionAnimalRenderer {
    private static let ink = Color(red: 0.24, green: 0.18, blue: 0.18)
    private static let blush = Color(red: 1.0, green: 0.62, blue: 0.66)

    // MARK: - 颜色工具

    static func lighten(_ c: (Double, Double, Double), _ f: Double) -> Color {
        Color(red: c.0 + (1 - c.0) * f, green: c.1 + (1 - c.1) * f, blue: c.2 + (1 - c.2) * f)
    }
    static func darken(_ c: (Double, Double, Double), _ f: Double) -> Color {
        Color(red: c.0 * (1 - f), green: c.1 * (1 - f), blue: c.2 * (1 - f))
    }
    /// 竖直方向的柔和渐变，营造玩偶的体积感（上亮下暗）。
    static func plush(_ c: (Double, Double, Double), _ rect: CGRect, top: Double = 0.26, bottom: Double = 0.16) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [lighten(c, top), CompanionAnimal.color(c), darken(c, bottom)]),
            startPoint: CGPoint(x: rect.midX, y: rect.minY),
            endPoint: CGPoint(x: rect.midX, y: rect.maxY)
        )
    }

    // MARK: - 入口

    static func draw(_ animal: CompanionAnimal, in context: GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        let body = bodyRect(animal, w: w, h: h)
        let head = headRect(animal, w: w, h: h)

        drawTail(animal, context: context, body: body, head: head)
        drawBehindHead(animal, context: context, head: head)
        drawBodyAndFeet(animal, context: context, body: body, head: head)
        drawArmsAndProps(animal, context: context, body: body, head: head, back: true)
        drawHead(animal, context: context, head: head)
        drawFace(animal, context: context, head: head)
        drawArmsAndProps(animal, context: context, body: body, head: head, back: false)
    }

    private static func headRect(_ animal: CompanionAnimal, w: CGFloat, h: CGFloat) -> CGRect {
        let r: CGFloat
        switch animal {
        case .pig, .tiger, .rabbit, .rat: r = w * 0.27
        case .snake: r = w * 0.20
        default: r = w * 0.25
        }
        let cy = h * (animal == .snake ? 0.30 : 0.345)
        return CGRect(x: w / 2 - r, y: cy - r, width: r * 2, height: r * 2)
    }

    private static func bodyRect(_ animal: CompanionAnimal, w: CGFloat, h: CGFloat) -> CGRect {
        let bw = w * (animal == .pig ? 0.58 : 0.52)
        let bh = h * 0.46
        return CGRect(x: w / 2 - bw / 2, y: h * 0.92 - bh, width: bw, height: bh)
    }

    // MARK: - 身体 + 脚

    private static func drawBodyAndFeet(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect, head: CGRect) {
        let comp = animal.bodyRGB

        // 脚
        let footW = body.width * 0.30, footH = body.height * 0.20
        for sign in [-1.0, 1.0] {
            let fx = body.midX + CGFloat(sign) * body.width * 0.24
            let rect = CGRect(x: fx - footW / 2, y: body.maxY - footH * 0.7, width: footW, height: footH)
            context.fill(Path(ellipseIn: rect), with: .color(darken(comp, 0.04)))
            context.fill(Path(ellipseIn: rect.insetBy(dx: footW * 0.28, dy: footH * 0.30)), with: .color(animal.featureColor.opacity(0.5)))
        }

        // 身体（坐姿圆胖）
        let bodyPath = Path(roundedRect: body, cornerSize: CGSize(width: body.width * 0.5, height: body.height * 0.46))
        context.fill(bodyPath, with: plush(comp, body))

        // 肚皮浅色高光
        let bellyW = body.width * 0.52, bellyH = body.height * 0.66
        let belly = CGRect(x: body.midX - bellyW / 2, y: body.maxY - bellyH - body.height * 0.04, width: bellyW, height: bellyH)
        context.fill(Path(ellipseIn: belly), with: .color(lighten(comp, 0.34).opacity(0.55)))
    }

    // MARK: - 头

    private static func drawHead(_ animal: CompanionAnimal, context: GraphicsContext, head: CGRect) {
        let comp = animal.bodyRGB
        context.fill(Path(ellipseIn: head), with: plush(comp, head, top: 0.30, bottom: 0.12))
        // 顶部柔光
        let glowW = head.width * 0.5, glowH = head.height * 0.34
        let glow = CGRect(x: head.midX - glowW / 2, y: head.minY + head.height * 0.08, width: glowW, height: glowH)
        context.fill(Path(ellipseIn: glow), with: .color(lighten(comp, 0.30).opacity(0.5)))
    }

    // MARK: - 尾巴（身体后方）

    private static func drawTail(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect, head: CGRect) {
        let comp = animal.bodyRGB
        switch animal {
        case .rat:
            var tail = Path()
            tail.move(to: CGPoint(x: body.maxX - body.width * 0.10, y: body.maxY - body.height * 0.30))
            tail.addQuadCurve(to: CGPoint(x: body.maxX + body.width * 0.28, y: body.maxY - body.height * 0.10),
                              control: CGPoint(x: body.maxX + body.width * 0.30, y: body.maxY - body.height * 0.50))
            context.stroke(tail, with: .color(CompanionAnimal.color(animal.featureRGB)), style: StrokeStyle(lineWidth: body.width * 0.05, lineCap: .round))
        case .monkey:
            var tail = Path()
            tail.move(to: CGPoint(x: body.minX + body.width * 0.06, y: body.maxY - body.height * 0.30))
            tail.addQuadCurve(to: CGPoint(x: body.minX - body.width * 0.22, y: body.maxY - body.height * 0.50),
                              control: CGPoint(x: body.minX - body.width * 0.26, y: body.maxY - body.height * 0.05))
            context.stroke(tail, with: .color(darken(comp, 0.05)), style: StrokeStyle(lineWidth: body.width * 0.08, lineCap: .round))
        case .pig:
            var tail = Path()
            let sx = body.maxX - body.width * 0.04
            let sy = body.maxY - body.height * 0.40
            tail.move(to: CGPoint(x: sx, y: sy))
            tail.addCurve(to: CGPoint(x: sx + body.width * 0.16, y: sy - body.height * 0.06),
                          control1: CGPoint(x: sx + body.width * 0.20, y: sy + body.height * 0.04),
                          control2: CGPoint(x: sx + body.width * 0.18, y: sy - body.height * 0.16))
            context.stroke(tail, with: .color(CompanionAnimal.color(animal.featureRGB)), style: StrokeStyle(lineWidth: body.width * 0.045, lineCap: .round))
        case .ox, .horse:
            var tail = Path()
            tail.move(to: CGPoint(x: body.maxX - body.width * 0.08, y: body.maxY - body.height * 0.34))
            tail.addQuadCurve(to: CGPoint(x: body.maxX + body.width * 0.16, y: body.maxY + body.height * 0.02),
                              control: CGPoint(x: body.maxX + body.width * 0.22, y: body.maxY - body.height * 0.30))
            context.stroke(tail, with: .color(CompanionAnimal.color(animal.featureRGB)), style: StrokeStyle(lineWidth: body.width * 0.06, lineCap: .round))
        case .tiger:
            var tail = Path()
            tail.move(to: CGPoint(x: body.maxX - body.width * 0.08, y: body.maxY - body.height * 0.28))
            tail.addQuadCurve(to: CGPoint(x: body.maxX + body.width * 0.22, y: body.maxY - body.height * 0.46),
                              control: CGPoint(x: body.maxX + body.width * 0.26, y: body.maxY - body.height * 0.02))
            context.stroke(tail, with: .color(darken(comp, 0.02)), style: StrokeStyle(lineWidth: body.width * 0.09, lineCap: .round))
        default:
            break
        }
    }

    // MARK: - 头后方：耳朵 / 犄角 / 鸡冠 / 鬃毛

    private static func drawBehindHead(_ animal: CompanionAnimal, context: GraphicsContext, head: CGRect) {
        let cx = head.midX, topY = head.minY, comp = animal.bodyRGB

        switch animal {
        case .rat:
            for sign in [-1.0, 1.0] {
                ear(context, CGPoint(x: cx + CGFloat(sign) * head.width * 0.34, y: topY + head.height * 0.10), head.width * 0.28, comp, animal.featureColor)
            }
        case .monkey:
            for sign in [-1.0, 1.0] {
                ear(context, CGPoint(x: cx + CGFloat(sign) * head.width * 0.50, y: head.midY), head.width * 0.20, comp, animal.featureColor)
            }
        case .tiger:
            for sign in [-1.0, 1.0] {
                ear(context, CGPoint(x: cx + CGFloat(sign) * head.width * 0.32, y: topY + head.height * 0.06), head.width * 0.18, comp, Color(red: 0.32, green: 0.22, blue: 0.18).opacity(0.5))
            }
        case .pig:
            for sign in [-1.0, 1.0] {
                var e = Path()
                let bx = cx + CGFloat(sign) * head.width * 0.30
                e.move(to: CGPoint(x: bx - CGFloat(sign) * head.width * 0.06, y: topY + head.height * 0.10))
                e.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.20, y: topY + head.height * 0.04),
                               control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.16, y: topY - head.height * 0.10))
                e.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.02, y: topY + head.height * 0.26),
                               control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.22, y: topY + head.height * 0.22))
                e.closeSubpath()
                context.fill(e, with: .color(CompanionAnimal.color(comp)))
                context.fill(e, with: .color(animal.featureColor.opacity(0.4)))
            }
        case .rabbit:
            let ew = head.width * 0.24, eh = head.height * 0.78
            for sign in [-1.0, 1.0] {
                let rect = CGRect(x: cx + CGFloat(sign) * head.width * 0.22 - ew / 2, y: topY - eh * 0.74, width: ew, height: eh)
                context.fill(Path(ellipseIn: rect), with: .color(CompanionAnimal.color(comp)))
                context.fill(Path(ellipseIn: rect.insetBy(dx: ew * 0.30, dy: eh * 0.16)), with: .color(animal.featureColor))
            }
        case .horse:
            for sign in [-1.0, 1.0] {
                var e = Path()
                let bx = cx + CGFloat(sign) * head.width * 0.28
                e.move(to: CGPoint(x: bx, y: topY + head.height * 0.18))
                e.addLine(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.02, y: topY - head.height * 0.20))
                e.addLine(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.18, y: topY + head.height * 0.12))
                e.closeSubpath()
                context.fill(e, with: .color(CompanionAnimal.color(comp)))
            }
            // 鬃毛
            var mane = Path()
            mane.move(to: CGPoint(x: cx - head.width * 0.10, y: topY + head.height * 0.04))
            mane.addQuadCurve(to: CGPoint(x: cx, y: topY - head.height * 0.22), control: CGPoint(x: cx - head.width * 0.12, y: topY - head.height * 0.18))
            mane.addQuadCurve(to: CGPoint(x: cx + head.width * 0.10, y: topY + head.height * 0.04), control: CGPoint(x: cx + head.width * 0.12, y: topY - head.height * 0.18))
            mane.addQuadCurve(to: CGPoint(x: cx, y: topY + head.height * 0.20), control: CGPoint(x: cx, y: topY + head.height * 0.12))
            mane.closeSubpath()
            context.fill(mane, with: .color(CompanionAnimal.color(animal.featureRGB)))
        case .dog:
            let ew = head.width * 0.30, eh = head.height * 0.66
            for sign in [-1.0, 1.0] {
                let rect = CGRect(x: cx + CGFloat(sign) * head.width * 0.40 - ew / 2, y: topY + head.height * 0.04, width: ew, height: eh)
                context.fill(Path(ellipseIn: rect), with: .color(CompanionAnimal.color(animal.featureRGB)))
            }
        case .ox:
            for sign in [-1.0, 1.0] {
                let er = head.width * 0.16
                context.fill(Path(ellipseIn: CGRect(x: cx + CGFloat(sign) * head.width * 0.46 - er, y: topY + head.height * 0.20, width: er * 2, height: er * 1.5)), with: .color(CompanionAnimal.color(comp)))
            }
            for sign in [-1.0, 1.0] { oxHorn(context, head, sign) }
        case .goat:
            for sign in [-1.0, 1.0] {
                let er = head.width * 0.18
                context.fill(Path(ellipseIn: CGRect(x: cx + CGFloat(sign) * head.width * 0.46 - er, y: topY + head.height * 0.26, width: er * 2, height: er * 1.4)), with: .color(CompanionAnimal.color(comp)))
            }
            for sign in [-1.0, 1.0] { goatHorn(context, head, sign, animal.featureColor) }
        case .dragon:
            for sign in [-1.0, 1.0] { dragonHorn(context, head, sign, animal.featureColor) }
            // 背鳍/小刺沿头顶
            for i in -1...1 {
                var spike = Path()
                let sx = cx + CGFloat(i) * head.width * 0.16
                spike.move(to: CGPoint(x: sx - head.width * 0.06, y: topY + head.height * 0.06))
                spike.addLine(to: CGPoint(x: sx, y: topY - head.height * 0.10))
                spike.addLine(to: CGPoint(x: sx + head.width * 0.06, y: topY + head.height * 0.06))
                spike.closeSubpath()
                context.fill(spike, with: .color(CompanionAnimal.color(animal.featureRGB).opacity(0.9)))
            }
        case .rooster:
            for i in -1...1 {
                let r = head.width * 0.12 * (i == 0 ? 1.25 : 1.0)
                context.fill(Path(ellipseIn: CGRect(x: cx + CGFloat(i) * head.width * 0.16 - r, y: topY - head.height * 0.16, width: r * 2, height: r * 2)), with: .color(animal.featureColor))
            }
        case .snake:
            break
        }
    }

    // MARK: - 脸：眼睛 / 腮红 / 口鼻 / 花纹

    private static func drawFace(_ animal: CompanionAnimal, context: GraphicsContext, head: CGRect) {
        let cx = head.midX

        // 浅色脸盘 / 嘴鼻区
        switch animal {
        case .monkey:
            let fw = head.width * 0.66, fh = head.height * 0.74
            context.fill(Path(ellipseIn: CGRect(x: cx - fw / 2, y: head.minY + head.height * 0.24, width: fw, height: fh)), with: .color(animal.featureColor))
        case .tiger:
            let fw = head.width * 0.52, fh = head.height * 0.40
            context.fill(Path(ellipseIn: CGRect(x: cx - fw / 2, y: head.minY + head.height * 0.50, width: fw, height: fh)), with: .color(.white.opacity(0.7)))
        case .dog, .ox, .horse:
            let fw = head.width * 0.50, fh = head.height * 0.40
            context.fill(Path(ellipseIn: CGRect(x: cx - fw / 2, y: head.minY + head.height * 0.50, width: fw, height: fh)), with: .color(.white.opacity(animal == .ox ? 0.4 : 0.35)))
        default:
            break
        }

        let eyeY = head.minY + head.height * (animal == .snake ? 0.42 : 0.50)
        let eyeDX = head.width * (animal == .snake ? 0.22 : 0.24)
        let eyeR = head.width * 0.10

        for sign in [-1.0, 1.0] {
            let ex = cx + CGFloat(sign) * eyeDX
            let eye = CGRect(x: ex - eyeR, y: eyeY - eyeR * 1.1, width: eyeR * 2, height: eyeR * 2.2)
            context.fill(Path(ellipseIn: eye), with: .color(ink))
            // 大高光 + 小高光
            let g1 = eyeR * 0.46
            context.fill(Path(ellipseIn: CGRect(x: ex - g1 + eyeR * 0.30, y: eye.minY + eyeR * 0.35, width: g1 * 2, height: g1 * 2)), with: .color(.white.opacity(0.95)))
            let g2 = eyeR * 0.20
            context.fill(Path(ellipseIn: CGRect(x: ex - g2 - eyeR * 0.30, y: eye.maxY - eyeR * 0.9, width: g2 * 2, height: g2 * 2)), with: .color(.white.opacity(0.7)))
        }

        // 腮红
        let blushR = head.width * 0.11
        let blushY = eyeY + head.height * 0.14
        for sign in [-1.0, 1.0] {
            let bx = cx + CGFloat(sign) * head.width * 0.36
            context.fill(Path(ellipseIn: CGRect(x: bx - blushR, y: blushY - blushR * 0.6, width: blushR * 2, height: blushR * 1.2)), with: .color(blush.opacity(0.5)))
        }

        drawMuzzle(animal, context: context, head: head, eyeY: eyeY)
        drawFaceMarks(animal, context: context, head: head, eyeY: eyeY)
    }

    private static func drawMuzzle(_ animal: CompanionAnimal, context: GraphicsContext, head: CGRect, eyeY: CGFloat) {
        let cx = head.midX
        let noseY = eyeY + head.height * 0.20

        switch animal {
        case .pig:
            let sw = head.width * 0.40, sh = head.height * 0.28
            let snout = CGRect(x: cx - sw / 2, y: noseY - sh / 2, width: sw, height: sh)
            context.fill(Path(ellipseIn: snout), with: plush(animal.featureRGB, snout, top: 0.18, bottom: 0.12))
            let nw = sw * 0.15, nh = sh * 0.42
            for sign in [-1.0, 1.0] {
                let nx = cx + CGFloat(sign) * sw * 0.18
                context.fill(Path(ellipseIn: CGRect(x: nx - nw / 2, y: noseY - nh / 2, width: nw, height: nh)), with: .color(ink.opacity(0.65)))
            }
        case .rooster:
            let bw = head.width * 0.22, bh = head.height * 0.14
            var beak = Path()
            beak.move(to: CGPoint(x: cx - bw / 2, y: noseY - bh * 0.2))
            beak.addLine(to: CGPoint(x: cx + bw / 2, y: noseY - bh * 0.2))
            beak.addLine(to: CGPoint(x: cx, y: noseY + bh))
            beak.closeSubpath()
            context.fill(beak, with: .color(Color(red: 0.97, green: 0.62, blue: 0.20)))
        case .snake:
            noseDot(context, cx, noseY - head.height * 0.02, head.width * 0.035)
            var tongue = Path()
            let ty = noseY + head.height * 0.06
            tongue.move(to: CGPoint(x: cx, y: ty))
            tongue.addLine(to: CGPoint(x: cx, y: ty + head.height * 0.12))
            tongue.addLine(to: CGPoint(x: cx - head.width * 0.06, y: ty + head.height * 0.18))
            tongue.move(to: CGPoint(x: cx, y: ty + head.height * 0.12))
            tongue.addLine(to: CGPoint(x: cx + head.width * 0.06, y: ty + head.height * 0.18))
            context.stroke(tongue, with: .color(Color(red: 0.92, green: 0.34, blue: 0.40)), style: StrokeStyle(lineWidth: head.width * 0.028, lineCap: .round))
        case .horse, .ox:
            let nw = head.width * 0.07, nh = head.height * 0.10
            let ny = noseY + head.height * 0.02
            for sign in [-1.0, 1.0] {
                let nx = cx + CGFloat(sign) * head.width * 0.12
                context.fill(Path(ellipseIn: CGRect(x: nx - nw / 2, y: ny - nh / 2, width: nw, height: nh)), with: .color(ink.opacity(0.5)))
            }
        case .dog:
            let nr = head.width * 0.075
            context.fill(Path(ellipseIn: CGRect(x: cx - nr, y: noseY - head.height * 0.06, width: nr * 2, height: nr * 1.7)), with: .color(ink.opacity(0.9)))
            smile(context, cx: cx, y: noseY + head.height * 0.08, w: head.width * 0.12, h: head.height * 0.05)
        case .dragon:
            noseDot(context, cx - head.width * 0.07, noseY - head.height * 0.04, head.width * 0.028)
            noseDot(context, cx + head.width * 0.07, noseY - head.height * 0.04, head.width * 0.028)
            smile(context, cx: cx, y: noseY + head.height * 0.04, w: head.width * 0.16, h: head.height * 0.05)
        default:
            noseDot(context, cx, noseY - head.height * 0.02, head.width * 0.05)
            smile(context, cx: cx, y: noseY + head.height * 0.05, w: head.width * 0.12, h: head.height * 0.05)
        }
    }

    private static func drawFaceMarks(_ animal: CompanionAnimal, context: GraphicsContext, head: CGRect, eyeY: CGFloat) {
        let cx = head.midX
        switch animal {
        case .tiger:
            for sign in [-1.0, 0.0, 1.0] {
                var s = Path()
                let sx = cx + CGFloat(sign) * head.width * 0.12
                s.move(to: CGPoint(x: sx, y: head.minY + head.height * 0.10))
                s.addLine(to: CGPoint(x: sx, y: head.minY + head.height * 0.26))
                context.stroke(s, with: .color(animal.featureColor.opacity(0.85)), style: StrokeStyle(lineWidth: head.width * 0.03, lineCap: .round))
            }
            for sign in [-1.0, 1.0] {
                var s = Path()
                let sx = cx + CGFloat(sign) * head.width * 0.40
                s.move(to: CGPoint(x: sx, y: eyeY - head.height * 0.02))
                s.addLine(to: CGPoint(x: sx + CGFloat(sign) * head.width * 0.06, y: eyeY + head.height * 0.10))
                context.stroke(s, with: .color(animal.featureColor.opacity(0.7)), style: StrokeStyle(lineWidth: head.width * 0.025, lineCap: .round))
            }
        case .dragon:
            for sign in [-1.0, 1.0] {
                var wsk = Path()
                let sx = cx + CGFloat(sign) * head.width * 0.24
                let sy = eyeY + head.height * 0.16
                wsk.move(to: CGPoint(x: sx, y: sy))
                wsk.addQuadCurve(to: CGPoint(x: sx + CGFloat(sign) * head.width * 0.34, y: sy + head.height * 0.04),
                                 control: CGPoint(x: sx + CGFloat(sign) * head.width * 0.26, y: sy - head.height * 0.12))
                context.stroke(wsk, with: .color(CompanionAnimal.color(animal.featureRGB)), style: StrokeStyle(lineWidth: head.width * 0.022, lineCap: .round))
            }
        default:
            break
        }
    }

    // MARK: - 手臂 + 道具

    private static func drawArmsAndProps(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect, head: CGRect, back: Bool) {
        switch animal {
        case .rat:
            if back { return }
            paws(context, body, animal)
            cheese(context, CGRect(x: body.midX - body.width * 0.22, y: body.midY - body.height * 0.04, width: body.width * 0.44, height: body.height * 0.40))
        case .rabbit:
            if back { return }
            paws(context, body, animal)
            carrot(context, CGRect(x: body.midX - body.width * 0.15, y: body.midY - body.height * 0.16, width: body.width * 0.30, height: body.height * 0.58))
        case .monkey:
            if back { return }
            paws(context, body, animal)
            banana(context, CGRect(x: body.midX - body.width * 0.26, y: body.midY - body.height * 0.02, width: body.width * 0.52, height: body.height * 0.34))
        case .dog:
            if back { return }
            bone(context, CGRect(x: body.midX - body.width * 0.24, y: body.maxY - body.height * 0.18, width: body.width * 0.48, height: body.height * 0.16))
        case .rooster:
            if !back { wing(context, body, animal) }
        default:
            break
        }
    }

    // MARK: - 零件

    private static func paws(_ context: GraphicsContext, _ body: CGRect, _ animal: CompanionAnimal) {
        let pw = body.width * 0.16
        for sign in [-1.0, 1.0] {
            let px = body.midX + CGFloat(sign) * body.width * 0.18
            context.fill(Path(ellipseIn: CGRect(x: px - pw / 2, y: body.midY + body.height * 0.06, width: pw, height: pw)), with: .color(animal.bodyColor))
        }
    }

    private static func wing(_ context: GraphicsContext, _ body: CGRect, _ animal: CompanionAnimal) {
        let w = body.width * 0.30, h = body.height * 0.42
        let rect = CGRect(x: body.midX - body.width * 0.02, y: body.midY - body.height * 0.06, width: w, height: h)
        context.fill(Path(ellipseIn: rect), with: .color(darken(animal.bodyRGB, 0.10)))
    }

    private static func ear(_ context: GraphicsContext, _ center: CGPoint, _ radius: CGFloat, _ outer: (Double, Double, Double), _ inner: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(CompanionAnimal.color(outer)))
        let ir = radius * 0.55
        context.fill(Path(ellipseIn: CGRect(x: center.x - ir, y: center.y - ir, width: ir * 2, height: ir * 2)), with: .color(inner))
    }

    private static func noseDot(_ context: GraphicsContext, _ cx: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        context.fill(Path(ellipseIn: CGRect(x: cx - r, y: y - r, width: r * 2, height: r * 1.7)), with: .color(ink.opacity(0.85)))
    }

    private static func smile(_ context: GraphicsContext, cx: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        var m = Path()
        m.move(to: CGPoint(x: cx - w, y: y))
        m.addQuadCurve(to: CGPoint(x: cx, y: y + h), control: CGPoint(x: cx - w * 0.5, y: y + h * 1.1))
        m.addQuadCurve(to: CGPoint(x: cx + w, y: y), control: CGPoint(x: cx + w * 0.5, y: y + h * 1.1))
        context.stroke(m, with: .color(ink.opacity(0.65)), style: StrokeStyle(lineWidth: w * 0.16, lineCap: .round))
    }

    private static func oxHorn(_ context: GraphicsContext, _ head: CGRect, _ sign: Double) {
        let cx = head.midX, topY = head.minY
        var horn = Path()
        let bx = cx + CGFloat(sign) * head.width * 0.16
        horn.move(to: CGPoint(x: bx, y: topY + head.height * 0.10))
        horn.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.42, y: topY - head.height * 0.10), control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.36, y: topY + head.height * 0.16))
        horn.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.30, y: topY - head.height * 0.02), control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.36, y: topY - head.height * 0.08))
        horn.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.04, y: topY + head.height * 0.08), control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.18, y: topY + head.height * 0.04))
        horn.closeSubpath()
        context.fill(horn, with: .color(Color(red: 0.96, green: 0.93, blue: 0.86)))
    }

    private static func goatHorn(_ context: GraphicsContext, _ head: CGRect, _ sign: Double, _ color: Color) {
        let cx = head.midX, topY = head.minY
        var horn = Path()
        let bx = cx + CGFloat(sign) * head.width * 0.20
        horn.move(to: CGPoint(x: bx, y: topY + head.height * 0.06))
        horn.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.22, y: topY - head.height * 0.28), control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.30, y: topY - head.height * 0.02))
        horn.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.06, y: topY + head.height * 0.02), control: CGPoint(x: bx + CGFloat(sign) * head.width * 0.14, y: topY - head.height * 0.12))
        horn.closeSubpath()
        context.fill(horn, with: .color(color))
    }

    private static func dragonHorn(_ context: GraphicsContext, _ head: CGRect, _ sign: Double, _ color: Color) {
        let cx = head.midX, topY = head.minY
        let bx = cx + CGFloat(sign) * head.width * 0.16
        var stem = Path()
        stem.move(to: CGPoint(x: bx, y: topY + head.height * 0.08))
        stem.addLine(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.10, y: topY - head.height * 0.30))
        context.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: head.width * 0.06, lineCap: .round))
        var branch = Path()
        branch.move(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.05, y: topY - head.height * 0.08))
        branch.addLine(to: CGPoint(x: bx + CGFloat(sign) * head.width * 0.22, y: topY - head.height * 0.14))
        context.stroke(branch, with: .color(color), style: StrokeStyle(lineWidth: head.width * 0.045, lineCap: .round))
        let r = head.width * 0.05
        context.fill(Path(ellipseIn: CGRect(x: bx + CGFloat(sign) * head.width * 0.10 - r, y: topY - head.height * 0.30 - r, width: r * 2, height: r * 2)), with: .color(color))
    }

    // MARK: - 道具

    private static func cheese(_ context: GraphicsContext, _ rect: CGRect) {
        var wedge = Path()
        wedge.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        wedge.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        wedge.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        wedge.closeSubpath()
        context.fill(wedge, with: .color(Color(red: 0.99, green: 0.83, blue: 0.32)))
        for p in [CGPoint(x: rect.minX + rect.width * 0.30, y: rect.maxY - rect.height * 0.25),
                  CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.55)] {
            let hr = rect.width * 0.07
            context.fill(Path(ellipseIn: CGRect(x: p.x - hr, y: p.y - hr, width: hr * 2, height: hr * 2)), with: .color(Color(red: 0.95, green: 0.72, blue: 0.20)))
        }
    }

    private static func carrot(_ context: GraphicsContext, _ rect: CGRect) {
        var body = Path()
        body.move(to: CGPoint(x: rect.midX - rect.width * 0.5, y: rect.minY + rect.height * 0.30))
        body.addLine(to: CGPoint(x: rect.midX + rect.width * 0.5, y: rect.minY + rect.height * 0.30))
        body.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        body.closeSubpath()
        context.fill(body, with: .color(Color(red: 0.96, green: 0.55, blue: 0.22)))
        for sign in [-0.5, 0.3, 1.0] {
            let lr = rect.width * 0.22
            let lx = rect.midX + CGFloat(sign) * rect.width * 0.22
            context.fill(Path(ellipseIn: CGRect(x: lx - lr / 2, y: rect.minY, width: lr, height: rect.height * 0.32)), with: .color(Color(red: 0.40, green: 0.72, blue: 0.38)))
        }
    }

    private static func banana(_ context: GraphicsContext, _ rect: CGRect) {
        var b = Path()
        b.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2))
        b.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2), control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.8))
        b.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2), control: CGPoint(x: rect.midX, y: rect.maxY))
        b.closeSubpath()
        context.fill(b, with: .color(Color(red: 0.99, green: 0.84, blue: 0.32)))
    }

    private static func bone(_ context: GraphicsContext, _ rect: CGRect) {
        let knob = rect.height * 0.55
        let midY = rect.midY
        context.fill(Path(roundedRect: CGRect(x: rect.minX + knob * 0.6, y: midY - rect.height * 0.18, width: rect.width - knob * 1.2, height: rect.height * 0.36), cornerRadius: rect.height * 0.18), with: .color(Color(red: 0.98, green: 0.96, blue: 0.90)))
        for sign in [-1.0, 1.0] {
            let cxk = sign < 0 ? rect.minX + knob * 0.5 : rect.maxX - knob * 0.5
            for dy in [-1.0, 1.0] {
                context.fill(Path(ellipseIn: CGRect(x: cxk - knob / 2, y: midY + CGFloat(dy) * knob * 0.3 - knob / 2, width: knob, height: knob)), with: .color(Color(red: 0.98, green: 0.96, blue: 0.90)))
            }
        }
    }
}
