//  InvitadoSheet.swift
//  Fiestapp

import SwiftUI

struct InvitadoSheet: View {
    let titulo: String
    @State var nombre: String
    @State var foto: Data?
    let alGuardar: (String, Data?) -> Void
    var alEliminar: (() -> Void)? = nil
    var textoEliminar: String = "Eliminar invitado"
    var textoCampo: String = "Nombre del invitado"

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        SelectorFoto(foto: $foto, ajuste: .avatar) {
                            AvatarView(nombre: nombre.isEmpty ? "?" : nombre, foto: foto, tamano: 96, borde: Tema.teal)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.white, Tema.teal)
                                }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section("Nombre") {
                    TextField(textoCampo, text: $nombre)
                        .textInputAutocapitalization(.words)
                }

                if let alEliminar {
                    Section {
                        Button(textoEliminar, role: .destructive) {
                            alEliminar()
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Tema.fondo)
            .navigationTitle(titulo)
            .navigationBarTitleDisplayMode(.inline)
            .bajarTecladoAlTocarFuera()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        alGuardar(nombre.limpio, foto)
                        dismiss()
                    }
                    .disabled(nombre.limpio.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        InvitadoSheet(titulo: "Nuevo invitado", nombre: "", foto: nil) { _, _ in }
    }
}
