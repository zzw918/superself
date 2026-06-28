import SwiftUI

/// 心情页里陪伴用户的小动物。12 生肖统一为圆润"团子"风格，
/// 共用同一套身体与表情，仅以轮廓（耳朵/口鼻/犄角）和配色区分，保证整组风格一致又各有辨识度。
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

    /// 身体主色（柔和、圆润、符合中国审美的可爱配色）。
    var bodyColor: Color {
        switch self {
        case .rat: return Color(red: 0.80, green: 0.82, blue: 0.88)
        case .ox: return Color(red: 0.78, green: 0.66, blue: 0.55)
        case .tiger: return Color(red: 0.99, green: 0.74, blue: 0.43)
        case .rabbit: return Color(red: 0.99, green: 0.95, blue: 0.96)
        case .dragon: return Color(red: 0.50, green: 0.80, blue: 0.62)
        case .snake: return Color(red: 0.76, green: 0.86, blue: 0.62)
        case .horse: return Color(red: 0.80, green: 0.58, blue: 0.40)
        case .goat: return Color(red: 0.98, green: 0.96, blue: 0.91)
        case .monkey: return Color(red: 0.84, green: 0.66, blue: 0.49)
        case .rooster: return Color(red: 0.99, green: 0.91, blue: 0.56)
        case .dog: return Color(red: 0.94, green: 0.84, blue: 0.68)
        case .pig: return Color(red: 1.00, green: 0.78, blue: 0.83)
        }
    }

    /// 特征色：犄角/鸡冠/喙/口鼻等装饰用色。
    var featureColor: Color {
        switch self {
        case .rat: return Color(red: 0.63, green: 0.66, blue: 0.74)
        case .ox: return Color(red: 0.96, green: 0.93, blue: 0.86)
        case .tiger: return Color(red: 0.36, green: 0.27, blue: 0.22)
        case .rabbit: return Color(red: 0.98, green: 0.78, blue: 0.82)
        case .dragon: return Color(red: 0.98, green: 0.82, blue: 0.40)
        case .snake: return Color(red: 0.55, green: 0.71, blue: 0.42)
        case .horse: return Color(red: 0.45, green: 0.32, blue: 0.22)
        case .goat: return Color(red: 0.80, green: 0.74, blue: 0.64)
        case .monkey: return Color(red: 0.98, green: 0.86, blue: 0.74)
        case .rooster: return Color(red: 0.95, green: 0.38, blue: 0.34)
        case .dog: return Color(red: 0.66, green: 0.52, blue: 0.37)
        case .pig: return Color(red: 0.98, green: 0.62, blue: 0.69)
        }
    }
}

/// 把 CompanionAnimal 画成统一团子风格的矢量小动物，背景透明、任意分辨率清晰。
struct CompanionAnimalView: View {
    let animal: CompanionAnimal

    var body: some View {
        Canvas { context, size in
            CompanionAnimalRenderer.draw(animal, in: context, size: size)
        }
    }
}

private enum CompanionAnimalRenderer {
    private static let eyeColor = Color(red: 0.20, green: 0.16, blue: 0.18)
    private static let blushColor = Color(red: 1.0, green: 0.66, blue: 0.71)

    static func draw(_ animal: CompanionAnimal, in context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let bodyW = w * (animal == .pig ? 0.70 : 0.64)
        let bodyH = h * (animal == .pig ? 0.56 : 0.54)
        let body = CGRect(x: (w - bodyW) / 2, y: h * 0.30, width: bodyW, height: bodyH)

        drawBehind(animal, context: context, body: body)
        // 突出的口鼻（马/牛/狗/龙）：先画与身体同色的底，再被身体盖住上半，留下伸出的下半，轮廓自然。
        if let m = protrudingMuzzleRect(animal, body) {
            context.fill(Path(ellipseIn: m), with: .color(animal.bodyColor))
        }
        context.fill(Path(ellipseIn: body), with: .color(animal.bodyColor))
        drawBelly(context: context, body: body)
        drawFront(animal, context: context, body: body)
    }

    // MARK: - 突出口鼻的尺寸

