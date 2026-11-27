//  BarraFlotante.swift
//  Fiestapp

import SwiftUI

struct BotonBarra: Identifiable {
    let titulo: String
    let icono: String
    var activo: Bool = false
    var deshabilitado: Bool = false
    var destino: Ruta? = nil
    var accion: () -> Void = {}

    var id: String { titulo }
}

struct BarraFlotante: View {
    let botones: [BotonBarra]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(botones) { boton in
                Group {
                    if let destino = boton.destino {
                        NavigationLink(value: destino) {
                            etiqueta(boton)
                        }
                    } else {
                        Button(action: boton.accion) {
                            etiqueta(boton)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(boton.deshabilitado)
                .opacity(boton.deshabilitado ? 0.4 : 1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Tema.teal).shadow(color: .black.opacity(0.2), radius: 8, y: 4))
    }

    private func etiqueta(_ boton: BotonBarra) -> some View {
        VStack(spacing: 2) {
            Image(systemName: boton.icono)
                .font(.system(size: 18, weight: .semibold))
            Text(boton.titulo)
                .font(.fiesta(9, .medium))
        }
        .foregroundStyle(.white)
        .frame(width: 58, height: 46)
        .background {
            Circle()
                .fill(.white.opacity(boton.activo ? 0.28 : 0))
                .frame(width: 52, height: 52)
        }
    }
}

#Preview {
    NavigationStack {
        BarraFlotante(botones: [
            BotonBarra(titulo: "Crear", icono: "plus", destino: .editarEvento(nil)),
            BotonBarra(titulo: "Activos", icono: "checkmark", activo: true),
            BotonBarra(titulo: "Pasados", icono: "clock.arrow.circlepath")
        ])
    }
}
