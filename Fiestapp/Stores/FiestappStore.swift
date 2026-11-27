//  FiestappStore.swift
//  Fiestapp

import Foundation
import Combine

enum EstadoCarga: Equatable {
    case cargando
    case listo
    case error(String)
}

final class FiestappStore: ObservableObject {
    @Published private(set) var estado: EstadoCarga = .cargando
    @Published private(set) var perfil: Perfil?
    @Published private(set) var eventos: [Evento] = []
    @Published private(set) var amigos: [Amigo] = []
    @Published var errorGuardado: String?

    private let persistencia: PersistenciaService
    private let fotos: FotosService
    private let guardaCambios: Bool

    init(persistencia: PersistenciaService = PersistenciaService(),
         fotos: FotosService = .compartido,
         guardaCambios: Bool = true) {
        self.persistencia = persistencia
        self.fotos = fotos
        self.guardaCambios = guardaCambios
    }

    // MARK: - Carga

    func cargar() {
        estado = .cargando
        do {
            perfil = try persistencia.leer(Perfil.self, clave: .perfil)
            eventos = try persistencia.leer([Evento].self, clave: .eventos) ?? []
            amigos = try persistencia.leer([Amigo].self, clave: .amigos) ?? []
            estado = .listo
            limpiarFotos()
        } catch {
            estado = .error(error.localizedDescription)
        }
    }

    func empezarDeCero() {
        persistencia.borrarTodo()
        perfil = nil
        eventos = []
        amigos = []
        estado = .listo
        limpiarFotos()
    }

    func usarDatos(perfil: Perfil?, eventos: [Evento], amigos: [Amigo]) {
        self.perfil = perfil
        self.eventos = eventos
        self.amigos = amigos
        estado = .listo
    }

    // MARK: - Perfil

    func guardarPerfil(nombre: String, fotoID: String?) {
        let nombreAnterior = perfil?.nombre
        perfil = Perfil(nombre: nombre, fotoID: fotoID)
        if let nombreAnterior {
            for i in eventos.indices {
                for j in eventos[i].participantes.indices where eventos[i].participantes[j].nombre == nombreAnterior {
                    eventos[i].participantes[j].nombre = nombre
                    eventos[i].participantes[j].fotoID = fotoID
                }
            }
        }
        persistir()
    }

    // MARK: - Eventos

    func evento(_ id: UUID?) -> Evento? {
        guard let id else { return nil }
        return eventos.first { $0.id == id }
    }

    func guardar(_ evento: Evento) {
        if let indice = eventos.firstIndex(where: { $0.id == evento.id }) {
            eventos[indice] = evento
        } else {
            eventos.append(evento)
        }
        persistir()
    }

    func modificarEvento(_ id: UUID, _ cambio: (inout Evento) -> Void) {
        guard let indice = eventos.firstIndex(where: { $0.id == id }) else { return }
        cambio(&eventos[indice])
        persistir()
    }

    func eliminarEvento(_ id: UUID) {
        eventos.removeAll { $0.id == id }
        persistir()
    }

    // MARK: - Amigos

    var amigosOrdenados: [Amigo] {
        amigos.sorted { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending }
    }

    func guardar(_ amigo: Amigo) {
        if let indice = amigos.firstIndex(where: { $0.id == amigo.id }) {
            amigos[indice] = amigo
        } else {
            amigos.append(amigo)
        }
        persistir()
    }

    func eliminarAmigo(_ id: UUID) {
        amigos.removeAll { $0.id == id }
        persistir()
    }

    func esAmigo(_ nombre: String) -> Bool {
        let buscado = nombre.limpio.lowercased()
        return amigos.contains { $0.nombre.limpio.lowercased() == buscado }
    }

    // MARK: - Fotos

    func guardarFoto(_ datos: Data?) -> String? {
        fotos.guardar(datos)
    }

    func actualizarFoto(_ datos: Data?, idActual: String?) -> String? {
        fotos.actualizar(datos, idActual: idActual)
    }

    private func limpiarFotos() {
        guard guardaCambios else { return }
        var enUso = Set<String>()
        if let fotoID = perfil?.fotoID { enUso.insert(fotoID) }
        amigos.compactMap(\.fotoID).forEach { enUso.insert($0) }
        eventos.flatMap(\.idsDeFotos).forEach { enUso.insert($0) }
        fotos.borrarNoUsadas(conservar: enUso)
    }

    // MARK: - Guardado

    private func persistir() {
        guard guardaCambios else { return }
        do {
            try persistencia.escribir(perfil, clave: .perfil)
            try persistencia.escribir(eventos, clave: .eventos)
            try persistencia.escribir(amigos, clave: .amigos)
        } catch {
            errorGuardado = error.localizedDescription
        }
    }
}