    private static func protrudingMuzzleRect(_ animal: CompanionAnimal, _ body: CGRect) -> CGRect? {
        func rect(_ wF: CGFloat, _ hF: CGFloat, _ centerY: CGFloat) -> CGRect {
            let sw = body.width * wF
            let sh = body.height * hF
            return CGRect(x: body.midX - sw / 2, y: centerY - sh / 2, width: sw, height: sh)
        }
        switch animal {
        case .horse: return rect(0.42, 0.46, body.maxY - body.height * 0.02)
        case .ox: return rect(0.62, 0.38, body.maxY + body.height * 0.02)
        case .dog: return rect(0.50, 0.36, body.maxY + body.height * 0.02)
        case .dragon: return rect(0.44, 0.34, body.maxY + body.height * 0.02)
        default: return nil
        }
    }

    // MARK: - Shared pieces

    private static func drawBelly(context: GraphicsContext, body: CGRect) {
        let bellyW = body.width * 0.50
        let bellyH = body.height * 0.46
        let belly = CGRect(x: body.midX - bellyW / 2, y: body.maxY - bellyH - body.height * 0.04, width: bellyW, height: bellyH)
        context.fill(Path(ellipseIn: belly), with: .color(.white.opacity(0.35)))
    }

    // MARK: - 身体后方的耳朵/犄角/鬃毛

