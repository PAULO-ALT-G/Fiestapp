//  GastoEditorViewModel.swift
//  Fiestapp

import Foundation
import Combine

final class GastoEditorViewModel: ObservableObject {
    @Published var concepto: String
    @Published var montoTexto: String
    @Published var fecha: Date
    @Published var fechaLimite: Date
    @Published var division: TipoDivision
    @Published var seleccionados: Set<UUID>
    @Published var montosPersonalizados: [UUID: String]
    @Published var pagadorID: UUID?
    @Published var foto: Data?

    @Published var sugerencias: EstadoSugerencias = .cargando
    @Published var alerta: String?
    @Published var agregandoInvitado = false
    @Published var confirmarBorrado = false
    @Published var verFotoCompleta = false

    let eventoID: UUID
    let gastoID: UUID?
    private let store: FiestappStore
    private let catalogo: CatalogoService
    private let fotoIDOriginal: String?

    init(eventoID: UUID, gastoID: UUID?, store: FiestappStore, catalogo: CatalogoService = CatalogoService()) {
        self.eventoID = eventoID
        self.gastoID = gastoID
        self.store = store
        self.catalogo = catalogo

        let evento = store.evento(eventoID)
        let gasto = evento?.gastos.first { $0.id == gastoID }

        concepto = gasto?.concepto ?? ""
        montoTexto = gasto.map { Dinero.textoEditable($0.montoCentavos) } ?? ""
        fecha = gasto?.fecha ?? .now
        fechaLimite = gasto?.fechaLimite ?? max(evento?.fecha ?? .now, .now)
        division = gasto?.division ?? .iguales
        foto = gasto?.fotoTicket
        fotoIDOriginal = gasto?.fotoTicketID
        pagadorID = gasto?.pagadorID ?? evento?.organizador?.id

        if let gasto {
            seleccionados = Set(gasto.partes.map(\.participanteID))
            var montos: [UUID: String] = [:]
            for parte in gasto.partes {
                montos[parte.participanteID] = Dinero.textoEditable(parte.montoCentavos)
            }
            montosPersonalizados = montos
        } else {
            seleccionados = Set(evento?.participantes.map(\.id) ?? [])
            montosPersonalizados = [:]
        }
    }

    // MARK: - Datos para la vista

    var evento: Evento? { store.evento(eventoID) }

    var esNuevo: Bool { gastoID == nil }

    var cerrado: Bool { evento?.cerrado ?? true }

    var personas: [Participante] { evento?.participantesOrdenados ?? [] }

    var elegidos: [Participante] {
        personas.filter { seleccionados.contains($0.id) }
    }

    var totalCentavos: Int { Dinero.centavos(de: montoTexto) ?? 0 }

    var sumaPersonalizada: Int {
        elegidos.reduce(0) { $0 + (Dinero.centavos(de: montosPersonalizados[$1.id] ?? "") ?? 0) }
    }

    var restantePersonalizado: Int { totalCentavos - sumaPersonalizada }

    var textoPorPersona: String? {
        guard !elegidos.isEmpty, totalCentavos > 0 else { return nil }
        return "A cada quien le tocan aprox. \(Dinero.texto(totalCentavos / elegidos.count))"
    }

    // MARK: - Sugerencias (JSON local)

    func cargarSugerencias() async {
        sugerencias = .cargando
        do {
            let datos = try await catalogo.cargar()
            sugerencias = .listo(datos.conceptos(para: evento?.tipo ?? .otro))
        } catch {
            sugerencias = .error(error.localizedDescription)
        }
    }

    func usarSugerencia(_ texto: String) {
        concepto = texto
    }

    // MARK: - Selección

    func alternar(_ persona: Participante) {
        if seleccionados.contains(persona.id) {
            seleccionados.remove(persona.id)
        } else {
            seleccionados.insert(persona.id)
        }
    }

    func agregarInvitados(_ nuevos: [InvitadoNuevo]) {
        var agregados: [UUID] = []
        store.modificarEvento(eventoID) { evento in
            for nuevo in nuevos {
                let persona = Participante(nombre: nuevo.nombre, fotoID: nuevo.fotoID)
                evento.participantes.append(persona)
                agregados.append(persona.id)
            }
        }
        seleccionados.formUnion(agregados)
    }

    // MARK: - Guardar

    func guardar() -> Bool {
        let conceptoFinal = concepto.limpio
        guard !conceptoFinal.isEmpty else { alerta = "Escribe el concepto del gasto."; return false }
        guard let total = Dinero.centavos(de: montoTexto), total > 0 else { alerta = "Escribe un monto válido."; return false }
        guard !elegidos.isEmpty else { alerta = "Elige al menos a una persona para dividir."; return false }
        guard let pagadorID, personas.contains(where: { $0.id == pagadorID }) else { alerta = "Elige quién pagó."; return false }

        let anterior = evento?.gastos.first { $0.id == gastoID }
        let montos: [Int]
        switch division {
        case .iguales:
            let idsElegidos = Set(elegidos.map(\.id))
            let idsAnteriores = Set(anterior?.partes.map(\.participanteID) ?? [])
            if let anterior, anterior.division == .iguales, anterior.montoCentavos == total, idsAnteriores == idsElegidos {
                montos = elegidos.map { persona in
                    anterior.partes.first { $0.participanteID == persona.id }?.montoCentavos ?? 0
                }
            } else {
                montos = Balance.dividirIguales(totalCentavos: total, entre: elegidos.count)
            }
        case .personalizada:
            montos = elegidos.map { Dinero.centavos(de: montosPersonalizados[$0.id] ?? "") ?? 0 }
            let suma = montos.reduce(0, +)
            guard suma == total else {
                alerta = "Los montos suman \(Dinero.texto(suma)) pero el gasto es de \(Dinero.texto(total))."
                return false
            }
        }

        let yaPagaron = Set(anterior?.partes.filter(\.saldada).map(\.participanteID) ?? [])
        var gasto = anterior ?? Gasto(concepto: conceptoFinal, montoCentavos: total)
        gasto.concepto = conceptoFinal
        gasto.montoCentavos = total
        gasto.fecha = fecha
        gasto.fechaLimite = fechaLimite
        gasto.division = division
        gasto.pagadorID = pagadorID
        gasto.fotoTicketID = store.actualizarFoto(foto, idActual: fotoIDOriginal)
        gasto.partes = zip(elegidos, montos).map { persona, monto in
            Parte(participanteID: persona.id, montoCentavos: monto, saldada: yaPagaron.contains(persona.id))
        }

        let gastoFinal = gasto
        store.modificarEvento(eventoID) { evento in
            if let i = evento.gastos.firstIndex(where: { $0.id == gastoFinal.id }) {
                evento.gastos[i] = gastoFinal
            } else {
                evento.gastos.append(gastoFinal)
            }
        }
        return true
    }

    func eliminar() {
        guard let gastoID else { return }
        store.modificarEvento(eventoID) { evento in
            evento.gastos.removeAll { $0.id == gastoID }
        }
    }
}
