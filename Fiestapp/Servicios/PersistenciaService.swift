//  PersistenciaService.swift
//  Fiestapp

import Foundation

enum ErrorPersistencia: LocalizedError {
    case lectura(String)
    case escritura(String)

    var errorDescription: String? {
        switch self {
        case .lectura(let clave):
            "No se pudieron leer tus datos guardados (\(clave))."
        case .escritura(let clave):
            "No se pudieron guardar tus cambios (\(clave))."
        }
    }
}

final class PersistenciaService {
    enum Clave: String {
        case perfil = "fiestapp.perfil"
        case eventos = "fiestapp.eventos"
        case amigos = "fiestapp.amigos"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func leer<T: Decodable>(_ tipo: T.Type, clave: Clave) throws -> T? {
        guard let datos = defaults.data(forKey: clave.rawValue) else { return nil }
        do {
            return try decoder.decode(tipo, from: datos)
        } catch {
            throw ErrorPersistencia.lectura(clave.rawValue)
        }
    }

    func escribir<T: Encodable>(_ valor: T?, clave: Clave) throws {
        guard let valor else {
            defaults.removeObject(forKey: clave.rawValue)
            return
        }
        do {
            let datos = try encoder.encode(valor)
            defaults.set(datos, forKey: clave.rawValue)
        } catch {
            throw ErrorPersistencia.escritura(clave.rawValue)
        }
    }

    func borrarTodo() {
        for clave in [Clave.perfil, .eventos, .amigos] {
            defaults.removeObject(forKey: clave.rawValue)
        }
    }
}
