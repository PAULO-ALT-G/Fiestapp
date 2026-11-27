//  CuentasEvento.swift
//  Fiestapp

import SwiftUI

struct AccionesCuentas {
    let alternarParte: (_ gastoID: UUID, _ participanteID: UUID) -> Void
    let saldar: (Transferencia) -> Void
    let deshacerPago: (UUID) -> Void
}

// MARK: - Gastos Registrados

struct ListaGastos: View {
    let evento: Evento
    var editable: Bool = true
    var abierta: Bool = true

    var body: some View {
        SeccionDesplegable("Gastos Registrados", abierta: abierta) {
            if evento.gastos.isEmpty {
                Text("Todavía no hay gastos.")
                    .foregroundStyle(.secondary)
            }

            ForEach(evento.gastosOrdenados) { gasto in
                if editable {
                    NavigationLink(value: Ruta.gasto(evento: evento.id, gasto: gasto.id)) {
                        filaGasto(gasto)
                    }
                    .buttonStyle(.plain)
                } else {
                    filaGasto(gasto)
                }
            }

            if editable && !evento.cerrado {
                NavigationLink(value: Ruta.gasto(evento: evento.id, gasto: nil)) {
                    HStack {
                        Text("Agregar Gasto")
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Tema.tealOscuro)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()
            HStack {
                Text("Total").fontWeight(.semibold)
                Spacer()
                Text(Dinero.texto(evento.totalCentavos)).fontWeight(.semibold)
            }
        }
    }

    private func filaGasto(_ gasto: Gasto) -> some View {
        HStack(spacing: 6) {
            Text(gasto.concepto).lineLimit(1)
            if gasto.fotoTicketID != nil {
                Image(systemName: "paperclip")
                    .font(.system(size: 11))
                    .foregroundStyle(Tema.tealOscuro)
            }
            Spacer()
            Text(Dinero.texto(gasto.montoCentavos))
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Balance del Grupo

struct BalanceGrupo: View {
    let evento: Evento
    var acciones: AccionesCuentas? = nil
    var abierta: Bool = true

    private var editable: Bool { acciones != nil && !evento.cerrado }

    var body: some View {
        let netos = Balance.netos(evento)
        let transferencias = Balance.transferencias(evento)

        SeccionDesplegable("Balance del Grupo", abierta: abierta) {
            if evento.gastos.isEmpty {
                Text("Cuando registren gastos, aquí verás quién debe qué.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(evento.gastosOrdenados) { gasto in
                    FilaBalanceGasto(evento: evento, gasto: gasto, netos: netos,
                                     alternar: editable ? acciones?.alternarParte : nil)
                }

                Divider()
                HStack {
                    Text("Total pendiente").fontWeight(.semibold)
                    Spacer()
                    Text(Dinero.texto(transferencias.reduce(0) { $0 + $1.montoCentavos }))
                        .fontWeight(.semibold)
                }

                Text("¿Quién le debe a quién?")
                    .font(.fiesta(15, .semibold))
                    .foregroundStyle(Tema.tealOscuro)
                    .padding(.top, 8)

                if transferencias.isEmpty {
                    Label("Todos están a mano", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Tema.tealOscuro)
                } else {
                    ForEach(transferencias) { t in
                        FilaTransferencia(transferencia: t, saldar: editable ? acciones?.saldar : nil)
                    }
                }

                if !evento.pagos.isEmpty {
                    PagosRegistrados(evento: evento, deshacer: editable ? acciones?.deshacerPago : nil)
                }
            }
        }
    }
}

private struct FilaBalanceGasto: View {
    let evento: Evento
    let gasto: Gasto
    let netos: [UUID: Int]
    let alternar: ((UUID, UUID) -> Void)?

    @State private var abierta = false

    var body: some View {
        let pendientes = Balance.partesPendientes(gasto, netos: netos)
        let montoPendiente = pendientes.reduce(0) { $0 + $1.montoCentavos }

        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { abierta.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text(gasto.concepto).lineLimit(1)
                    Spacer()
                    if pendientes.isEmpty {
                        Text("Pagado").foregroundStyle(Tema.tealOscuro)
                    } else {
                        Text(Dinero.texto(montoPendiente))
                        AvataresApilados(personas: pendientes.compactMap { evento.participante($0.participanteID) },
                                         tamano: 22, maximo: 3)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if abierta {
                desglose
            }
        }
    }

    private var desglose: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let pagador = evento.participante(gasto.pagadorID) {
                Text("Pagó \(pagador.nombre) · \(Dinero.texto(gasto.montoCentavos))")
                    .font(.fiesta(12))
                    .foregroundStyle(.secondary)
            }
            ForEach(gasto.partes) { parte in
                if let persona = evento.participante(parte.participanteID) {
                    let esPagador = parte.participanteID == gasto.pagadorID
                    let liquidada = Balance.parteLiquidada(parte, en: gasto, netos: netos)
                    HStack(spacing: 8) {
                        AvatarView(persona, tamano: 24)
                        Text(persona.primerNombre).font(.fiesta(13))
                        Spacer()
                        Text(Dinero.texto(parte.montoCentavos)).font(.fiesta(13))
                        if esPagador {
                            Text("Pagó").font(.fiesta(12, .medium)).foregroundStyle(.secondary)
                                .frame(width: 78, alignment: .trailing)
                        } else {
                            Button {
                                alternar?(gasto.id, parte.participanteID)
                            } label: {
                                Text(liquidada ? "Pagado" : "Pendiente")
                                    .font(.fiesta(12, .semibold))
                                    .foregroundStyle(liquidada ? .white : Tema.tealOscuro)
                                    .frame(width: 78)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(liquidada ? Tema.teal : .white))
                            }
                            .buttonStyle(.plain)
                            .disabled(alternar == nil || (liquidada && !parte.saldada))
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.6)))
    }
}

private struct FilaTransferencia: View {
    let transferencia: Transferencia
    let saldar: ((Transferencia) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            AvatarView(transferencia.de, tamano: 28)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Tema.tealOscuro)
            AvatarView(transferencia.para, tamano: 28)
            Text("\(Text(transferencia.de.primerNombre).bold()) le debe \(Text(Dinero.texto(transferencia.montoCentavos)).bold()) a \(Text(transferencia.para.primerNombre).bold())")
                .font(.fiesta(13))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let saldar {
                Button("Saldar") { saldar(transferencia) }
                    .font(.fiesta(12, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Tema.teal))
                    .buttonStyle(.plain)
            }
        }
    }
}

private struct PagosRegistrados: View {
    let evento: Evento
    let deshacer: ((UUID) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pagos saldados")
                .font(.fiesta(13, .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            ForEach(evento.pagos.sorted { $0.fecha < $1.fecha }) { pago in
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Tema.teal)
                    Text("\(evento.participante(pago.deID)?.primerNombre ?? "?") → \(evento.participante(pago.paraID)?.primerNombre ?? "?")")
                    Spacer()
                    Text(Dinero.texto(pago.montoCentavos))
                    if let deshacer {
                        Button {
                            deshacer(pago.id)
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .foregroundStyle(Tema.tealOscuro)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.fiesta(12))
            }
        }
    }
}
