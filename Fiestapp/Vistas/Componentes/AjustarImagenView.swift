//  AjustarImagenView.swift
//  Fiestapp

import SwiftUI
import UIKit

struct AjusteImagen {
    let proporcion: CGFloat
    let circular: Bool
    var libre: Bool = false

    static let avatar = AjusteImagen(proporcion: 1, circular: true)
    static let portada = AjusteImagen(proporcion: 3.0 / 2.0, circular: false)
    static let libre = AjusteImagen(proporcion: 1, circular: false, libre: true)
}

struct ImagenPorAjustar: Identifiable {
    let id = UUID()
    let imagen: UIImage
}

struct AjustarImagenView: View {
    let imagen: UIImage
    let ajuste: AjusteImagen
    let alTerminar: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var escala: CGFloat = 1
    @State private var escalaBase: CGFloat = 1
    @State private var desplazamiento: CGSize = .zero
    @State private var desplazamientoBase: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let marco = tamanoMarco(en: geo.size)
            let base = tamanoBase(para: marco)

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: imagen)
                    .resizable()
                    .frame(width: base.width * escala, height: base.height * escala)
                    .offset(desplazamiento)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    let rect = CGRect(x: (geo.size.width - marco.width) / 2,
                                      y: (geo.size.height - marco.height) / 2,
                                      width: marco.width, height: marco.height)
                    if ajuste.circular {
                        path.addEllipse(in: rect)
                    } else {
                        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 12, height: 12))
                    }
                }
                .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)

                Group {
                    if ajuste.circular {
                        Circle().stroke(.white, lineWidth: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 2)
                    }
                }
                .frame(width: marco.width, height: marco.height)
                .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button("Cancelar") { dismiss() }
                        Spacer()
                        Text("Ajustar foto").fontWeight(.semibold)
                        Spacer()
                        Button("Usar") {
                            alTerminar(recortar(marco: marco, base: base))
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.fiesta(17))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    Text("Arrastra para mover · Pellizca para hacer zoom")
                        .font(.fiesta(13))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 24)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { valor in
                        let nuevo = CGSize(width: desplazamientoBase.width + valor.translation.width,
                                           height: desplazamientoBase.height + valor.translation.height)
                        desplazamiento = limitar(nuevo, marco: marco, base: base, escala: escala)
                    }
                    .onEnded { _ in desplazamientoBase = desplazamiento }
                    .simultaneously(with:
                        MagnifyGesture()
                            .onChanged { valor in
                                escala = min(max(escalaBase * valor.magnification, 1), 5)
                                desplazamiento = limitar(desplazamiento, marco: marco, base: base, escala: escala)
                            }
                            .onEnded { _ in
                                escalaBase = escala
                                desplazamientoBase = desplazamiento
                            }
                    )
            )
        }
        .statusBarHidden()
    }

    // MARK: - Cálculos

    private func tamanoMarco(en pantalla: CGSize) -> CGSize {
        let ancho = min(pantalla.width - 40, (pantalla.height - 200) * ajuste.proporcion)
        return CGSize(width: ancho, height: ancho / ajuste.proporcion)
    }

    private func tamanoBase(para marco: CGSize) -> CGSize {
        let factor = max(marco.width / imagen.size.width, marco.height / imagen.size.height)
        return CGSize(width: imagen.size.width * factor, height: imagen.size.height * factor)
    }

    private func limitar(_ offset: CGSize, marco: CGSize, base: CGSize, escala: CGFloat) -> CGSize {
        let maxX = max(0, (base.width * escala - marco.width) / 2)
        let maxY = max(0, (base.height * escala - marco.height) / 2)
        return CGSize(width: min(max(offset.width, -maxX), maxX),
                      height: min(max(offset.height, -maxY), maxY))
    }

    private func recortar(marco: CGSize, base: CGSize) -> UIImage {
        let mostrada = CGSize(width: base.width * escala, height: base.height * escala)
        let pixelesPorPunto = imagen.size.width / mostrada.width

        let x = ((mostrada.width - marco.width) / 2 - desplazamiento.width) * pixelesPorPunto
        let y = ((mostrada.height - marco.height) / 2 - desplazamiento.height) * pixelesPorPunto
        let tamano = CGSize(width: marco.width * pixelesPorPunto, height: marco.height * pixelesPorPunto)

        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            imagen.draw(at: CGPoint(x: -x, y: -y))
        }
    }
}
