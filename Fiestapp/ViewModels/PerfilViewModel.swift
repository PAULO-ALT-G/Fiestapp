//  PerfilViewModel.swift
//  Fiestapp

import Foundation
import Combine

final class PerfilViewModel: ObservableObject {
    @Published var nombre: String
    @Published var foto: Data?

    let esPrimeraVez: Bool
    private let store: FiestappStore
    private let fotoIDOriginal: String?

    init(store: FiestappStore) {
        self.store = store
        self.esPrimeraVez = store.perfil == nil
        self.nombre = store.perfil?.nombre ?? ""
        self.foto = store.perfil?.foto
        self.fotoIDOriginal = store.perfil?.fotoID
    }

    var puedeGuardar: Bool {
        !nombre.limpio.isEmpty
    }

    var textoBoton: String {
        esPrimeraVez ? "Empezar" : "Guardar"
    }

    func guardar() {
        guard puedeGuardar else { return }
        let fotoID = store.actualizarFoto(foto, idActual: fotoIDOriginal)
        store.guardarPerfil(nombre: nombre.limpio, fotoID: fotoID)
    }
}
