//  PantallaFiesta.swift
//  Fiestapp

import SwiftUI

struct PantallaFiesta<Encabezado: View, Contenido: View>: View {
    var imagen: Data? = nil
    let barra: [BotonBarra]
    @ViewBuilder let encabezado: () -> Encabezado
    @ViewBuilder let contenido: () -> Contenido

    var body: some View {
        ZStack(alignment: .bottom) {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    encabezado()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 44)
                        .background { FondoEncabezado(imagen: imagen) }

                    contenido()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                        .padding(.bottom, 110)
                        .background(Tema.fondo)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
                        .padding(.top, -26)
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(alignment: .top) {
                Tema.teal.frame(height: 420).ignoresSafeArea()
            }

            BarraFlotante(botones: barra)
                .padding(.bottom, 6)
        }
        .toolbar(.hidden, for: .navigationBar)
        .bajarTecladoAlTocarFuera()
    }
}

struct FondoEncabezado: View {
    let imagen: Data?

    var body: some View {
        ZStack {
            Tema.teal
            if let imagen, let ui = UIImage(data: imagen) {
                Color.clear
                    .overlay {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                LinearGradient(
                    colors: [.black.opacity(0.55), .black.opacity(0.25), .black.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
    }
}

struct LineaSeccion: View {
    var body: some View {
        Rectangle().fill(Tema.teal).frame(height: 2)
    }
}

struct EncabezadoSeccion: View {
    let titulo: String

    init(_ titulo: String) { self.titulo = titulo }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LineaSeccion()
            Text(titulo)
                .font(.fiesta(17, .medium))
                .foregroundStyle(Tema.texto)
                .padding(.horizontal, 20)
        }
    }
}

struct SeccionDesplegable<Contenido: View>: View {
    let titulo: String
    @State private var abierta: Bool
    @ViewBuilder let contenido: () -> Contenido

    init(_ titulo: String, abierta: Bool = true, @ViewBuilder contenido: @escaping () -> Contenido) {
        self.titulo = titulo
        self._abierta = State(initialValue: abierta)
        self.contenido = contenido
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) { abierta.toggle() }
            } label: {
                HStack {
                    Text(titulo).font(.fiesta(15, .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(abierta ? 90 : 0))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Tema.teal)
            }
            .buttonStyle(.plain)

            if abierta {
                VStack(alignment: .leading, spacing: 10) {
                    contenido()
                }
                .font(.fiesta(14))
                .foregroundStyle(Tema.texto)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Tema.tarjeta)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Tema.teal, lineWidth: 1.5))
        .padding(.horizontal, 16)
    }
}
