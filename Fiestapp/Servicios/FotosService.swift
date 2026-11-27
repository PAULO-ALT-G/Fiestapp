//  FotosService.swift
//  Fiestapp

import Foundation

final class FotosService {
    static let compartido = FotosService()

    private let carpeta: URL
    private let cache = NSCache<NSString, NSData>()

    init(carpeta: URL? = nil) {
        let documentos = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.carpeta = carpeta ?? documentos.appendingPathComponent("Fotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.carpeta, withIntermediateDirectories: true)
    }

    func guardar(_ datos: Data?) -> String? {
        guard let datos else { return nil }
        let id = UUID().uuidString
        do {
            try datos.write(to: url(id), options: .atomic)
            cache.setObject(datos as NSData, forKey: id as NSString)
            return id
        } catch {
            return nil
        }
    }

    func cargar(_ id: String?) -> Data? {
        guard let id else { return nil }
        if let enCache = cache.object(forKey: id as NSString) {
            return enCache as Data
        }
        guard let datos = try? Data(contentsOf: url(id)) else { return nil }
        cache.setObject(datos as NSData, forKey: id as NSString)
        return datos
    }

    func actualizar(_ datos: Data?, idActual: String?) -> String? {
        guard let datos else { return nil }
        if let idActual, cargar(idActual) == datos {
            return idActual
        }
        return guardar(datos)
    }

    func borrarNoUsadas(conservar ids: Set<String>) {
        guard let archivos = try? FileManager.default.contentsOfDirectory(atPath: carpeta.path) else { return }
        for archivo in archivos {
            let id = (archivo as NSString).deletingPathExtension
            if !ids.contains(id) {
                try? FileManager.default.removeItem(at: carpeta.appendingPathComponent(archivo))
                cache.removeObject(forKey: id as NSString)
            }
        }
    }

    private func url(_ id: String) -> URL {
        carpeta.appendingPathComponent("\(id).jpg")
    }
}

// MARK: - Fotos de los modelos

extension Perfil {
    var foto: Data? { FotosService.compartido.cargar(fotoID) }
}

extension Amigo {
    var foto: Data? { FotosService.compartido.cargar(fotoID) }
}

extension Participante {
    var foto: Data? { FotosService.compartido.cargar(fotoID) }
}

extension Gasto {
    var fotoTicket: Data? { FotosService.compartido.cargar(fotoTicketID) }
}

extension Evento {
    var portada: Data? { FotosService.compartido.cargar(portadaID) }

    var idsDeFotos: [String] {
        var ids: [String] = []
        if let portadaID { ids.append(portadaID) }
        ids += participantes.compactMap(\.fotoID)
        ids += gastos.compactMap(\.fotoTicketID)
        return ids
    }
}
