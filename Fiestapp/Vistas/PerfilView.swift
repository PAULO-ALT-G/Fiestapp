//  PerfilView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct PerfilView: View {
    let perfil: Perfil?

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var dismiss

    @State private var nombre: String
    @State private var foto: Data?

    init(perfil: Perfil?) {
        self.perfil = perfil
        _nombre = State(initialValue: perfil?.nombre ?? "")
        _foto = State(initialValue: perfil?.foto)
    }

    var body: some View {
        ZStack {
            Tema.teal.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Fiestapp")
                        .font(.fiesta(42, .semibold))
                    Text("Cuentas claras, relaciones largas")
                        .font(.fiesta(15))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)

                SelectorFoto(foto: $foto, ajuste: .avatar) {
                    AvatarView(nombre: nombre.isEmpty ? "?" : nombre, foto: foto, tamano: 120)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Tema.teal, .white)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("¿Cómo te llamas?")
                        .font(.fiesta(15, .medium))
                        .foregroundStyle(.white)
                    TextField("Tu nombre", text: $nombre)
                        .font(.fiesta(18))
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Tema.fondo))
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: guardar) {
                    Text(perfil == nil ? "Empezar" : "Guardar")
                        .font(.fiesta(18, .semibold))
                        .foregroundStyle(Tema.teal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.white))
                }
                .disabled(nombre.limpio.isEmpty)
                .opacity(nombre.limpio.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .bajarTecladoAlTocarFuera()
    }

    private func guardar() {
        let nombreFinal = nombre.limpio
        if let perfil {
            let nombreAnterior = perfil.nombre
            perfil.nombre = nombreFinal
            perfil.foto = foto
            let yoEnEventos = ((try? contexto.fetch(FetchDescriptor<Participante>())) ?? [])
                .filter { $0.nombre == nombreAnterior }
            for participante in yoEnEventos {
                participante.nombre = nombreFinal
                participante.foto = foto
            }
        } else {
            contexto.insert(Perfil(nombre: nombreFinal, foto: foto))
        }
        try? contexto.save()
        dismiss()
    }
}

#Preview {
    PerfilView(perfil: nil)
        .modelContainer(DatosEjemplo.contenedor(vacio: true))
}
