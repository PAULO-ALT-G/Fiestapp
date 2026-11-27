//  Modelos.swift
//  Fiestapp

import Foundation

// MARK: - Enums

enum TipoSalida: String, CaseIterable, Identifiable, Codable, Sendable {
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

enum TipoDivision: String, CaseIterable, Identifiable, Codable, Sendable {
    case iguales = "Partes iguales"
    case personalizada = "Personalizada"

    var id: String { rawValue }
}

// MARK: - Perfil

struct Perfil: Codable, Sendable, Equatable {
    var nombre: String
    var fotoID: String?
}

// MARK: - Amigo

struct Amigo: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var nombre: String
    var fotoID: String?
    var creadoEn = Date.now
}

// MARK: - Participante

struct Participante: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var nombre: String
    var fotoID: String?
    var esOrganizador = false
    var creadoEn = Date.now

    var primerNombre: String {
        nombre.split(separator: " ").first.map(String.init) ?? nombre
    }
}

// MARK: - Gasto

struct Parte: Identifiable, Codable, Sendable, Equatable {
    var participanteID: UUID
    var montoCentavos: Int
    var saldada = false

    var id: UUID { participanteID }
}

struct Gasto: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var concepto: String
    var montoCentavos: Int
    var fecha = Date.now
    var fechaLimite = Date.now
    var division: TipoDivision = .iguales
    var fotoTicketID: String?
    var pagadorID: UUID?
    var partes: [Parte] = []
    var creadoEn = Date.now
}

// MARK: - Pago

struct Pago: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var montoCentavos: Int
    var fecha = Date.now
    var deID: UUID
    var paraID: UUID
}

// MARK: - Evento

struct Evento: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var nombre: String
    var tipo: TipoSalida = .fiesta
    var detalles = ""
    var lugar = ""
    var latitud: Double?
    var longitud: Double?
    var fecha = Date.now
    var fechaFin: Date?
    var cerrado = false
    var portadaID: String?
    var participantes: [Participante] = []
    var gastos: [Gasto] = []
    var pagos: [Pago] = []
    var creadoEn = Date.now

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

    func participante(_ id: UUID?) -> Participante? {
        guard let id else { return nil }
        return participantes.first { $0.id == id }
    }
}
