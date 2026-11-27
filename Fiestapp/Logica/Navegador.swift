//  Navegador.swift
//  Fiestapp

import Foundation
import Combine

enum Ruta: Hashable {
    case detalle(UUID)
    case editarEvento(UUID?)
    case gasto(evento: UUID, gasto: UUID?)
    case amigos
}

final class Navegador: ObservableObject {
    @Published var ruta: [Ruta] = []

    func ir(_ destino: Ruta) {
        ruta.append(destino)
    }

    func atras() {
        if !ruta.isEmpty { ruta.removeLast() }
    }

    func inicio() {
        ruta.removeAll()
    }

    func reemplazar(con destino: Ruta) {
        if !ruta.isEmpty { ruta.removeLast() }
        ruta.append(destino)
    }
}
