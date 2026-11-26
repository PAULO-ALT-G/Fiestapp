//  Navegador.swift
//  Fiestapp

import SwiftUI
import SwiftData

enum Ruta: Hashable {
    case detalle(Evento)
    case editarEvento(Evento?)
    case gasto(Evento, Gasto?)
    case amigos
}

@Observable
final class Navegador {
    var ruta: [Ruta] = []

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
