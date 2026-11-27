//  DatosEjemplo.swift
//  Fiestapp

import Foundation

enum DatosEjemplo {
    static func store(vacio: Bool = false, sinPerfil: Bool = false) -> FiestappStore {
        let defaults = UserDefaults(suiteName: "fiestapp.previews") ?? .standard
        let store = FiestappStore(persistencia: PersistenciaService(defaults: defaults), guardaCambios: false)
        if vacio {
            store.usarDatos(perfil: sinPerfil ? nil : Perfil(nombre: "Santiago B."), eventos: [], amigos: [])
            return store
        }

        let amigos = ["Santi", "Mau", "Kiara", "Paulo", "Ana"].map { Amigo(nombre: $0) }

        var personas: [Participante] = []
        for (i, nombre) in ["Santiago B.", "Kiara", "Paulo", "Ana"].enumerated() {
            personas.append(Participante(nombre: nombre, esOrganizador: i == 0,
                                         creadoEn: Date(timeIntervalSince1970: Double(i))))
        }

        let inicio = Calendar.current.date(byAdding: .day, value: 20, to: .now) ?? .now
        var cumple = Evento(
            nombre: "Fiesta de Cumpleaños",
            tipo: .fiesta,
            detalles: "Haremos una celebración pequeña en mi casa (Santiago B.) y comeremos algo y escucharemos música y así.",
            lugar: "Augusto Rodin 123",
            latitud: 19.3836,
            longitud: -99.1830,
            fecha: inicio,
            fechaFin: Calendar.current.date(byAdding: .hour, value: 6, to: inicio),
            participantes: personas
        )
        cumple.gastos = [
            gasto("Pastel", 60000, pagador: personas[0], entre: personas, limite: inicio),
            gasto("Bebidas", 40000, pagador: personas[2], entre: personas, limite: inicio),
            gasto("Pizza", 24000, pagador: personas[1], entre: [personas[1], personas[3]], limite: inicio)
        ]

        let carne = Evento(
            nombre: "Carne asada",
            tipo: .comida,
            fecha: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now,
            participantes: [Participante(nombre: "Santiago B.", esOrganizador: true)]
        )

        var viaje = Evento(nombre: "Viaje a Valle", tipo: .viaje,
                           fecha: Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now)
        viaje.cerrado = true

        store.usarDatos(perfil: Perfil(nombre: "Santiago B."), eventos: [cumple, carne, viaje], amigos: amigos)
        return store
    }

    static func eventoConGastos(en store: FiestappStore) -> UUID {
        store.eventos.first { !$0.gastos.isEmpty }?.id ?? UUID()
    }

    private static func gasto(_ concepto: String, _ centavos: Int, pagador: Participante,
                              entre personas: [Participante], limite: Date) -> Gasto {
        let montos = Balance.dividirIguales(totalCentavos: centavos, entre: personas.count)
        let partes = zip(personas, montos).map { Parte(participanteID: $0.id, montoCentavos: $1) }
        return Gasto(concepto: concepto, montoCentavos: centavos, fechaLimite: limite,
                     pagadorID: pagador.id, partes: partes)
    }
}