    private static func drawBehind(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect) {
        let cx = body.midX
        let topY = body.minY

        switch animal {
        case .rat:
            let r = body.width * 0.25
            for sign in [-1.0, 1.0] {
                roundEar(context: context, center: CGPoint(x: cx + CGFloat(sign) * body.width * 0.34, y: topY + body.height * 0.06), radius: r, outer: animal.bodyColor, inner: animal.featureColor)
            }
        case .monkey:
            let r = body.width * 0.20
            for sign in [-1.0, 1.0] {
                roundEar(context: context, center: CGPoint(x: cx + CGFloat(sign) * body.width * 0.46, y: topY + body.height * 0.34), radius: r, outer: animal.bodyColor, inner: animal.featureColor)
            }
        case .tiger:
            for sign in [-1.0, 1.0] {
                roundEar(context: context, center: CGPoint(x: cx + CGFloat(sign) * body.width * 0.30, y: topY + body.height * 0.02), radius: body.width * 0.16, outer: animal.bodyColor, inner: animal.featureColor.opacity(0.5))
            }
        case .rabbit:
            let earW = body.width * 0.22
            let earH = body.height * 0.66
            for sign in [-1.0, 1.0] {
                let rect = CGRect(x: cx + CGFloat(sign) * body.width * 0.20 - earW / 2, y: topY - earH * 0.78, width: earW, height: earH)
                context.fill(Path(ellipseIn: rect), with: .color(animal.bodyColor))
                context.fill(Path(ellipseIn: rect.insetBy(dx: earW * 0.28, dy: earH * 0.18)), with: .color(animal.featureColor))
            }
        case .pig:
            for sign in [-1.0, 1.0] {
                var ear = Path()
                let bx = cx + CGFloat(sign) * body.width * 0.32
                ear.move(to: CGPoint(x: bx - CGFloat(sign) * body.width * 0.04, y: topY + body.height * 0.04))
                ear.addQuadCurve(to: CGPoint(x: bx + CGFloat(sign) * body.width * 0.18, y: topY + body.height * 0.22),
                                 control: CGPoint(x: bx + CGFloat(sign) * body.width * 0.22, y: topY - body.height * 0.04))
                ear.addQuadCurve(to: CGPoint(x: bx, y: topY + body.height * 0.16),
                                 control: CGPoint(x: bx + CGFloat(sign) * body.width * 0.04, y: topY + body.height * 0.22))
                ear.closeSubpath()
                context.fill(ear, with: .color(animal.bodyColor))
                context.fill(ear, with: .color(animal.featureColor.opacity(0.35)))
            }
        case .ox:
            for sign in [-1.0, 1.0] {
                let er = body.width * 0.16
                context.fill(Path(ellipseIn: CGRect(x: cx + CGFloat(sign) * body.width * 0.50 - er, y: topY + body.height * 0.26, width: er * 2, height: er * 1.4)), with: .color(animal.bodyColor))
            }
            for sign in [-1.0, 1.0] { oxHorn(context: context, body: body, sign: sign, color: animal.featureColor) }
        case .horse:
            for sign in [-1.0, 1.0] {
                var ear = Path()
                let bx = cx + CGFloat(sign) * body.width * 0.26
                ear.move(to: CGPoint(x: bx, y: topY + body.height * 0.14))
                ear.addLine(to: CGPoint(x: bx + CGFloat(sign) * body.width * 0.02, y: topY - body.height * 0.22))
                ear.addLine(to: CGPoint(x: bx + CGFloat(sign) * body.width * 0.18, y: topY + body.height * 0.08))
                ear.closeSubpath()
                context.fill(ear, with: .color(animal.bodyColor))
            }
            // 鬃毛：头顶居中的一簇，向下垂到额前
            var mane = Path()
            mane.move(to: CGPoint(x: cx - body.width * 0.10, y: topY + body.height * 0.06))
            mane.addQuadCurve(to: CGPoint(x: cx, y: topY - body.height * 0.20), control: CGPoint(x: cx - body.width * 0.10, y: topY - body.height * 0.16))
            mane.addQuadCurve(to: CGPoint(x: cx + body.width * 0.10, y: topY + body.height * 0.06), control: CGPoint(x: cx + body.width * 0.10, y: topY - body.height * 0.16))
            mane.addQuadCurve(to: CGPoint(x: cx, y: topY + body.height * 0.20), control: CGPoint(x: cx, y: topY + body.height * 0.10))
            mane.closeSubpath()
            context.fill(mane, with: .color(animal.featureColor.opacity(0.9)))
        case .dog:
            for sign in [-1.0, 1.0] {
                let earW = body.width * 0.28
                let earH = body.height * 0.60
                let rect = CGRect(x: cx + CGFloat(sign) * body.width * 0.40 - earW / 2, y: topY + body.height * 0.00, width: earW, height: earH)
                context.fill(Path(ellipseIn: rect), with: .color(animal.featureColor))
            }
        case .goat:
            for sign in [-1.0, 1.0] { goatHorn(context: context, body: body, sign: sign, color: animal.featureColor) }
            for sign in [-1.0, 1.0] {
                let earW = body.width * 0.24
                let earH = body.height * 0.22
                let rect = CGRect(x: cx + CGFloat(sign) * body.width * 0.44 - earW / 2, y: topY + body.height * 0.30, width: earW, height: earH)
                context.fill(Path(ellipseIn: rect), with: .color(animal.bodyColor))
            }
            for i in -2...2 {
                let r = body.width * 0.12
                context.fill(Path(ellipseIn: CGRect(x: cx + CGFloat(i) * body.width * 0.15 - r, y: topY - r * 0.5, width: r * 2, height: r * 2)), with: .color(animal.bodyColor))
            }
        case .dragon:
            for sign in [-1.0, 1.0] { dragonAntler(context: context, body: body, sign: sign, color: animal.featureColor) }
        case .rooster:
            for i in -1...1 {
                let r = body.width * 0.11 * (i == 0 ? 1.25 : 1.0)
                context.fill(Path(ellipseIn: CGRect(x: cx + CGFloat(i) * body.width * 0.15 - r, y: topY - body.height * 0.14, width: r * 2, height: r * 2)), with: .color(animal.featureColor))
            }
        case .snake:
            break
        }
    }

    // MARK: - 身体前方：脸盘、眼睛、口鼻、装饰

