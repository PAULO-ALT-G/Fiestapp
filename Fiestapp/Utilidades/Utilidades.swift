//  Utilidades.swift
//  Fiestapp

import SwiftUI
import UIKit

// MARK: - Tema (colores del diseño)

enum Tema {
    static let teal = Color(red: 0.165, green: 0.620, blue: 0.651)
    static let tealOscuro = Color(red: 0.118, green: 0.447, blue: 0.490)
    static let fondo = Color(red: 0.902, green: 0.949, blue: 0.945)
    static let tarjeta = Color(red: 0.855, green: 0.875, blue: 0.875)
    static let texto = Color(red: 0.122, green: 0.200, blue: 0.220)

    static let coloresAvatar: [Color] = [
        Color(red: 0.95, green: 0.55, blue: 0.40),
        Color(red: 0.45, green: 0.60, blue: 0.90),
        Color(red: 0.60, green: 0.45, blue: 0.80),
        Color(red: 0.95, green: 0.75, blue: 0.30),
        Color(red: 0.40, green: 0.75, blue: 0.55),
        Color(red: 0.90, green: 0.45, blue: 0.60)
    ]
}

extension Font {
    static func fiesta(_ tamano: CGFloat, _ peso: Font.Weight = .regular) -> Font {
        .system(size: tamano, weight: peso, design: .rounded)
    }
}

extension String {
    var limpio: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Dinero (todo en centavos)

enum Dinero {
    static func texto(_ centavos: Int) -> String {
        let formato = NumberFormatter()
        formato.numberStyle = .currency
        formato.locale = Locale(identifier: "es_MX")
        formato.currencySymbol = "$"
        let tieneCentavos = centavos % 100 != 0
        formato.minimumFractionDigits = tieneCentavos ? 2 : 0
        formato.maximumFractionDigits = 2
        return formato.string(from: NSNumber(value: Double(centavos) / 100)) ?? "$0"
    }

    static func centavos(de texto: String) -> Int? {
        let limpio = texto
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .limpio
        guard !limpio.isEmpty, var decimal = Decimal(string: limpio), decimal >= 0 else { return nil }
        decimal *= 100
        var redondeado = Decimal()
        NSDecimalRound(&redondeado, &decimal, 0, .plain)
        return NSDecimalNumber(decimal: redondeado).intValue
    }

    static func textoEditable(_ centavos: Int) -> String {
        centavos % 100 == 0 ? "\(centavos / 100)" : String(format: "%.2f", Double(centavos) / 100)
    }
}

// MARK: - Fechas

enum Formato {
    private static func formateador(_ patron: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = patron
        return f
    }

    static func diaMes(_ fecha: Date) -> String { formateador("dd/MM").string(from: fecha) }
    static func hora(_ fecha: Date) -> String { formateador("HH:mm").string(from: fecha) }
    static func corta(_ fecha: Date) -> String { formateador("dd/MM/yy").string(from: fecha) }
    static func diaHora(_ fecha: Date) -> String { formateador("dd/MM HH:mm").string(from: fecha) }

    static func diaMesLargo(_ fecha: Date) -> String {
        let texto = formateador("d 'de' MMMM").string(from: fecha)
        guard let rango = texto.range(of: "de ") else { return texto }
        let mes = texto[rango.upperBound...]
        return String(texto[..<rango.upperBound]) + mes.prefix(1).uppercased() + String(mes.dropFirst())
    }

    static func finDelDia(_ fecha: Date) -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: fecha) ?? fecha
    }

    static func rango(_ inicio: Date, _ fin: Date) -> String {
        if fin <= inicio { return diaHora(inicio) }
        let mismoDia = Calendar.current.isDate(inicio, inSameDayAs: fin)
        return "\(diaHora(inicio)) – \(mismoDia ? hora(fin) : diaHora(fin))"
    }
}

// MARK: - Teclado

enum Teclado {
    static func ocultar() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

final class GestoOcultarTeclado: NSObject, UIGestureRecognizerDelegate {
    static let compartido = GestoOcultarTeclado()
    private let nombre = "fiestapp.ocultarTeclado"

    func instalar() {
        let ventanas = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for ventana in ventanas {
            let yaTiene = (ventana.gestureRecognizers ?? []).contains { $0.name == nombre }
            if yaTiene { continue }
            let toque = UITapGestureRecognizer(target: self, action: #selector(tocar(_:)))
            toque.name = nombre
            toque.cancelsTouchesInView = false
            toque.delegate = self
            ventana.addGestureRecognizer(toque)
        }
    }

    @objc private func tocar(_ gesto: UITapGestureRecognizer) {
        gesto.view?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var vista = touch.view
        while let actual = vista {
            if actual is UITextField || actual is UITextView { return false }
            vista = actual.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension View {
    func bajarTecladoAlTocarFuera() -> some View {
        self
            .onAppear { GestoOcultarTeclado.compartido.instalar() }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { Teclado.ocultar() }
                        .fontWeight(.semibold)
                }
            }
    }
}

// MARK: - Imágenes

enum Imagenes {
    static func comprimir(_ imagen: UIImage, maximo: CGFloat = 1200) -> Data? {
        let lado = max(imagen.size.width, imagen.size.height)
        let escala = lado > maximo ? maximo / lado : 1
        let tamano = CGSize(width: imagen.size.width * escala, height: imagen.size.height * escala)
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        let nueva = UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            imagen.draw(in: CGRect(origin: .zero, size: tamano))
        }
        return nueva.jpegData(compressionQuality: 0.75)
    }

    static func unirVerticalmente(_ imagenes: [UIImage]) -> UIImage? {
        guard let primera = imagenes.first else { return nil }
        if imagenes.count == 1 { return primera }
        let ancho = imagenes.map(\.size.width).max() ?? primera.size.width
        let alturas = imagenes.map { $0.size.height * (ancho / $0.size.width) }
        let total = CGSize(width: ancho, height: alturas.reduce(0, +))
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: total, format: formato).image { _ in
            var y: CGFloat = 0
            for (imagen, alto) in zip(imagenes, alturas) {
                imagen.draw(in: CGRect(x: 0, y: y, width: ancho, height: alto))
                y += alto
            }
        }
    }

    static func comprimir(data: Data) -> Data? {
        guard let imagen = UIImage(data: data) else { return nil }
        return comprimir(imagen)
    }
}
