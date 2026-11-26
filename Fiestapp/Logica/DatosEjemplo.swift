//  DatosEjemplo.swift
//  Fiestapp

import Foundation
import SwiftData

enum DatosEjemplo {
    static func contenedor(vacio: Bool = false) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let contenedor = try! ModelContainer(
            for: Perfil.self, Amigo.self, Evento.self, Participante.self, Gasto.self, Parte.self, Pago.self,
            configurations: config
        )
        if vacio { return contenedor }

        let contexto = contenedor.mainContext
        contexto.insert(Perfil(nombre: "Santiago B."))
        for nombre in ["Santi", "Mau", "Kiara", "Paulo", "Ana"] {
            contexto.insert(Amigo(nombre: nombre))
        }

        let cumple = Evento(
            nombre: "Fiesta de Cumpleaños",
            tipo: .fiesta,
            detalles: "Haremos una celebración pequeña en mi casa (Santiago B.) y comeremos algo y escucharemos música y así.",
            lugar: "Augusto Rodin 123",
            fecha: Calendar.current.date(byAdding: .day, value: 20, to: .now) ?? .now
        )
        cumple.fechaFin = Calendar.current.date(byAdding: .hour, value: 6, to: cumple.fecha)
        cumple.latitud = 19.3836
        cumple.longitud = -99.1830
        contexto.insert(cumple)

        let nombres = ["Santiago B.", "Kiara", "Paulo", "Ana"]
        var personas: [Participante] = []
        for (i, nombre) in nombres.enumerated() {
            let p = Participante(nombre: nombre, esOrganizador: i == 0)
            p.creadoEn = Date(timeIntervalSince1970: Double(i))
            contexto.insert(p)
            p.evento = cumple
            personas.append(p)
        }

        agregarGasto("Pastel", 60000, pagador: personas[0], entre: personas, a: cumple, en: contexto)
        agregarGasto("Bebidas", 40000, pagador: personas[2], entre: personas, a: cumple, en: contexto)
        agregarGasto("Pizza", 24000, pagador: personas[1], entre: [personas[1], personas[3]], a: cumple, en: contexto)

        let carne = Evento(nombre: "Carne asada", tipo: .comida, fecha: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now)
        contexto.insert(carne)
        let org = Participante(nombre: "Santiago B.", esOrganizador: true)
        contexto.insert(org)
        org.evento = carne

        let viaje = Evento(nombre: "Viaje a Valle", tipo: .viaje, fecha: Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now)
        viaje.cerrado = true
        contexto.insert(viaje)

        return contenedor
    }

    private static func agregarGasto(_ concepto: String, _ centavos: Int, pagador: Participante,
                                     entre personas: [Participante], a evento: Evento, en contexto: ModelContext) {
        let gasto = Gasto(concepto: concepto, montoCentavos: centavos, fechaLimite: evento.fecha)
        contexto.insert(gasto)
        gasto.evento = evento
        gasto.pagador = pagador
        let montos = Balance.dividirIguales(totalCentavos: centavos, entre: personas.count)
        for (persona, monto) in zip(personas, montos) {
            let parte = Parte(montoCentavos: monto)
            contexto.insert(parte)
            parte.participante = persona
            parte.gasto = gasto
        }
    }

    static func evento(en contenedor: ModelContainer) -> Evento {
        let eventos = (try? contenedor.mainContext.fetch(FetchDescriptor<Evento>())) ?? []
        return eventos.first { !$0.gastos.isEmpty } ?? eventos[0]
    }

    static func perfil(en contenedor: ModelContainer) -> Perfil {
        (try? contenedor.mainContext.fetch(FetchDescriptor<Perfil>()))?.first ?? Perfil(nombre: "Yo")
    }
}
