//  ElegirInvitadosSheet.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct InvitadoNuevo {
    let nombre: String
    let foto: Data?
}

struct ElegirInvitadosSheet: View {
    let yaInvitados: [String]
    let alAgregar: ([InvitadoNuevo]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var contexto

    @Query(sort: \Amigo.nombre) private var amigos: [Amigo]

    @State private var seleccionados: Set<PersistentIdentifier> = []
    @State private var busqueda = ""
    @State private var nuevoNombre = ""
    @State private var nuevaFoto: Data?
    @State private var guardarEnAmigos = true

    private var filtrados: [Amigo] {
        let texto = busqueda.limpio
        guard !texto.isEmpty else { return amigos }
        return amigos.filter { $0.nombre.localizedCaseInsensitiveContains(texto) }
    }

    private var total: Int {
        seleccionados.count + (nuevoNombre.limpio.isEmpty ? 0 : 1)
    }

    var body: some View {
        NavigationStack {
            List {
                if !amigos.isEmpty {
                    Section("Mis amigos") {
                        ForEach(filtrados) { amigo in
                            filaAmigo(amigo)
                        }
                    }
                }

                Section {
                    SelectorFoto(foto: $nuevaFoto, ajuste: .avatar) {
                        HStack(spacing: 12) {
                            AvatarView(nombre: nuevoNombre.isEmpty ? "+" : nuevoNombre, foto: nuevaFoto,
                                       tamano: 40, borde: Tema.teal)
                            Text(nuevaFoto == nil ? "Agregar foto (opcional)" : "Cambiar foto")
                                .foregroundStyle(Tema.tealOscuro)
                        }
                    }
                    TextField("Nombre", text: $nuevoNombre)
                        .textInputAutocapitalization(.words)
                    Toggle("Guardar también en mis amigos", isOn: $guardarEnAmigos)
                        .tint(Tema.teal)
                } header: {
                    Text("Alguien nuevo")
                } footer: {
                    if amigos.isEmpty {
                        Text("Tip: en la pestaña Amigos del inicio puedes guardar a tus amigos para invitarlos más rápido.")
                    }
                }
            }
            .font(.fiesta(15))
            .scrollContentBackground(.hidden)
            .background(Tema.fondo)
            .searchable(text: $busqueda, prompt: "Buscar amigo")
            .navigationTitle("Agregar invitados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(total > 0 ? "Agregar (\(total))" : "Agregar") { agregar() }
                        .disabled(total == 0)
                }
            }
            .bajarTecladoAlTocarFuera()
        }
        .presentationDetents([.large])
    }

    private func filaAmigo(_ amigo: Amigo) -> some View {
        let yaEsta = estaInvitado(amigo.nombre)
        let elegido = seleccionados.contains(amigo.persistentModelID)

        return Button {
            if elegido { seleccionados.remove(amigo.persistentModelID) }
            else { seleccionados.insert(amigo.persistentModelID) }
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

    private func estaInvitado(_ nombre: String) -> Bool {
        let buscado = nombre.limpio.lowercased()
        return yaInvitados.contains { $0.limpio.lowercased() == buscado }
    }

    private func agregar() {
        var lista = amigos
            .filter { seleccionados.contains($0.persistentModelID) }
            .map { InvitadoNuevo(nombre: $0.nombre, foto: $0.foto) }

        let nombre = nuevoNombre.limpio
        if !nombre.isEmpty && !estaInvitado(nombre) {
            lista.append(InvitadoNuevo(nombre: nombre, foto: nuevaFoto))
            let yaEsAmigo = amigos.contains { $0.nombre.limpio.lowercased() == nombre.lowercased() }
            if guardarEnAmigos && !yaEsAmigo {
                contexto.insert(Amigo(nombre: nombre, foto: nuevaFoto))
                try? contexto.save()
            }
        }

        alAgregar(lista)
        dismiss()
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ElegirInvitadosSheet(yaInvitados: ["Kiara"]) { _ in }
    }
    .modelContainer(DatosEjemplo.contenedor())
}