    private static func drawFront(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect) {
        let cx = body.midX
        let muzzle = protrudingMuzzleRect(animal, body)

        // 突出口鼻上的浅色斑
        if let m = muzzle {
            let patch = CGRect(x: m.minX + m.width * 0.10, y: m.midY - m.height * 0.06, width: m.width * 0.80, height: m.height * 0.58)
            let color: Color = (animal == .ox) ? animal.featureColor : (animal == .dragon ? animal.bodyColor.opacity(0.001) : .white.opacity(0.30))
            if animal != .dragon {
                context.fill(Path(ellipseIn: patch), with: .color(color))
            }
        }

        // 猴：桃心脸盘
        if animal == .monkey {
            let fw = body.width * 0.60, fh = body.height * 0.76
            context.fill(Path(ellipseIn: CGRect(x: cx - fw / 2, y: body.minY + body.height * 0.22, width: fw, height: fh)), with: .color(animal.featureColor))
        }
        // 虎：浅色嘴鼻区
        if animal == .tiger {
            let fw = body.width * 0.46, fh = body.height * 0.42
            context.fill(Path(ellipseIn: CGRect(x: cx - fw / 2, y: body.minY + body.height * 0.46, width: fw, height: fh)), with: .color(.white.opacity(0.55)))
        }

        let eyeY = eyeBaseline(animal, body)
        let metrics = eyeMetrics(animal, body)
        drawEyes(context: context, body: body, dx: metrics.dx, y: eyeY, r: metrics.r)
        drawBlush(animal, context: context, body: body, y: eyeY + body.height * 0.13)
        drawMuzzleDetails(animal, context: context, body: body, eyeY: eyeY, muzzle: muzzle)
        drawOverlays(animal, context: context, body: body, eyeY: eyeY)
    }

    private static func eyeBaseline(_ animal: CompanionAnimal, _ body: CGRect) -> CGFloat {
        let f: CGFloat
        switch animal {
        case .horse: f = 0.32
        case .ox, .dog, .dragon: f = 0.36
        default: f = 0.40
        }
        return body.minY + body.height * f
    }

    private static func eyeMetrics(_ animal: CompanionAnimal, _ body: CGRect) -> (dx: CGFloat, r: CGFloat) {
        switch animal {
        case .pig: return (body.width * 0.20, body.width * 0.088)
        case .dragon: return (body.width * 0.17, body.width * 0.090)
        case .horse: return (body.width * 0.15, body.width * 0.066)
        case .snake: return (body.width * 0.14, body.width * 0.072)
        case .ox: return (body.width * 0.20, body.width * 0.075)
        case .dog: return (body.width * 0.18, body.width * 0.078)
        case .monkey: return (body.width * 0.16, body.width * 0.072)
        default: return (body.width * 0.19, body.width * 0.075)
        }
    }

    private static func drawEyes(context: GraphicsContext, body: CGRect, dx: CGFloat, y: CGFloat, r: CGFloat) {
        for sign in [-1.0, 1.0] {
            let cx = body.midX + CGFloat(sign) * dx
            let eye = CGRect(x: cx - r, y: y - r * 1.15, width: r * 2, height: r * 2.3)
            context.fill(Path(ellipseIn: eye), with: .color(eyeColor))
            let glintR = r * 0.42
            let glint = CGRect(x: cx - glintR + r * 0.35, y: eye.minY + r * 0.45, width: glintR * 2, height: glintR * 2)
            context.fill(Path(ellipseIn: glint), with: .color(.white.opacity(0.9)))
        }
    }

    private static func drawBlush(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect, y: CGFloat) {
        let blushR = body.width * (animal == .pig ? 0.10 : 0.085)
        for sign in [-1.0, 1.0] {
            let cx = body.midX + CGFloat(sign) * body.width * 0.30
            let rect = CGRect(x: cx - blushR, y: y - blushR * 0.62, width: blushR * 2, height: blushR * 1.24)
            context.fill(Path(ellipseIn: rect), with: .color(blushColor.opacity(animal == .pig ? 0.6 : 0.5)))
        }
    }

