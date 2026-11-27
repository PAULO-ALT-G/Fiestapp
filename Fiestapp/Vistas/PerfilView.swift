//  PerfilView.swift
//  Fiestapp

import SwiftUI

struct PerfilView: View {
    @StateObject private var viewModel: PerfilViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: FiestappStore) {
        _viewModel = StateObject(wrappedValue: PerfilViewModel(store: store))
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

                SelectorFoto(foto: $viewModel.foto, ajuste: .avatar) {
                    AvatarView(nombre: viewModel.nombre.isEmpty ? "?" : viewModel.nombre, foto: viewModel.foto, tamano: 120)
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
                    TextField("Tu nombre", text: $viewModel.nombre)
                        .font(.fiesta(18))
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Tema.fondo))
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    viewModel.guardar()
                    dismiss()
                } label: {
                    Text(viewModel.textoBoton)
                        .font(.fiesta(18, .semibold))
                        .foregroundStyle(Tema.teal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.white))
                }
                .disabled(!viewModel.puedeGuardar)
                .opacity(viewModel.puedeGuardar ? 1 : 0.5)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .bajarTecladoAlTocarFuera()
    }
}

#Preview {
    PerfilView(store: DatosEjemplo.store(vacio: true, sinPerfil: true))
}
