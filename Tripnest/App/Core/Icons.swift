import SwiftUI

// Tripnest icon set — SVG-style line icons, viewBox 24×24, stroke 1.75 round.
struct TIcon: View {
    enum Glyph {
        case home, trips, plane, boat, train, car, spot, wallet, user, plus, search, bell,
             arrow, back, more, cam, gallery, heart, cal, filter, star, edit,
             check, close, food, hotel, bus, ticket, gift, globe,
             passport, sun
    }

    let glyph: Glyph
    var size: CGFloat = 22
    var stroke: Color = .tText
    var fill: Color? = nil
    var strokeWidth: CGFloat = 1.75
    var eoFill: Bool = false

    var body: some View {
        Canvas { ctx, rect in
            let scale = rect.width / 24
            ctx.translateBy(x: 0, y: 0)
            ctx.scaleBy(x: scale, y: scale)
            let path = Self.path(for: glyph)
            if let fill = fill {
                ctx.fill(path, with: .color(fill), style: FillStyle(eoFill: eoFill))
            }
            ctx.stroke(path, with: .color(stroke), style: StrokeStyle(
                lineWidth: strokeWidth, lineCap: .round, lineJoin: .round
            ))
        }
        .frame(width: size, height: size)
    }

    static func path(for g: Glyph) -> Path {
        var p = Path()
        switch g {
        case .home:
            p.move(to: CGPoint(x: 3, y: 11))
            p.addLine(to: CGPoint(x: 12, y: 4))
            p.addLine(to: CGPoint(x: 21, y: 11))
            p.addLine(to: CGPoint(x: 21, y: 20))
            p.addQuadCurve(to: CGPoint(x: 20, y: 21), control: CGPoint(x: 21, y: 21))
            p.addLine(to: CGPoint(x: 15, y: 21))
            p.addLine(to: CGPoint(x: 15, y: 15))
            p.addLine(to: CGPoint(x: 9, y: 15))
            p.addLine(to: CGPoint(x: 9, y: 21))
            p.addLine(to: CGPoint(x: 4, y: 21))
            p.addQuadCurve(to: CGPoint(x: 3, y: 20), control: CGPoint(x: 3, y: 21))
            p.closeSubpath()
        case .trips:
            p.move(to: CGPoint(x: 4, y: 7));  p.addLine(to: CGPoint(x: 20, y: 7))
            p.move(to: CGPoint(x: 4, y: 12)); p.addLine(to: CGPoint(x: 20, y: 12))
            p.move(to: CGPoint(x: 4, y: 17)); p.addLine(to: CGPoint(x: 14, y: 17))
        case .plane:
            p.move(to: CGPoint(x: 3.5, y: 12.5))
            p.addLine(to: CGPoint(x: 21, y: 4))
            p.addLine(to: CGPoint(x: 16, y: 21))
            p.addLine(to: CGPoint(x: 12, y: 14))
            p.addLine(to: CGPoint(x: 5, y: 12.5))
            p.closeSubpath()
        case .boat:
            p.move(to: CGPoint(x: 3, y: 15))
            p.addCurve(
                to: CGPoint(x: 21, y: 15),
                control1: CGPoint(x: 9, y: 10),
                control2: CGPoint(x: 15, y: 10)
            )
            p.addLine(to: CGPoint(x: 19.5, y: 19))
            p.addLine(to: CGPoint(x: 4.5, y: 19))
            p.closeSubpath()
            p.addRoundedRect(in: CGRect(x: 8.5, y: 9, width: 7, height: 6), cornerSize: CGSize(width: 1.2, height: 1.2))
            p.move(to: CGPoint(x: 12, y: 9))
            p.addLine(to: CGPoint(x: 12, y: 5.5))
        case .train:
            p.addRoundedRect(in: CGRect(x: 5, y: 6, width: 14, height: 11), cornerSize: CGSize(width: 2, height: 2))
            p.move(to: CGPoint(x: 5, y: 12.5))
            p.addLine(to: CGPoint(x: 19, y: 12.5))
            p.move(to: CGPoint(x: 8, y: 19))
            p.addLine(to: CGPoint(x: 8, y: 17))
            p.move(to: CGPoint(x: 16, y: 19))
            p.addLine(to: CGPoint(x: 16, y: 17))
        case .car:
            p.move(to: CGPoint(x: 4, y: 14))
            p.addLine(to: CGPoint(x: 6.5, y: 10))
            p.addLine(to: CGPoint(x: 17.5, y: 10))
            p.addLine(to: CGPoint(x: 20, y: 14))
            p.addLine(to: CGPoint(x: 20, y: 16))
            p.addLine(to: CGPoint(x: 4, y: 16))
            p.closeSubpath()
            p.addEllipse(in: CGRect(x: 7, y: 16, width: 3, height: 3))
            p.addEllipse(in: CGRect(x: 14, y: 16, width: 3, height: 3))
        case .spot:
            // Épingle carte classique (tête ronde + pointe + trou central)
            let headCenter = CGPoint(x: 12, y: 8.5)
            let headRadius: CGFloat = 5.75
            p.move(to: CGPoint(x: 12, y: 21))
            p.addCurve(
                to: CGPoint(x: headCenter.x - headRadius, y: headCenter.y),
                control1: CGPoint(x: 12, y: 16.5),
                control2: CGPoint(x: 5.5, y: 12)
            )
            p.addArc(
                center: headCenter,
                radius: headRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            p.addCurve(
                to: CGPoint(x: 12, y: 21),
                control1: CGPoint(x: 18.5, y: 12),
                control2: CGPoint(x: 12, y: 16.5)
            )
            p.addEllipse(in: CGRect(x: 9.6, y: 6.1, width: 4.8, height: 4.8))
        case .wallet:
            p.move(to: CGPoint(x: 4, y: 7))
            p.addQuadCurve(to: CGPoint(x: 6, y: 5), control: CGPoint(x: 4, y: 5))
            p.addLine(to: CGPoint(x: 18, y: 5))
            p.addLine(to: CGPoint(x: 18, y: 8))
            p.move(to: CGPoint(x: 4, y: 7))
            p.addLine(to: CGPoint(x: 4, y: 18))
            p.addQuadCurve(to: CGPoint(x: 6, y: 20), control: CGPoint(x: 4, y: 20))
            p.addLine(to: CGPoint(x: 19, y: 20))
            p.addLine(to: CGPoint(x: 20, y: 19))
            p.addLine(to: CGPoint(x: 20, y: 16))
            p.move(to: CGPoint(x: 17, y: 13.5))
            p.addEllipse(in: CGRect(x: 16, y: 13.5, width: 2, height: 2))
        case .user:
            p.addEllipse(in: CGRect(x: 8, y: 4, width: 8, height: 8))
            p.move(to: CGPoint(x: 4, y: 21))
            p.addArc(center: CGPoint(x: 12, y: 21), radius: 8,
                     startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        case .plus:
            p.move(to: CGPoint(x: 12, y: 5)); p.addLine(to: CGPoint(x: 12, y: 19))
            p.move(to: CGPoint(x: 5, y: 12)); p.addLine(to: CGPoint(x: 19, y: 12))
        case .search:
            p.addEllipse(in: CGRect(x: 3, y: 3, width: 16, height: 16))
            p.move(to: CGPoint(x: 21, y: 21)); p.addLine(to: CGPoint(x: 16.7, y: 16.7))
        case .bell:
            p.move(to: CGPoint(x: 6, y: 16))
            p.addLine(to: CGPoint(x: 6, y: 11))
            p.addArc(center: CGPoint(x: 12, y: 11), radius: 6,
                     startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            p.addLine(to: CGPoint(x: 18, y: 16))
            p.addLine(to: CGPoint(x: 19.5, y: 18.5))
            p.addLine(to: CGPoint(x: 4.5, y: 18.5))
            p.closeSubpath()
            p.move(to: CGPoint(x: 10, y: 21))
            p.addArc(center: CGPoint(x: 12, y: 21), radius: 2,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        case .arrow:
            p.move(to: CGPoint(x: 5, y: 12)); p.addLine(to: CGPoint(x: 19, y: 12))
            p.move(to: CGPoint(x: 13, y: 6)); p.addLine(to: CGPoint(x: 19, y: 12)); p.addLine(to: CGPoint(x: 13, y: 18))
        case .back:
            p.move(to: CGPoint(x: 19, y: 12)); p.addLine(to: CGPoint(x: 5, y: 12))
            p.move(to: CGPoint(x: 11, y: 6)); p.addLine(to: CGPoint(x: 5, y: 12)); p.addLine(to: CGPoint(x: 11, y: 18))
        case .more:
            for x in [5.0, 12.0, 19.0] {
                p.addEllipse(in: CGRect(x: x - 1.2, y: 10.8, width: 2.4, height: 2.4))
            }
        case .cam:
            p.move(to: CGPoint(x: 3, y: 8))
            p.addQuadCurve(to: CGPoint(x: 5, y: 6), control: CGPoint(x: 3, y: 6))
            p.addLine(to: CGPoint(x: 7, y: 6))
            p.addLine(to: CGPoint(x: 8.5, y: 4))
            p.addLine(to: CGPoint(x: 15.5, y: 4))
            p.addLine(to: CGPoint(x: 17, y: 6))
            p.addLine(to: CGPoint(x: 19, y: 6))
            p.addQuadCurve(to: CGPoint(x: 21, y: 8), control: CGPoint(x: 21, y: 6))
            p.addLine(to: CGPoint(x: 21, y: 18))
            p.addQuadCurve(to: CGPoint(x: 19, y: 20), control: CGPoint(x: 21, y: 20))
            p.addLine(to: CGPoint(x: 5, y: 20))
            p.addQuadCurve(to: CGPoint(x: 3, y: 18), control: CGPoint(x: 3, y: 20))
            p.closeSubpath()
            p.addEllipse(in: CGRect(x: 8, y: 9, width: 8, height: 8))
        case .gallery:
            p.addRoundedRect(in: CGRect(x: 4, y: 6, width: 16, height: 14), cornerSize: CGSize(width: 2, height: 2))
            p.move(to: CGPoint(x: 4, y: 10))
            p.addLine(to: CGPoint(x: 8.5, y: 14))
            p.addLine(to: CGPoint(x: 12, y: 11.5))
            p.addLine(to: CGPoint(x: 16.5, y: 16))
            p.addLine(to: CGPoint(x: 20, y: 13))
        case .heart:
            p.move(to: CGPoint(x: 12, y: 20))
            p.addCurve(to: CGPoint(x: 5, y: 10),
                       control1: CGPoint(x: 5, y: 15.6),
                       control2: CGPoint(x: 5, y: 10))
            p.addArc(center: CGPoint(x: 8.5, y: 10), radius: 3.5,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addArc(center: CGPoint(x: 15.5, y: 10), radius: 3.5,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addCurve(to: CGPoint(x: 12, y: 20),
                       control1: CGPoint(x: 19, y: 10),
                       control2: CGPoint(x: 19, y: 15.6))
        case .cal:
            p.addRoundedRect(in: CGRect(x: 4, y: 4, width: 16, height: 16), cornerSize: CGSize(width: 2, height: 2))
            p.move(to: CGPoint(x: 4, y: 10)); p.addLine(to: CGPoint(x: 20, y: 10))
            p.move(to: CGPoint(x: 8, y: 3));  p.addLine(to: CGPoint(x: 8, y: 7))
            p.move(to: CGPoint(x: 16, y: 3)); p.addLine(to: CGPoint(x: 16, y: 7))
        case .filter:
            p.move(to: CGPoint(x: 4, y: 6));  p.addLine(to: CGPoint(x: 20, y: 6))
            p.move(to: CGPoint(x: 7, y: 12)); p.addLine(to: CGPoint(x: 17, y: 12))
            p.move(to: CGPoint(x: 10, y: 18)); p.addLine(to: CGPoint(x: 14, y: 18))
        case .star:
            p.move(to: CGPoint(x: 12, y: 3.5))
            p.addLine(to: CGPoint(x: 14.7, y: 9))
            p.addLine(to: CGPoint(x: 20.7, y: 9.9))
            p.addLine(to: CGPoint(x: 16.3, y: 14.1))
            p.addLine(to: CGPoint(x: 17.35, y: 20.1))
            p.addLine(to: CGPoint(x: 12, y: 17.3))
            p.addLine(to: CGPoint(x: 6.6, y: 20.1))
            p.addLine(to: CGPoint(x: 7.7, y: 14))
            p.addLine(to: CGPoint(x: 3.3, y: 9.9))
            p.addLine(to: CGPoint(x: 9.3, y: 9))
            p.closeSubpath()
        case .edit:
            p.move(to: CGPoint(x: 4, y: 20))
            p.addLine(to: CGPoint(x: 8, y: 20))
            p.addLine(to: CGPoint(x: 19, y: 9))
            p.addLine(to: CGPoint(x: 15, y: 5))
            p.addLine(to: CGPoint(x: 4, y: 16))
            p.closeSubpath()
            p.move(to: CGPoint(x: 14, y: 6)); p.addLine(to: CGPoint(x: 18, y: 10))
        case .check:
            p.move(to: CGPoint(x: 5, y: 12)); p.addLine(to: CGPoint(x: 9, y: 16)); p.addLine(to: CGPoint(x: 19, y: 6))
        case .close:
            p.move(to: CGPoint(x: 6, y: 6)); p.addLine(to: CGPoint(x: 18, y: 18))
            p.move(to: CGPoint(x: 18, y: 6)); p.addLine(to: CGPoint(x: 6, y: 18))
        case .food:
            p.move(to: CGPoint(x: 5, y: 3)); p.addLine(to: CGPoint(x: 5, y: 11))
            p.addArc(center: CGPoint(x: 6.5, y: 11), radius: 1.5,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: 8, y: 21))
            p.move(to: CGPoint(x: 8, y: 3));  p.addLine(to: CGPoint(x: 8, y: 9))
            p.move(to: CGPoint(x: 11, y: 3)); p.addLine(to: CGPoint(x: 11, y: 9))
            p.move(to: CGPoint(x: 17, y: 3))
            p.addQuadCurve(to: CGPoint(x: 14, y: 8), control: CGPoint(x: 14, y: 4))
            p.addQuadCurve(to: CGPoint(x: 17, y: 12), control: CGPoint(x: 14, y: 12))
            p.addLine(to: CGPoint(x: 17, y: 21))
        case .hotel:
            p.move(to: CGPoint(x: 3, y: 20)); p.addLine(to: CGPoint(x: 3, y: 7))
            p.move(to: CGPoint(x: 3, y: 14)); p.addLine(to: CGPoint(x: 21, y: 14)); p.addLine(to: CGPoint(x: 21, y: 20))
            p.addEllipse(in: CGRect(x: 5, y: 7, width: 4, height: 4))
            p.move(to: CGPoint(x: 11, y: 14)); p.addLine(to: CGPoint(x: 11, y: 11))
            p.addArc(center: CGPoint(x: 13, y: 11), radius: 2,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: 19, y: 9))
            p.addArc(center: CGPoint(x: 19, y: 11), radius: 2,
                     startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: 21, y: 14))
        case .bus:
            p.addRoundedRect(in: CGRect(x: 5, y: 5, width: 14, height: 12), cornerSize: CGSize(width: 2, height: 2))
            p.move(to: CGPoint(x: 5, y: 12)); p.addLine(to: CGPoint(x: 19, y: 12))
            p.move(to: CGPoint(x: 8, y: 21)); p.addLine(to: CGPoint(x: 8, y: 19))
            p.move(to: CGPoint(x: 16, y: 21)); p.addLine(to: CGPoint(x: 16, y: 19))
            p.addEllipse(in: CGRect(x: 8.6, y: 15.6, width: 0.8, height: 0.8))
            p.addEllipse(in: CGRect(x: 14.6, y: 15.6, width: 0.8, height: 0.8))
        case .ticket:
            p.move(to: CGPoint(x: 3, y: 9))
            p.addQuadCurve(to: CGPoint(x: 5, y: 7), control: CGPoint(x: 3, y: 7))
            p.addLine(to: CGPoint(x: 19, y: 7))
            p.addQuadCurve(to: CGPoint(x: 21, y: 9), control: CGPoint(x: 21, y: 7))
            p.addLine(to: CGPoint(x: 21, y: 11))
            p.addArc(center: CGPoint(x: 21, y: 13), radius: 2,
                     startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
            p.addLine(to: CGPoint(x: 21, y: 17))
            p.addQuadCurve(to: CGPoint(x: 19, y: 19), control: CGPoint(x: 21, y: 19))
            p.addLine(to: CGPoint(x: 5, y: 19))
            p.addQuadCurve(to: CGPoint(x: 3, y: 17), control: CGPoint(x: 3, y: 19))
            p.addLine(to: CGPoint(x: 3, y: 15))
            p.addArc(center: CGPoint(x: 3, y: 13), radius: 2,
                     startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            p.closeSubpath()
            p.move(to: CGPoint(x: 10, y: 7)); p.addLine(to: CGPoint(x: 10, y: 17))
        case .gift:
            p.move(to: CGPoint(x: 4, y: 12)); p.addLine(to: CGPoint(x: 20, y: 12))
            p.addLine(to: CGPoint(x: 20, y: 20)); p.addLine(to: CGPoint(x: 4, y: 20)); p.closeSubpath()
            p.addRect(CGRect(x: 3, y: 8, width: 18, height: 4))
            p.move(to: CGPoint(x: 12, y: 8)); p.addLine(to: CGPoint(x: 12, y: 21))
        case .globe:
            p.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
            p.move(to: CGPoint(x: 3, y: 12)); p.addLine(to: CGPoint(x: 21, y: 12))
            p.move(to: CGPoint(x: 12, y: 3))
            p.addQuadCurve(to: CGPoint(x: 12, y: 21), control: CGPoint(x: 6, y: 12))
            p.move(to: CGPoint(x: 12, y: 3))
            p.addQuadCurve(to: CGPoint(x: 12, y: 21), control: CGPoint(x: 18, y: 12))
        case .passport:
            p.addRect(CGRect(x: 5, y: 3, width: 14, height: 18))
            p.addEllipse(in: CGRect(x: 9, y: 5, width: 6, height: 6))
            p.move(to: CGPoint(x: 8, y: 17)); p.addLine(to: CGPoint(x: 16, y: 17))
        case .sun:
            p.addEllipse(in: CGRect(x: 7, y: 7, width: 10, height: 10))
            for (x1, y1, x2, y2) in [
                (12.0, 2.0, 12.0, 4.0), (12.0, 20.0, 12.0, 22.0),
                (4.2, 4.2, 5.6, 5.6), (18.4, 18.4, 19.8, 19.8),
                (2.0, 12.0, 4.0, 12.0), (20.0, 12.0, 22.0, 12.0),
                (4.2, 19.8, 5.6, 18.4), (18.4, 5.6, 19.8, 4.2),
            ] {
                p.move(to: CGPoint(x: x1, y: y1)); p.addLine(to: CGPoint(x: x2, y: y2))
            }
        }
        return p
    }
}
