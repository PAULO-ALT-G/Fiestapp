//  EventoDetalleViewModel.swift
//  Fiestapp

import Foundation
import Combine

final class EventoDetalleViewModel: ObservableObject {
    @Published var agregandoInvitado = false

    let eventoID: UUID
    private let store: FiestappStore

    init(eventoID: UUID, store: FiestappStore) {
        self.eventoID = eventoID
        self.store = store
    }

    var evento: Evento? {
        store.evento(eventoID)
    }

    func estado(de evento: Evento) -> String? {
        if evento.cerrado { return "Cuentas cerradas" }
        if evento.esPasado() { return "Este evento ya pasó" }
        return nil
    }

    func textoFecha(_ evento: Evento) -> (inicio: String, fin: String?) {
        let inicio = "Inicio: \(Formato.diaMesLargo(evento.fecha)) · \(Formato.hora(evento.fecha))"
        guard evento.fin > evento.fecha else { return (inicio, nil) }
        return (inicio, "Fin: \(Formato.diaMesLargo(evento.fin)) · \(Formato.hora(evento.fin))")
    }

    // MARK: - Acciones

    func agregarInvitados(_ nuevos: [InvitadoNuevo]) {
        store.modificarEvento(eventoID) { evento in
            for nuevo in nuevos {
                evento.participantes.append(Participante(nombre: nuevo.nombre, fotoID: nuevo.fotoID))
            }
        }
    }

    func alternarParte(gastoID: UUID, participanteID: UUID) {
        store.modificarEvento(eventoID) { evento in
            guard let g = evento.gastos.firstIndex(where: { $0.id == gastoID }),
                  let p = evento.gastos[g].partes.firstIndex(where: { $0.participanteID == participanteID }) else { return }
            evento.gastos[g].partes[p].saldada.toggle()
        }
    }

    func saldar(_ transferencia: Transferencia) {
        store.modificarEvento(eventoID) { evento in
            evento.pagos.append(Pago(montoCentavos: transferencia.montoCentavos,
                                     deID: transferencia.de.id,
                                     paraID: transferencia.para.id))
        }
    }

    func deshacerPago(_ pagoID: UUID) {
        store.modificarEvento(eventoID) { evento in
            evento.pagos.removeAll { $0.id == pagoID }
        }
    }
}
