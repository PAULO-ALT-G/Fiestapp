//  Catalogo.swift
//  Fiestapp

import Foundation

struct Catalogo: Decodable, Sendable {
    let tipos: [InfoTipoSalida]

    func conceptos(para tipo: TipoSalida) -> [String] {
        tipos.first { $0.tipo == tipo }?.conceptos ?? []
    }
}

struct InfoTipoSalida: Identifiable, Decodable, Sendable {
    let tipo: TipoSalida
    let descripcion: String
    let conceptos: [String]

    var id: String { tipo.rawValue }
}

enum EstadoSugerencias: Equatable {
    case cargando
    case listo([String])
    case error(String)
}
