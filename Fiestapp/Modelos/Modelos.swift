//  Modelos.swift
//  Fiestapp

import Foundation
import SwiftData

// MARK: - Enums de apoyo

enum TipoSalida: String, CaseIterable, Identifiable {
    case comida = "Comida"
    case fiesta = "Fiesta"
    case viaje = "Viaje"
    case salida = "Salida"
    case otro = "Otro"

    var id: String { rawValue }

    var icono: String {
        switch self {
        case .comida: "fork.knife"
        case .fiesta: "party.popper"
        case .viaje: "airplane"
        case .salida: "figure.walk"
        case .otro: "sparkles"
        }
    }
}

enum TipoDivision: String, CaseIterable, Identifiable {
    case iguales = "Partes iguales"
    case personalizada = "Personalizada"

    var id: String { rawValue }
}

// MARK: - Perfil (el "yo" de la app)

@Model
final class Perfil {
    var nombre: String
    @Attribute(.externalStorage) var foto: Data?

    init(nombre: String, foto: Data? = nil) {
        self.nombre = nombre
        self.foto = foto
    }
}

// MARK: - Amigo (tu lista de amigos guardada)

@Model
final class Amigo {
    var nombre: String
    @Attribute(.externalStorage) var foto: Data?
    var creadoEn: Date

    init(nombre: String, foto: Data? = nil) {
        self.nombre = nombre
        self.foto = foto
        self.creadoEn = .now
    }
}

// MARK: - Evento

@Model
final class Evento {
    var nombre: String
    var tipoRaw: String
    var detalles: String
    var lugar: String
    var latitud: Double?
    var longitud: Double?
    var fecha: Date
    var fechaFin: Date?
    var cerrado: Bool
    @Attribute(.externalStorage) var portada: Data?
    var creadoEn: Date

    @Relationship(deleteRule: .cascade, inverse: \Participante.evento)
    var participantes: [Participante] = []

    @Relationship(deleteRule: .cascade, inverse: \Gasto.evento)
    var gastos: [Gasto] = []

    @Relationship(deleteRule: .cascade, inverse: \Pago.evento)
    var pagos: [Pago] = []

    init(nombre: String,
         tipo: TipoSalida = .fiesta,
         detalles: String = "",
         lugar: String = "",
         fecha: Date = .now,
         fechaFin: Date? = nil) {
        self.nombre = nombre
        self.tipoRaw = tipo.rawValue
        self.detalles = detalles
        self.lugar = lugar
        self.fecha = fecha
        self.fechaFin = fechaFin
        self.cerrado = false
        self.creadoEn = .now
    }

    var tipo: TipoSalida {
        get { TipoSalida(rawValue: tipoRaw) ?? .otro }
        set { tipoRaw = newValue.rawValue }
    }

    var fin: Date { fechaFin ?? fecha }

    func esPasado(_ ahora: Date = .now) -> Bool {
        cerrado || fin < ahora
    }

    var organizador: Participante? {
        participantes.first { $0.esOrganizador }
    }

    var participantesOrdenados: [Participante] {
        participantes.sorted {
            ($0.esOrganizador ? 0 : 1, $0.creadoEn) < ($1.esOrganizador ? 0 : 1, $1.creadoEn)
        }
    }

    var gastosOrdenados: [Gasto] {
        gastos.sorted { ($0.fecha, $0.creadoEn) < ($1.fecha, $1.creadoEn) }
    }

    var totalCentavos: Int {
        gastos.reduce(0) { $0 + $1.montoCentavos }
    }
}

// MARK: - Participante (invitado u organizador)

@Model
final class Participante {
    var nombre: String
    @Attribute(.externalStorage) var foto: Data?
    var esOrganizador: Bool
    var creadoEn: Date
    var evento: Evento?

    init(nombre: String, foto: Data? = nil, esOrganizador: Bool = false) {
        self.nombre = nombre
        self.foto = foto
        self.esOrganizador = esOrganizador
        self.creadoEn = .now
    }

    var primerNombre: String {
        nombre.split(separator: " ").first.map(String.init) ?? nombre
    }
}

// MARK: - Gasto

@Model
final class Gasto {
    var concepto: String
    var montoCentavos: Int
    var fecha: Date
    var fechaLimite: Date
    var divisionRaw: String
    @Attribute(.externalStorage) var fotoTicket: Data?
    var creadoEn: Date
    var evento: Evento?

    var pagador: Participante?

    @Relationship(deleteRule: .cascade, inverse: \Parte.gasto)
    var partes: [Parte] = []

    init(concepto: String, montoCentavos: Int, fecha: Date = .now, fechaLimite: Date = .now, division: TipoDivision = .iguales) {
        self.concepto = concepto
        self.montoCentavos = montoCentavos
        self.fecha = fecha
        self.fechaLimite = fechaLimite
        self.divisionRaw = division.rawValue
        self.creadoEn = .now
    }

    var division: TipoDivision {
        get { TipoDivision(rawValue: divisionRaw) ?? .iguales }
        set { divisionRaw = newValue.rawValue }
    }
}

// MARK: - Parte (lo que le toca a una persona de un gasto)

@Model
final class Parte {
    var montoCentavos: Int
    var saldada: Bool
    var participante: Participante?
    var gasto: Gasto?

    init(montoCentavos: Int, saldada: Bool = false) {
        self.montoCentavos = montoCentavos
        self.saldada = saldada
    }
}

// MARK: - Pago (deuda simplificada que se marcó como saldada)

@Model
final class Pago {
    var montoCentavos: Int
    var fecha: Date
    var de: Participante?
    var para: Participante?
    var evento: Evento?

    init(montoCentavos: Int) {
        self.montoCentavos = montoCentavos
        self.fecha = .now
    }
}
