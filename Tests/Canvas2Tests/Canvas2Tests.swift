import XCTest
@testable import Canvas2

final class Canvas2Tests: XCTestCase {
    
    func testPathMethod() {
        do {
            let testMethods: [ShapePath.Method] = [.stroke(2), .dash(1, 2, [3, 4]), .fill]
            for method in testMethods {
                let data = try JSONEncoder().encode(method)
                let result = try JSONDecoder().decode(ShapePath.Method.self, from: data)
                XCTAssertEqual(result, method)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPath() {
        let cgPath = CGMutablePath()
        cgPath.addArc(center: .zero, radius: 1, startAngle: 0, endAngle: .pi, clockwise: true)
        let path = ShapePath(path: cgPath, method: .stroke(1), color: .blue)
        do {
            let data = try JSONEncoder().encode(path)
            let result = try JSONDecoder().decode(ShapePath.self, from: data)
            XCTAssertEqual(path.cgPath.elements(), result.cgPath.elements())
            XCTAssertEqual(path.method, result.method)
            XCTAssertEqual(path.color, result.color)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testText() {
        let str = "content"
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.blue,
            .font: NSFont.systemFont(ofSize: 16)
        ]
        let text = ShapeText(string: .init(string: str, attributes: attrs), at: .zero, rotation: .pi)
        do {
            let data = try JSONEncoder().encode(text)
            let result = try JSONDecoder().decode(ShapeText.self, from: data)
            XCTAssertEqual(result.string, NSAttributedString(string: str, attributes: attrs))
            XCTAssertEqual(result.point, text.point)
            XCTAssertEqual(result.angle, text.angle)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    static var allTests = [
        ("testPathMethod", testPathMethod),
        ("testPath", testPath)
    ]
}
