//  ElegirInvitadosViewModel.swift
//  Fiestapp

import Foundation
import Combine

struct InvitadoNuevo {
    let nombre: String
    let fotoID: String?
}

final class ElegirInvitadosViewModel: ObservableObject {
    @Published var seleccionados: Set<UUID> = []
    @Published var busqueda = ""
    @Published var nuevoNombre = ""
    @Published var nuevaFoto: Data?
    @Published var guardarEnAmigos = true

    private let store: FiestappStore
    private let yaInvitados: [String]

    init(store: FiestappStore, yaInvitados: [String]) {
        self.store = store
        self.yaInvitados = yaInvitados
    }

    var hayAmigos: Bool { !store.amigos.isEmpty }

    var filtrados: [Amigo] {
        let texto = busqueda.limpio
        let amigos = store.amigosOrdenados
        guard !texto.isEmpty else { return amigos }
        return amigos.filter { $0.nombre.localizedCaseInsensitiveContains(texto) }
    }

    var total: Int {
        seleccionados.count + (nuevoNombre.limpio.isEmpty ? 0 : 1)
    }

    var textoBoton: String {
        total > 0 ? "Agregar (\(total))" : "Agregar"
    }

    func estaInvitado(_ nombre: String) -> Bool {
        let buscado = nombre.limpio.lowercased()
        return yaInvitados.contains { $0.limpio.lowercased() == buscado }
    }

    func estaElegido(_ amigo: Amigo) -> Bool {
        seleccionados.contains(amigo.id)
    }

    func alternar(_ amigo: Amigo) {
        if seleccionados.contains(amigo.id) {
            seleccionados.remove(amigo.id)
        } else {
            seleccionados.insert(amigo.id)
        }
    }

    func confirmar() -> [InvitadoNuevo] {
        var lista = store.amigosOrdenados
            .filter { seleccionados.contains($0.id) }
            .map { InvitadoNuevo(nombre: $0.nombre, fotoID: $0.fotoID) }

        let nombre = nuevoNombre.limpio
        if !nombre.isEmpty && !estaInvitado(nombre) {
            let fotoID = store.guardarFoto(nuevaFoto)
            lista.append(InvitadoNuevo(nombre: nombre, fotoID: fotoID))
            if guardarEnAmigos && !store.esAmigo(nombre) {
                store.guardar(Amigo(nombre: nombre, fotoID: fotoID))
            }
        }
        return lista
    }
}
