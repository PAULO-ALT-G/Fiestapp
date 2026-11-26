//  RecorteLibreView.swift
//  Fiestapp

import SwiftUI
import UIKit

struct RecorteLibreView: View {
    let imagen: UIImage
    let alTerminar: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var recorte = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var recorteInicial: CGRect?

    private let minimo: CGFloat = 0.08

    private enum Agarre { case arribaIzq, arribaDer, abajoIzq, abajoDer, mover }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Text("Recortar").fontWeight(.semibold)
                Spacer()
                Button("Usar") {
                    alTerminar(recortar())
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .font(.fiesta(17))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            GeometryReader { geo in
                let area = areaImagen(en: geo.size)
                let marco = CGRect(x: area.minX + recorte.minX * area.width,
                                   y: area.minY + recorte.minY * area.height,
                                   width: recorte.width * area.width,
                                   height: recorte.height * area.height)

                ZStack {
                    Image(uiImage: imagen)
                        .resizable()
                        .frame(width: area.width, height: area.height)
                        .position(x: area.midX, y: area.midY)

                    Path { path in
                        path.addRect(area)
                        path.addRect(marco)
                    }
                    .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))

                    Rectangle()
                        .fill(.white.opacity(0.001))
                        .overlay(Rectangle().stroke(.white, lineWidth: 2))
                        .frame(width: marco.width, height: marco.height)
                        .position(x: marco.midX, y: marco.midY)
                        .gesture(gesto(.mover, area: area))

                    esquina(en: CGPoint(x: marco.minX, y: marco.minY)).gesture(gesto(.arribaIzq, area: area))
                    esquina(en: CGPoint(x: marco.maxX, y: marco.minY)).gesture(gesto(.arribaDer, area: area))
                    esquina(en: CGPoint(x: marco.minX, y: marco.maxY)).gesture(gesto(.abajoIzq, area: area))
                    esquina(en: CGPoint(x: marco.maxX, y: marco.maxY)).gesture(gesto(.abajoDer, area: area))
                }
            }

            HStack {
                Button {
                    withAnimation { recorte = CGRect(x: 0, y: 0, width: 1, height: 1) }
                } label: {
                    Label("Restablecer", systemImage: "arrow.counterclockwise")
                }
                Spacer()
                Text("Mueve las esquinas para recortar")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .font(.fiesta(14))
            .foregroundStyle(.white)
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .statusBarHidden()
    }

    // MARK: - Piezas

    private func esquina(en punto: CGPoint) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 22, height: 22)
            .shadow(radius: 2)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .position(punto)
    }

    private func areaImagen(en tamano: CGSize) -> CGRect {
        let margen: CGFloat = 24
        let disponible = CGSize(width: tamano.width - margen * 2, height: tamano.height - margen * 2)
        let factor = min(disponible.width / imagen.size.width, disponible.height / imagen.size.height)
        let ancho = imagen.size.width * factor
        let alto = imagen.size.height * factor
        return CGRect(x: (tamano.width - ancho) / 2, y: (tamano.height - alto) / 2, width: ancho, height: alto)
    }

    private func gesto(_ agarre: Agarre, area: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { valor in
                if recorteInicial == nil { recorteInicial = recorte }
                guard let inicio = recorteInicial else { return }
                let dx = valor.translation.width / area.width
                let dy = valor.translation.height / area.height

                if agarre == .mover {
                    let x = min(max(inicio.minX + dx, 0), 1 - inicio.width)
                    let y = min(max(inicio.minY + dy, 0), 1 - inicio.height)
                    recorte = CGRect(x: x, y: y, width: inicio.width, height: inicio.height)
                    return
                }

                var izq = inicio.minX, der = inicio.maxX
                var arr = inicio.minY, aba = inicio.maxY
                switch agarre {
                case .arribaIzq:
                    izq = min(max(inicio.minX + dx, 0), der - minimo)
                    arr = min(max(inicio.minY + dy, 0), aba - minimo)
                case .arribaDer:
                    der = max(min(inicio.maxX + dx, 1), izq + minimo)
                    arr = min(max(inicio.minY + dy, 0), aba - minimo)
                case .abajoIzq:
                    izq = min(max(inicio.minX + dx, 0), der - minimo)
                    aba = max(min(inicio.maxY + dy, 1), arr + minimo)
                case .abajoDer:
                    der = max(min(inicio.maxX + dx, 1), izq + minimo)
                    aba = max(min(inicio.maxY + dy, 1), arr + minimo)
                case .mover:
                    break
                }
                recorte = CGRect(x: izq, y: arr, width: der - izq, height: aba - arr)
            }
            .onEnded { _ in recorteInicial = nil }
    }

    private func recortar() -> UIImage {
        let x = recorte.minX * imagen.size.width
        let y = recorte.minY * imagen.size.height
        let tamano = CGSize(width: recorte.width * imagen.size.width, height: recorte.height * imagen.size.height)
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            imagen.draw(at: CGPoint(x: -x, y: -y))
        }
    }
}
