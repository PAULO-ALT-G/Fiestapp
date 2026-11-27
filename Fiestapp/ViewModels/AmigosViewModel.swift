//  AmigosViewModel.swift
//  Fiestapp

import Foundation
import Combine

final class AmigosViewModel: ObservableObject {
    @Published var busqueda = ""
    @Published var agregando = false
    @Published var editando: Amigo?

    private let store: FiestappStore

    init(store: FiestappStore) {
        self.store = store
    }

    var amigos: [Amigo] {
        store.amigosOrdenados
    }

    var filtrados: [Amigo] {
        let texto = busqueda.limpio
        guard !texto.isEmpty else { return amigos }
        return amigos.filter { $0.nombre.localizedCaseInsensitiveContains(texto) }
    }

    var contador: String {
        amigos.count == 1 ? "1 amigo" : "\(amigos.count) amigos"
    }

    func agregar(nombre: String, foto: Data?) {
        store.guardar(Amigo(nombre: nombre, fotoID: store.guardarFoto(foto)))
    }

    func actualizar(_ amigo: Amigo, nombre: String, foto: Data?) {
        var cambiado = amigo
        cambiado.nombre = nombre
        cambiado.fotoID = store.actualizarFoto(foto, idActual: amigo.fotoID)
        store.guardar(cambiado)
    }

    func eliminar(_ amigo: Amigo) {
        store.eliminarAmigo(amigo.id)
    }
}
