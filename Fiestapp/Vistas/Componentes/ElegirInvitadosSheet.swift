//  ElegirInvitadosSheet.swift
//  Fiestapp

import SwiftUI

struct ElegirInvitadosSheet: View {
    let alAgregar: ([InvitadoNuevo]) -> Void

    @StateObject private var viewModel: ElegirInvitadosViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: FiestappStore, yaInvitados: [String], alAgregar: @escaping ([InvitadoNuevo]) -> Void) {
        self.alAgregar = alAgregar
        _viewModel = StateObject(wrappedValue: ElegirInvitadosViewModel(store: store, yaInvitados: yaInvitados))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.hayAmigos {
                    Section("Mis amigos") {
                        ForEach(viewModel.filtrados) { amigo in
                            filaAmigo(amigo)
                        }
                    }
                }

                Section {
                    SelectorFoto(foto: $viewModel.nuevaFoto, ajuste: .avatar) {
                        HStack(spacing: 12) {
                            AvatarView(nombre: viewModel.nuevoNombre.isEmpty ? "+" : viewModel.nuevoNombre,
                                       foto: viewModel.nuevaFoto, tamano: 40, borde: Tema.teal)
                            Text(viewModel.nuevaFoto == nil ? "Agregar foto (opcional)" : "Cambiar foto")
                                .foregroundStyle(Tema.tealOscuro)
                        }
                    }
                    TextField("Nombre", text: $viewModel.nuevoNombre)
                        .textInputAutocapitalization(.words)
                    Toggle("Guardar también en mis amigos", isOn: $viewModel.guardarEnAmigos)
                        .tint(Tema.teal)
                } header: {
                    Text("Alguien nuevo")
                } footer: {
                    if !viewModel.hayAmigos {
                        Text("Tip: en la pestaña Amigos del inicio puedes guardar a tus amigos para invitarlos más rápido.")
                    }
                }
            }
            .font(.fiesta(15))
            .scrollContentBackground(.hidden)
            .background(Tema.fondo)
            .searchable(text: $viewModel.busqueda, prompt: "Buscar amigo")
            .navigationTitle("Agregar invitados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.textoBoton) {
                        alAgregar(viewModel.confirmar())
                        dismiss()
                    }
                    .disabled(viewModel.total == 0)
                }
            }
            .bajarTecladoAlTocarFuera()
        }
        .presentationDetents([.large])
    }

    private func filaAmigo(_ amigo: Amigo) -> some View {
        let yaEsta = viewModel.estaInvitado(amigo.nombre)
        let elegido = viewModel.estaElegido(amigo)

        return Button {
            viewModel.alternar(amigo)
        } label: {
            HStack(spacing: 12) {
                AvatarView(nombre: amigo.nombre, foto: amigo.foto, tamano: 40, borde: Tema.teal)
                Text(amigo.nombre)
                    .foregroundStyle(Tema.texto)
                Spacer()
                if yaEsta {
                    Text("Ya invitado")
                        .font(.fiesta(12))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: elegido ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(elegido ? Tema.teal : .secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(yaEsta)
        .opacity(yaEsta ? 0.5 : 1)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ElegirInvitadosSheet(store: DatosEjemplo.store(), yaInvitados: ["Kiara"]) { _ in }
    }
}