    private static func drawMuzzleDetails(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect, eyeY: CGFloat, muzzle: CGRect?) {
        let cx = body.midX

        switch animal {
        case .pig:
            let snoutW = body.width * 0.38
            let snoutH = body.height * 0.26
            let snoutY = eyeY + body.height * 0.22
            let snout = CGRect(x: cx - snoutW / 2, y: snoutY - snoutH / 2, width: snoutW, height: snoutH)
            context.fill(Path(ellipseIn: snout), with: .color(animal.featureColor))
            context.fill(Path(ellipseIn: snout.insetBy(dx: snoutW * 0.30, dy: snoutH * 0.18).offsetBy(dx: -snoutW * 0.12, dy: -snoutH * 0.18)), with: .color(.white.opacity(0.35)))
            let nostrilW = snoutW * 0.16, nostrilH = snoutH * 0.42
            for sign in [-1.0, 1.0] {
                let nx = cx + CGFloat(sign) * snoutW * 0.18
                context.fill(Path(ellipseIn: CGRect(x: nx - nostrilW / 2, y: snoutY - nostrilH / 2, width: nostrilW, height: nostrilH)), with: .color(eyeColor.opacity(0.7)))
            }
        case .rooster:
            let beakW = body.width * 0.20, beakH = body.height * 0.13
            let by = eyeY + body.height * 0.18
            var beak = Path()
            beak.move(to: CGPoint(x: cx - beakW / 2, y: by))
            beak.addLine(to: CGPoint(x: cx + beakW / 2, y: by))
            beak.addLine(to: CGPoint(x: cx, y: by + beakH))
            beak.closeSubpath()
            context.fill(beak, with: .color(Color(red: 0.96, green: 0.62, blue: 0.24)))
        case .snake:
            let ny = eyeY + body.height * 0.14
            drawNoseDot(context: context, cx: cx, noseY: ny, r: body.width * 0.03)
            var tongue = Path()
            let ty = ny + body.height * 0.08
            tongue.move(to: CGPoint(x: cx, y: ty))
            tongue.addLine(to: CGPoint(x: cx, y: ty + body.height * 0.10))
            tongue.addLine(to: CGPoint(x: cx - body.width * 0.05, y: ty + body.height * 0.16))
            tongue.move(to: CGPoint(x: cx, y: ty + body.height * 0.10))
            tongue.addLine(to: CGPoint(x: cx + body.width * 0.05, y: ty + body.height * 0.16))
            context.stroke(tongue, with: .color(Color(red: 0.92, green: 0.34, blue: 0.40)), lineWidth: body.width * 0.022)
        case .horse:
            if let m = muzzle {
                let nostrilW = m.width * 0.16, nostrilH = m.height * 0.16
                let ny = m.maxY - m.height * 0.26
                for sign in [-1.0, 1.0] {
                    let nx = cx + CGFloat(sign) * m.width * 0.18
                    context.fill(Path(ellipseIn: CGRect(x: nx - nostrilW / 2, y: ny - nostrilH / 2, width: nostrilW, height: nostrilH)), with: .color(eyeColor.opacity(0.55)))
                }
            }
        case .ox:
            if let m = muzzle {
                let nostrilW = m.width * 0.10, nostrilH = m.height * 0.30
                let ny = m.midY + m.height * 0.04
                for sign in [-1.0, 1.0] {
                    let nx = cx + CGFloat(sign) * m.width * 0.16
                    context.fill(Path(ellipseIn: CGRect(x: nx - nostrilW / 2, y: ny - nostrilH / 2, width: nostrilW, height: nostrilH)), with: .color(eyeColor.opacity(0.5)))
                }
            }
        case .dog:
            if let m = muzzle {
                let noseR = m.width * 0.13
                let nrect = CGRect(x: cx - noseR, y: m.minY + m.height * 0.12, width: noseR * 2, height: noseR * 1.7)
                context.fill(Path(roundedRect: nrect, cornerRadius: noseR * 0.6), with: .color(eyeColor.opacity(0.9)))
                var mouth = Path()
                let my = nrect.maxY + m.height * 0.10
                mouth.move(to: CGPoint(x: cx, y: nrect.maxY))
                mouth.addLine(to: CGPoint(x: cx, y: my))
                mouth.addQuadCurve(to: CGPoint(x: cx - m.width * 0.16, y: my + m.height * 0.04), control: CGPoint(x: cx - m.width * 0.08, y: my + m.height * 0.06))
                mouth.move(to: CGPoint(x: cx, y: my))
                mouth.addQuadCurve(to: CGPoint(x: cx + m.width * 0.16, y: my + m.height * 0.04), control: CGPoint(x: cx + m.width * 0.08, y: my + m.height * 0.06))
                context.stroke(mouth, with: .color(eyeColor.opacity(0.6)), lineWidth: body.width * 0.022)
            }
        case .dragon:
            if let m = muzzle {
                let nostrilR = m.width * 0.06
                let ny = m.minY + m.height * 0.16
                for sign in [-1.0, 1.0] {
                    let nx = cx + CGFloat(sign) * m.width * 0.16
                    context.fill(Path(ellipseIn: CGRect(x: nx - nostrilR, y: ny - nostrilR, width: nostrilR * 2, height: nostrilR * 1.6)), with: .color(eyeColor.opacity(0.55)))
                }
                var mouth = Path()
                let my = m.midY + m.height * 0.18
                mouth.move(to: CGPoint(x: cx - m.width * 0.20, y: my))
                mouth.addQuadCurve(to: CGPoint(x: cx + m.width * 0.20, y: my), control: CGPoint(x: cx, y: my + m.height * 0.20))
                context.stroke(mouth, with: .color(eyeColor.opacity(0.5)), lineWidth: body.width * 0.02)
            }
        default:
            let noseY = eyeY + body.height * 0.18
            drawNoseDot(context: context, cx: cx, noseY: noseY, r: body.width * 0.045)
            var mouth = Path()
            let my = noseY + body.height * 0.06
            mouth.move(to: CGPoint(x: cx - body.width * 0.06, y: my))
            mouth.addQuadCurve(to: CGPoint(x: cx, y: my + body.height * 0.04), control: CGPoint(x: cx - body.width * 0.03, y: my + body.height * 0.05))
            mouth.addQuadCurve(to: CGPoint(x: cx + body.width * 0.06, y: my), control: CGPoint(x: cx + body.width * 0.03, y: my + body.height * 0.05))
            context.stroke(mouth, with: .color(eyeColor.opacity(0.7)), lineWidth: body.width * 0.02)
        }
    }

