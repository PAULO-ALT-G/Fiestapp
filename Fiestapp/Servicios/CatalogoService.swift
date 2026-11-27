//  CatalogoService.swift
//  Fiestapp

import Foundation

enum ErrorCatalogo: LocalizedError {
    case noEncontrado
    case formatoInvalido

    var errorDescription: String? {
        switch self {
        case .noEncontrado: "No se encontró el catálogo de sugerencias."
        case .formatoInvalido: "El catálogo de sugerencias tiene un formato inválido."
        }
    }
}

final class CatalogoService {
    private let nombreArchivo: String
    private var enMemoria: Catalogo?

    init(nombreArchivo: String = "catalogo") {
        self.nombreArchivo = nombreArchivo
    }

    func cargar() async throws -> Catalogo {
        if let enMemoria { return enMemoria }
        guard let url = Bundle.main.url(forResource: nombreArchivo, withExtension: "json") else {
            throw ErrorCatalogo.noEncontrado
        }
        let datos: Data
        do {
            datos = try Data(contentsOf: url)
        } catch {
            throw ErrorCatalogo.noEncontrado
        }
        do {
            let catalogo = try JSONDecoder().decode(Catalogo.self, from: datos)
            enMemoria = catalogo
            return catalogo
        } catch {
            throw ErrorCatalogo.formatoInvalido
        }
    }
}
