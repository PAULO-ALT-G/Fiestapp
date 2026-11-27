//  Balance.swift
//  Fiestapp

import Foundation

struct Transferencia: Identifiable {
    let de: Participante
    let para: Participante
    let montoCentavos: Int

    var id: String { "\(de.id)-\(para.id)" }
}

enum Balance {
    // MARK: División de un gasto

    static func dividirIguales(totalCentavos: Int, entre personas: Int) -> [Int] {
        guard personas > 0 else { return [] }
        let base = totalCentavos / personas
        let sobrante = totalCentavos % personas
        var montos = Array(repeating: base, count: personas)
        for indice in Array(0..<personas).shuffled().prefix(sobrante) {
            montos[indice] += 1
        }
        return montos
    }

    // MARK: Saldos netos

    static func netos(_ evento: Evento) -> [UUID: Int] {
        var neto: [UUID: Int] = [:]
        for persona in evento.participantes {
            neto[persona.id] = 0
        }

        for gasto in evento.gastos {
            guard let pagadorID = gasto.pagadorID else { continue }
            for parte in gasto.partes where parte.participanteID != pagadorID && !parte.saldada {
                neto[pagadorID, default: 0] += parte.montoCentavos
                neto[parte.participanteID, default: 0] -= parte.montoCentavos
            }
        }

        for pago in evento.pagos {
            neto[pago.deID, default: 0] += pago.montoCentavos
            neto[pago.paraID, default: 0] -= pago.montoCentavos
        }

        return neto
    }

    // MARK: Simplificación de deudas

    static func transferencias(_ evento: Evento) -> [Transferencia] {
        let saldos = netos(evento)

        var deudores = saldos.filter { $0.value < 0 }
            .map { (id: $0.key, monto: -$0.value) }
            .sorted { $0.monto > $1.monto }
        var acreedores = saldos.filter { $0.value > 0 }
            .map { (id: $0.key, monto: $0.value) }
            .sorted { $0.monto > $1.monto }

        var resultado: [Transferencia] = []
        var i = 0
        var j = 0
        while i < deudores.count && j < acreedores.count {
            let monto = min(deudores[i].monto, acreedores[j].monto)
            if monto > 0,
               let de = evento.participante(deudores[i].id),
               let para = evento.participante(acreedores[j].id) {
                resultado.append(Transferencia(de: de, para: para, montoCentavos: monto))
            }
            deudores[i].monto -= monto
            acreedores[j].monto -= monto
            if deudores[i].monto == 0 { i += 1 }
            if acreedores[j].monto == 0 { j += 1 }
        }
        return resultado
    }

    // MARK: Estado por gasto

    static func parteLiquidada(_ parte: Parte, en gasto: Gasto, netos: [UUID: Int]) -> Bool {
        if parte.participanteID == gasto.pagadorID { return true }
        if parte.saldada { return true }
        return (netos[parte.participanteID] ?? 0) >= 0
    }

    static func partesPendientes(_ gasto: Gasto, netos: [UUID: Int]) -> [Parte] {
        gasto.partes.filter { !parteLiquidada($0, en: gasto, netos: netos) }
    }

    static func totalPendiente(_ evento: Evento) -> Int {
        transferencias(evento).reduce(0) { $0 + $1.montoCentavos }
    }

    static func participaEnCuentas(_ personaID: UUID, evento: Evento) -> Bool {
        let enGastos = evento.gastos.contains { gasto in
            gasto.pagadorID == personaID || gasto.partes.contains { $0.participanteID == personaID }
        }
        let enPagos = evento.pagos.contains { $0.deID == personaID || $0.paraID == personaID }
        return enGastos || enPagos
    }

    // MARK: Resumen para compartir

    static func resumen(_ evento: Evento) -> String {
        var lineas: [String] = []
        lineas.append("🎉 \(evento.nombre) — Fiestapp")
        lineas.append("📅 \(Formato.rango(evento.fecha, evento.fin))")
        if !evento.lugar.isEmpty { lineas.append("📍 \(evento.lugar)") }
        lineas.append("")
        lineas.append("Gastos:")
        for gasto in evento.gastosOrdenados {
            let pagador = evento.participante(gasto.pagadorID)?.nombre ?? "?"
            lineas.append("• \(gasto.concepto): \(Dinero.texto(gasto.montoCentavos)) (pagó \(pagador))")
        }
        lineas.append("Total: \(Dinero.texto(evento.totalCentavos))")
        lineas.append("")
        let pendientes = transferencias(evento)
        if pendientes.isEmpty {
            lineas.append("✅ Todos están a mano")
        } else {
            lineas.append("Pendientes:")
            for t in pendientes {
                lineas.append("• \(t.de.nombre) le debe \(Dinero.texto(t.montoCentavos)) a \(t.para.nombre)")
            }
        }
        lineas.append("")
        lineas.append("Cuentas claras, relaciones largas.")
        return lineas.joined(separator: "\n")
    }
}