    private static func drawOverlays(_ animal: CompanionAnimal, context: GraphicsContext, body: CGRect, eyeY: CGFloat) {
        let cx = body.midX

        switch animal {
        case .tiger:
            for sign in [-1.0, 0.0, 1.0] {
                var stripe = Path()
                let sx = cx + CGFloat(sign) * body.width * 0.11
                stripe.move(to: CGPoint(x: sx, y: body.minY + body.height * 0.06))
                stripe.addLine(to: CGPoint(x: sx, y: body.minY + body.height * 0.22))
                context.stroke(stripe, with: .color(animal.featureColor.opacity(0.85)), lineWidth: body.width * 0.03)
            }
            for sign in [-1.0, 1.0] {
                for j in 0..<2 {
                    var stripe = Path()
                    let sx = cx + CGFloat(sign) * body.width * (0.30 + CGFloat(j) * 0.08)
                    stripe.move(to: CGPoint(x: sx, y: eyeY - body.height * 0.02))
                    stripe.addLine(to: CGPoint(x: sx + CGFloat(sign) * body.width * 0.04, y: eyeY + body.height * 0.10))
                    context.stroke(stripe, with: .color(animal.featureColor.opacity(0.7)), lineWidth: body.width * 0.025)
                }
            }
        case .dragon:
            for sign in [-1.0, 1.0] {
                var whisker = Path()
                let sx = cx + CGFloat(sign) * body.width * 0.22
                let sy = eyeY + body.height * 0.16
                whisker.move(to: CGPoint(x: sx, y: sy))
                whisker.addQuadCurve(to: CGPoint(x: sx + CGFloat(sign) * body.width * 0.34, y: sy + body.height * 0.06), control: CGPoint(x: sx + CGFloat(sign) * body.width * 0.26, y: sy - body.height * 0.10))
                context.stroke(whisker, with: .color(animal.featureColor.opacity(0.95)), lineWidth: body.width * 0.02)
            }
            // 眉毛
            for sign in [-1.0, 1.0] {
                var brow = Path()
                let bx = cx + CGFloat(sign) * body.width * 0.17
                brow.move(to: CGPoint(x: bx - body.width * 0.06, y: eyeY - body.height * 0.14))
                brow.addQuadCurve(to: CGPoint(x: bx + body.width * 0.06, y: eyeY - body.height * 0.16), control: CGPoint(x: bx, y: eyeY - body.height * 0.22))
                context.stroke(brow, with: .color(animal.featureColor.opacity(0.8)), lineWidth: body.width * 0.022)
            }
        case .goat:
            let r = body.width * 0.07
            let rect = CGRect(x: cx - r, y: body.maxY - body.height * 0.02, width: r * 2, height: r * 2.6)
            context.fill(Path(ellipseIn: rect), with: .color(animal.bodyColor))
        case .rooster:
            let r = body.width * 0.07
            let rect = CGRect(x: cx - r, y: eyeY + body.height * 0.30, width: r * 2, height: r * 2.2)
            context.fill(Path(ellipseIn: rect), with: .color(animal.featureColor))
        default:
            break
        }
    }

