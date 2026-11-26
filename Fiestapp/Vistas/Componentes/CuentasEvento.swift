//  CuentasEvento.swift
//  Fiestapp

import SwiftUI
import SwiftData

// MARK: - Gastos Registrados

struct ListaGastos: View {
    let evento: Evento
    var editable: Bool = true
    var abierta: Bool = true

    @Environment(Navegador.self) private var navegador

    var body: some View {
        SeccionDesplegable("Gastos Registrados", abierta: abierta) {
            if evento.gastos.isEmpty {
                Text("Todavía no hay gastos.")
                    .foregroundStyle(.secondary)
            }

            ForEach(evento.gastosOrdenados) { gasto in
                Button {
                    if editable { navegador.ir(.gasto(evento, gasto)) }
                } label: {
                    HStack(spacing: 6) {
                        Text(gasto.concepto).lineLimit(1)
                        if gasto.fotoTicket != nil {
                            Image(systemName: "paperclip")
                                .font(.system(size: 11))
                                .foregroundStyle(Tema.tealOscuro)
                        }
                        Spacer()
                        Text(Dinero.texto(gasto.montoCentavos))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if editable && !evento.cerrado {
                Button {
                    navegador.ir(.gasto(evento, nil))
                } label: {
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
}

// MARK: - Balance del Grupo

struct BalanceGrupo: View {
    let evento: Evento
    var editable: Bool = true
    var abierta: Bool = true

    var body: some View {
        let netos = Balance.netos(evento)
        let transferencias = Balance.transferencias(evento)

        SeccionDesplegable("Balance del Grupo", abierta: abierta) {
            if evento.gastos.isEmpty {
                Text("Cuando registren gastos, aquí verás quién debe qué.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(evento.gastosOrdenados) { gasto in
                    FilaBalanceGasto(gasto: gasto, netos: netos, editable: editable && !evento.cerrado)
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
                        FilaTransferencia(transferencia: t, evento: evento, editable: editable && !evento.cerrado)
                    }
                }

                if !evento.pagos.isEmpty {
                    PagosRegistrados(evento: evento, editable: editable && !evento.cerrado)
                }
            }
        }
    }
}

private struct FilaBalanceGasto: View {
    let gasto: Gasto
    let netos: [PersistentIdentifier: Int]
    let editable: Bool

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
                        AvataresApilados(personas: pendientes.compactMap(\.participante), tamano: 22, maximo: 3)
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
            if let pagador = gasto.pagador {
                Text("Pagó \(pagador.nombre) · \(Dinero.texto(gasto.montoCentavos))")
                    .font(.fiesta(12))
                    .foregroundStyle(.secondary)
            }
            ForEach(gasto.partes.sorted { ($0.participante?.creadoEn ?? .now) < ($1.participante?.creadoEn ?? .now) }) { parte in
                if let persona = parte.participante {
                    let esPagador = persona.persistentModelID == gasto.pagador?.persistentModelID
                    let liquidada = Balance.parteLiquidada(parte, netos: netos)
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
                                parte.saldada.toggle()
                            } label: {
                                Text(liquidada ? "Pagado" : "Pendiente")
                                    .font(.fiesta(12, .semibold))
                                    .foregroundStyle(liquidada ? .white : Tema.tealOscuro)
                                    .frame(width: 78)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(liquidada ? Tema.teal : .white))
                            }
                            .buttonStyle(.plain)
                            .disabled(!editable || (liquidada && !parte.saldada))
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
    let evento: Evento
    let editable: Bool

    @Environment(\.modelContext) private var contexto

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
            if editable {
                Button("Saldar") { saldar() }
                    .font(.fiesta(12, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Tema.teal))
                    .buttonStyle(.plain)
            }
        }
    }

    private func saldar() {
        let pago = Pago(montoCentavos: transferencia.montoCentavos)
        contexto.insert(pago)
        pago.de = transferencia.de
        pago.para = transferencia.para
        pago.evento = evento
        try? contexto.save()
    }
}

private struct PagosRegistrados: View {
    let evento: Evento
    let editable: Bool

    @Environment(\.modelContext) private var contexto

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pagos saldados")
                .font(.fiesta(13, .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            ForEach(evento.pagos.sorted { $0.fecha < $1.fecha }) { pago in
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Tema.teal)
                    Text("\(pago.de?.primerNombre ?? "?") → \(pago.para?.primerNombre ?? "?")")
                    Spacer()
                    Text(Dinero.texto(pago.montoCentavos))
                    if editable {
                        Button {
                            contexto.delete(pago)
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
