//  EventoEditorViewModel.swift
//  Fiestapp

import Foundation
import Combine

struct InvitadoBorrador: Identifiable {
    let id = UUID()
    var nombre: String
    var foto: Data?
    var fotoIDOriginal: String?
    var participanteID: UUID?
    var esOrganizador: Bool
}

final class EventoEditorViewModel: ObservableObject {
    @Published var nombre: String
    @Published var tipo: TipoSalida
    @Published var detalles: String
    @Published var lugar: String
    @Published var latitud: Double?
    @Published var longitud: Double?
    @Published var fecha: Date
    @Published var fechaFin: Date
    @Published var portada: Data?
    @Published var cerrado: Bool
    @Published var invitados: [InvitadoBorrador]

    @Published var agregandoInvitado = false
    @Published var eligiendoOrganizador = false
    @Published var invitadoEditando: InvitadoBorrador?
    @Published var confirmarBorrado = false

    let eventoID: UUID?
    private let store: FiestappStore
    private let portadaIDOriginal: String?

    init(eventoID: UUID?, store: FiestappStore) {
        self.eventoID = eventoID
        self.store = store
        let evento = store.evento(eventoID)

        nombre = evento?.nombre ?? ""
        tipo = evento?.tipo ?? .fiesta
        detalles = evento?.detalles ?? ""
        lugar = evento?.lugar ?? ""
        latitud = evento?.latitud
        longitud = evento?.longitud
        let inicio = evento?.fecha ?? .now
        fecha = inicio
        fechaFin = evento?.fechaFin ?? Formato.finDelDia(inicio)
        portada = evento?.portada
        portadaIDOriginal = evento?.portadaID
        cerrado = evento?.cerrado ?? false

        if let evento {
            invitados = evento.participantesOrdenados.map {
                InvitadoBorrador(nombre: $0.nombre, foto: $0.foto, fotoIDOriginal: $0.fotoID,
                                 participanteID: $0.id, esOrganizador: $0.esOrganizador)
            }
        } else {
            let perfil = store.perfil
            invitados = [
                InvitadoBorrador(nombre: perfil?.nombre ?? "Yo", foto: perfil?.foto,
                                 fotoIDOriginal: perfil?.fotoID, participanteID: nil, esOrganizador: true)
            ]
        }
    }

    // MARK: - Datos para la vista

    var esNuevo: Bool { eventoID == nil }

    var eventoGuardado: Evento? { store.evento(eventoID) }

    var organizador: String {
        invitados.first { $0.esOrganizador }?.nombre ?? store.perfil?.nombre ?? ""
    }

    var nombresInvitados: [String] {
        invitados.map(\.nombre)
    }

    func puedeEliminar(_ invitado: InvitadoBorrador) -> Bool {
        if invitado.esOrganizador { return false }
        if let id = invitado.participanteID, let evento = eventoGuardado,
           Balance.participaEnCuentas(id, evento: evento) {
            return false
        }
        return true
    }

    // MARK: - Fechas

    func inicioCambio(a nuevoInicio: Date) {
        guard fechaFin < nuevoInicio else { return }
        let finDelDia = Formato.finDelDia(nuevoInicio)
        fechaFin = finDelDia > nuevoInicio ? finDelDia : nuevoInicio.addingTimeInterval(3600)
    }

    // MARK: - Invitados

    func agregarInvitados(_ nuevos: [InvitadoNuevo]) {
        for nuevo in nuevos {
            invitados.append(InvitadoBorrador(nombre: nuevo.nombre, foto: FotosService.compartido.cargar(nuevo.fotoID),
                                              fotoIDOriginal: nuevo.fotoID, participanteID: nil, esOrganizador: false))
        }
    }

    func agregarComoOrganizador(_ nuevos: [InvitadoNuevo]) {
        let antes = invitados.count
        agregarInvitados(nuevos)
        if invitados.count > antes {
            hacerOrganizador(invitados[antes])
        }
    }

    func hacerOrganizador(_ elegido: InvitadoBorrador) {
        for i in invitados.indices {
            invitados[i].esOrganizador = (invitados[i].id == elegido.id)
        }
    }

    func actualizar(_ invitado: InvitadoBorrador, nombre: String, foto: Data?) {
        guard let i = invitados.firstIndex(where: { $0.id == invitado.id }) else { return }
        invitados[i].nombre = nombre
        invitados[i].foto = foto
    }

    func eliminar(_ invitado: InvitadoBorrador) {
        invitados.removeAll { $0.id == invitado.id }
    }

    // MARK: - Guardar

    func guardar() -> UUID {
        var evento = eventoGuardado ?? Evento(nombre: "")
        evento.nombre = nombre.limpio.isEmpty ? "Evento" : nombre.limpio
        evento.tipo = tipo
        evento.detalles = detalles.limpio
        evento.lugar = lugar
        evento.latitud = latitud
        evento.longitud = longitud
        evento.fecha = fecha
        evento.fechaFin = max(fechaFin, fecha)
        evento.portadaID = store.actualizarFoto(portada, idActual: portadaIDOriginal)
        evento.cerrado = cerrado

        let anteriores = evento.participantes
        evento.participantes = invitados.map { borrador in
            let anterior = anteriores.first { $0.id == borrador.participanteID }
            var persona = anterior ?? Participante(nombre: borrador.nombre)
            persona.nombre = borrador.nombre
            persona.fotoID = store.actualizarFoto(borrador.foto, idActual: borrador.fotoIDOriginal)
            persona.esOrganizador = borrador.esOrganizador
            return persona
        }

        store.guardar(evento)
        return evento.id
    }

    func eliminarEvento() {
        guard let eventoID else { return }
        store.eliminarEvento(eventoID)
    }
}