    private static func drawNoseDot(context: GraphicsContext, cx: CGFloat, noseY: CGFloat, r: CGFloat) {
        let rect = CGRect(x: cx - r, y: noseY - r, width: r * 2, height: r * 1.7)
        context.fill(Path(ellipseIn: rect), with: .color(eyeColor.opacity(0.85)))
    }

    // MARK: - Primitives

    private static func roundEar(context: GraphicsContext, center: CGPoint, radius: CGFloat, outer: Color, inner: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(outer))
        let innerR = radius * 0.55
        context.fill(Path(ellipseIn: CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2)), with: .color(inner))
    }

    private static func oxHorn(context: GraphicsContext, body: CGRect, sign: Double, color: Color) {
        let cx = body.midX
        let topY = body.minY
        var horn = Path()
        let baseX = cx + CGFloat(sign) * body.width * 0.16
        horn.move(to: CGPoint(x: baseX, y: topY + body.height * 0.08))
        horn.addQuadCurve(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.40, y: topY - body.height * 0.14), control: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.34, y: topY + body.height * 0.14))
        horn.addQuadCurve(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.30, y: topY - body.height * 0.06), control: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.34, y: topY - body.height * 0.12))
        horn.addQuadCurve(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.04, y: topY + body.height * 0.06), control: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.18, y: topY + body.height * 0.02))
        horn.closeSubpath()
        context.fill(horn, with: .color(color))
    }

    private static func goatHorn(context: GraphicsContext, body: CGRect, sign: Double, color: Color) {
        let cx = body.midX
        let topY = body.minY
        var horn = Path()
        let baseX = cx + CGFloat(sign) * body.width * 0.18
        horn.move(to: CGPoint(x: baseX, y: topY + body.height * 0.06))
        horn.addQuadCurve(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.24, y: topY - body.height * 0.30), control: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.30, y: topY - body.height * 0.04))
        horn.addQuadCurve(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.08, y: topY + body.height * 0.02), control: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.16, y: topY - body.height * 0.12))
        horn.closeSubpath()
        context.fill(horn, with: .color(color))
    }

    private static func dragonAntler(context: GraphicsContext, body: CGRect, sign: Double, color: Color) {
        let topY = body.minY
        let baseX = body.midX + CGFloat(sign) * body.width * 0.14
        // 主干
        var stem = Path()
        stem.move(to: CGPoint(x: baseX, y: topY + body.height * 0.08))
        stem.addLine(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.10, y: topY - body.height * 0.34))
        context.stroke(stem, with: .color(color), lineWidth: body.width * 0.05)
        // 分叉
        var branch = Path()
        branch.move(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.05, y: topY - body.height * 0.10))
        branch.addLine(to: CGPoint(x: baseX + CGFloat(sign) * body.width * 0.22, y: topY - body.height * 0.18))
        context.stroke(branch, with: .color(color), lineWidth: body.width * 0.04)
        // 顶端圆球
        let r = body.width * 0.05
        context.fill(Path(ellipseIn: CGRect(x: baseX + CGFloat(sign) * body.width * 0.10 - r, y: topY - body.height * 0.34 - r, width: r * 2, height: r * 2)), with: .color(color))
        context.fill(Path(ellipseIn: CGRect(x: baseX + CGFloat(sign) * body.width * 0.22 - r * 0.8, y: topY - body.height * 0.18 - r * 0.8, width: r * 1.6, height: r * 1.6)), with: .color(color))
    }
}
