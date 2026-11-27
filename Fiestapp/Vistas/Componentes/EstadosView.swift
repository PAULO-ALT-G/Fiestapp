//  EstadosView.swift
//  Fiestapp

import SwiftUI

struct CargandoView: View {
    let mensaje: String

    var body: some View {
        ZStack {
            Tema.teal.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                VStack(spacing: 6) {
                    Text("Fiestapp")
                        .font(.fiesta(42, .semibold))
                    Text("Cuentas claras, relaciones largas")
                        .font(.fiesta(15))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text(mensaje)
                        .font(.fiesta(15, .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.bottom, 60)
            }
        }
    }
}

struct ErrorDatosView: View {
    let mensaje: String
    let reintentar: () -> Void
    let empezarDeCero: () -> Void

    @State private var confirmarBorrado = false

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()
            ContentUnavailableView {
                Label("No pudimos abrir tus datos", systemImage: "exclamationmark.triangle")
            } description: {
                Text(mensaje)
            } actions: {
                Button("Reintentar", action: reintentar)
                    .buttonStyle(.borderedProminent)
                Button("Empezar de cero", role: .destructive) { confirmarBorrado = true }
            }
            .foregroundStyle(Tema.texto)
        }
        .confirmationDialog("¿Borrar todos los datos guardados?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Borrar y empezar de cero", role: .destructive, action: empezarDeCero)
        } message: {
            Text("Se borran tus eventos, amigos y perfil. No se puede deshacer.")
        }
    }
}

struct SugerenciasView: View {
    let estado: EstadoSugerencias
    let elegir: (String) -> Void
    let reintentar: () -> Void

    var body: some View {
        switch estado {
        case .cargando:
            HStack(spacing: 8) {
                ProgressView()
                Text("Cargando sugerencias…")
                    .font(.fiesta(13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
        case .listo(let conceptos):
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(conceptos, id: \.self) { concepto in
                        Button(concepto) { elegir(concepto) }
                            .font(.fiesta(13, .medium))
                            .foregroundStyle(Tema.tealOscuro)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().stroke(Tema.teal, lineWidth: 1.5))
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        case .error(let mensaje):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.orange)
                Text(mensaje)
                    .font(.fiesta(12))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reintentar", action: reintentar)
                    .font(.fiesta(12, .semibold))
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Cargando") {
    CargandoView(mensaje: "Cargando tus eventos…")
}

#Preview("Error") {
    ErrorDatosView(mensaje: "No se pudieron leer tus datos guardados.", reintentar: {}, empezarDeCero: {})
}
