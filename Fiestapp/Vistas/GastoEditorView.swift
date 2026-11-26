//  GastoEditorView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct GastoEditorView: View {
    let evento: Evento
    let gasto: Gasto?

    @Environment(Navegador.self) private var navegador
    @Environment(\.modelContext) private var contexto

    @State private var concepto: String
    @State private var montoTexto: String
    @State private var fecha: Date
    @State private var fechaLimite: Date
    @State private var division: TipoDivision
    @State private var seleccionados: Set<PersistentIdentifier>
    @State private var montosPersonalizados: [PersistentIdentifier: String]
    @State private var pagadorID: PersistentIdentifier?
    @State private var foto: Data?

    @State private var agregandoInvitado = false
    @State private var alerta: String?
    @State private var confirmarBorrado = false
    @State private var verFotoCompleta = false

    init(evento: Evento, gasto: Gasto?) {
        self.evento = evento
        self.gasto = gasto

        _concepto = State(initialValue: gasto?.concepto ?? "")
        _montoTexto = State(initialValue: gasto.map { Dinero.textoEditable($0.montoCentavos) } ?? "")
        _fecha = State(initialValue: gasto?.fecha ?? .now)
        _fechaLimite = State(initialValue: gasto?.fechaLimite ?? max(evento.fecha, .now))
        _division = State(initialValue: gasto?.division ?? .iguales)
        _foto = State(initialValue: gasto?.fotoTicket)
        _pagadorID = State(initialValue: gasto?.pagador?.persistentModelID ?? evento.organizador?.persistentModelID)

        if let gasto {
            _seleccionados = State(initialValue: Set(gasto.partes.compactMap { $0.participante?.persistentModelID }))
            var montos: [PersistentIdentifier: String] = [:]
            for parte in gasto.partes {
                if let id = parte.participante?.persistentModelID {
                    montos[id] = Dinero.textoEditable(parte.montoCentavos)
                }
            }
            _montosPersonalizados = State(initialValue: montos)
        } else {
            _seleccionados = State(initialValue: Set(evento.participantes.map(\.persistentModelID)))
            _montosPersonalizados = State(initialValue: [:])
        }
    }

    // MARK: - Datos calculados

    private var personas: [Participante] { evento.participantesOrdenados }

    private var elegidos: [Participante] {
        personas.filter { seleccionados.contains($0.persistentModelID) }
    }

    private var totalCentavos: Int { Dinero.centavos(de: montoTexto) ?? 0 }

    private var sumaPersonalizada: Int {
        elegidos.reduce(0) { suma, persona in
            suma + (Dinero.centavos(de: montosPersonalizados[persona.persistentModelID] ?? "") ?? 0)
        }
    }

    // MARK: - Vista

    var body: some View {
        PantallaFiesta(barra: [
            BotonBarra(titulo: "Detalles", icono: "arrow.left") { navegador.atras() },
            BotonBarra(titulo: "Ticket", icono: "paperclip", activo: true) {},
            BotonBarra(titulo: "Listo", icono: "checkmark", deshabilitado: evento.cerrado) { guardar() }
        ]) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(gasto == nil ? "Registrar Gasto" : "Editar Gasto").font(.fiesta(13))
                    Text("Ticket").font(.fiesta(30, .medium))
                }
                Spacer()
                if gasto != nil && !evento.cerrado {
                    Button { confirmarBorrado = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(.white)
        } contenido: {
            VStack(alignment: .leading, spacing: 0) {
                formulario
                divisor
                seccionDivision
                divisor
                seccionPagador
                divisor
                seccionRecibo
            }
            .disabled(evento.cerrado)
        }
        .sheet(isPresented: $agregandoInvitado) {
            ElegirInvitadosSheet(yaInvitados: evento.participantes.map(\.nombre)) { nuevos in
                var agregados: [Participante] = []
                for nuevo in nuevos {
                    let persona = Participante(nombre: nuevo.nombre, foto: nuevo.foto)
                    contexto.insert(persona)
                    persona.evento = evento
                    agregados.append(persona)
                }
                try? contexto.save()
                for persona in agregados {
                    seleccionados.insert(persona.persistentModelID)
                }
            }
        }
        .sheet(isPresented: $verFotoCompleta) {
            if let foto, let ui = UIImage(data: foto) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Revisa el gasto", isPresented: Binding(get: { alerta != nil }, set: { if !$0 { alerta = nil } })) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(alerta ?? "")
        }
        .confirmationDialog("¿Eliminar este gasto?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar gasto", role: .destructive) { eliminar() }
        }
    }

    private var divisor: some View {
        Rectangle().fill(Tema.teal).frame(height: 2).padding(.vertical, 14)
    }

    private var formulario: some View {
        VStack(spacing: 4) {
            Rectangle().fill(Tema.teal).frame(height: 2).padding(.bottom, 8)
            fila("Concepto") {
                TextField("Comida", text: $concepto)
                    .multilineTextAlignment(.trailing)
            }
            fila("Monto") {
                HStack(spacing: 2) {
                    Text("$")
                        .foregroundStyle(montoTexto.isEmpty ? Color.secondary : Tema.texto)
                    TextField("0", text: $montoTexto)
                        .keyboardType(.decimalPad)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: 30, alignment: .leading)
                }
            }
            fila("Fecha") {
                DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
                    .labelsHidden()
            }
            fila("Fecha límite de pago") {
                DatePicker("Fecha límite de pago", selection: $fechaLimite, displayedComponents: .date)
                    .labelsHidden()
            }
        }
    }

    private func fila<Campo: View>(_ titulo: String, @ViewBuilder campo: () -> Campo) -> some View {
        HStack {
            Text(titulo)
                .font(.fiesta(16, .medium))
                .foregroundStyle(Tema.texto)
            Spacer()
            campo()
                .font(.fiesta(15))
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 38)
    }

    private var seccionDivision: some View {
        VStack(spacing: 12) {
            Text("¿Entre quiénes se divide?")
                .font(.fiesta(18, .medium))
                .foregroundStyle(Tema.texto)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    BotonMas(tamano: 46) { agregandoInvitado = true }
                    ForEach(personas) { persona in
                        let activo = seleccionados.contains(persona.persistentModelID)
                        Button {
                            if activo { seleccionados.remove(persona.persistentModelID) }
                            else { seleccionados.insert(persona.persistentModelID) }
                        } label: {
                            VStack(spacing: 4) {
                                AvatarView(persona, tamano: 46)
                                    .opacity(activo ? 1 : 0.35)
                                    .overlay(alignment: .bottomTrailing) {
                                        if activo {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.white, Tema.teal)
                                                .font(.system(size: 16))
                                        }
                                    }
                                Text(persona.primerNombre)
                                    .font(.fiesta(11))
                                    .foregroundStyle(Tema.texto)
                                    .lineLimit(1)
                                    .frame(width: 54)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)

            Picker("División", selection: $division) {
                ForEach(TipoDivision.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if division == .iguales {
                if !elegidos.isEmpty && totalCentavos > 0 {
                    Text("A cada quien le tocan aprox. \(Dinero.texto(totalCentavos / elegidos.count))")
                        .font(.fiesta(13))
                        .foregroundStyle(.secondary)
                }
            } else {
                montosPorPersona
            }
        }
    }

    private var montosPorPersona: some View {
        VStack(spacing: 8) {
            ForEach(elegidos) { persona in
                HStack {
                    AvatarView(persona, tamano: 28)
                    Text(persona.nombre).font(.fiesta(14))
                    Spacer()
                    HStack(spacing: 2) {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: Binding(
                            get: { montosPersonalizados[persona.persistentModelID] ?? "" },
                            set: { montosPersonalizados[persona.persistentModelID] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                    }
                    .font(.fiesta(14))
                    .frame(width: 90)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                }
            }
            let restante = totalCentavos - sumaPersonalizada
            Text(restante == 0 ? "¡Cuadra exacto!" : "Faltan por asignar \(Dinero.texto(restante))")
                .font(.fiesta(13, .medium))
                .foregroundStyle(restante == 0 ? Tema.tealOscuro : .orange)
        }
        .padding(.horizontal, 24)
    }

    private var seccionPagador: some View {
        VStack(spacing: 12) {
            Text("¿Quién pagó?")
                .font(.fiesta(18, .medium))
                .foregroundStyle(Tema.texto)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(personas) { persona in
                        let activo = pagadorID == persona.persistentModelID
                        Button { pagadorID = persona.persistentModelID } label: {
                            VStack(spacing: 4) {
                                AvatarView(persona, tamano: 46, borde: activo ? Tema.teal : .white)
                                    .overlay(Circle().stroke(Tema.teal, lineWidth: activo ? 3 : 0).padding(-3))
                                    .opacity(activo ? 1 : 0.5)
                                Text(persona.primerNombre)
                                    .font(.fiesta(11, activo ? .semibold : .regular))
                                    .foregroundStyle(Tema.texto)
                                    .lineLimit(1)
                                    .frame(width: 54)
                            }
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var seccionRecibo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recibo")
                .font(.fiesta(17, .medium))
                .foregroundStyle(Tema.texto)
                .padding(.horizontal, 20)

            HStack {
                Spacer()
                if let foto, let ui = UIImage(data: foto) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { verFotoCompleta = true }
                        .overlay(alignment: .bottomTrailing) {
                            SelectorFoto(foto: $foto, permitirEscaner: true, ajuste: .libre) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, Tema.teal)
                                    .padding(6)
                            }
                        }
                } else {
                    SelectorFoto(foto: $foto, permitirEscaner: true, ajuste: .libre) {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 30))
                            Text("Foto del ticket\n(opcional)")
                                .font(.fiesta(12))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(Tema.tealOscuro)
                        .frame(width: 150, height: 190)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Tema.teal, style: StrokeStyle(lineWidth: 2, dash: [6]))
                        )
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Acciones

    private func guardar() {
        let conceptoFinal = concepto.limpio
        guard !conceptoFinal.isEmpty else { alerta = "Escribe el concepto del gasto."; return }
        guard let total = Dinero.centavos(de: montoTexto), total > 0 else { alerta = "Escribe un monto válido."; return }
        guard !elegidos.isEmpty else { alerta = "Elige al menos a una persona para dividir."; return }
        guard let pagador = personas.first(where: { $0.persistentModelID == pagadorID }) else {
            alerta = "Elige quién pagó."; return
        }

        var montos: [Int]
        switch division {
        case .iguales:
            let idsElegidos = Set(elegidos.map(\.persistentModelID))
            let idsAnteriores = Set(gasto?.partes.compactMap { $0.participante?.persistentModelID } ?? [])
            if let gasto, gasto.division == .iguales, gasto.montoCentavos == total, idsAnteriores == idsElegidos {
                montos = elegidos.map { persona in
                    gasto.partes.first { $0.participante?.persistentModelID == persona.persistentModelID }?.montoCentavos ?? 0
                }
            } else {
                montos = Balance.dividirIguales(totalCentavos: total, entre: elegidos.count)
            }
        case .personalizada:
            montos = elegidos.map { Dinero.centavos(de: montosPersonalizados[$0.persistentModelID] ?? "") ?? 0 }
            let suma = montos.reduce(0, +)
            guard suma == total else {
                alerta = "Los montos suman \(Dinero.texto(suma)) pero el gasto es de \(Dinero.texto(total))."
                return
            }
        }

        let destino: Gasto
        if let gasto {
            destino = gasto
        } else {
            destino = Gasto(concepto: conceptoFinal, montoCentavos: total)
            contexto.insert(destino)
            destino.evento = evento
        }

        destino.concepto = conceptoFinal
        destino.montoCentavos = total
        destino.fecha = fecha
        destino.fechaLimite = fechaLimite
        destino.division = division
        destino.fotoTicket = foto
        destino.pagador = pagador

        let yaPagaron = Set(destino.partes.filter(\.saldada).compactMap { $0.participante?.persistentModelID })
        for parte in destino.partes { contexto.delete(parte) }
        destino.partes.removeAll()

        for (persona, monto) in zip(elegidos, montos) {
            let parte = Parte(montoCentavos: monto, saldada: yaPagaron.contains(persona.persistentModelID))
            contexto.insert(parte)
            parte.participante = persona
            parte.gasto = destino
        }

        try? contexto.save()
        navegador.atras()
    }

    private func eliminar() {
        guard let gasto else { return }
        contexto.delete(gasto)
        try? contexto.save()
        navegador.atras()
    }
}

#Preview("Nuevo") {
    let contenedor = DatosEjemplo.contenedor()
    return NavigationStack {
        GastoEditorView(evento: DatosEjemplo.evento(en: contenedor), gasto: nil)
    }
    .environment(Navegador())
    .modelContainer(contenedor)
}

#Preview("Editar") {
    let contenedor = DatosEjemplo.contenedor()
    let evento = DatosEjemplo.evento(en: contenedor)
    return NavigationStack {
        GastoEditorView(evento: evento, gasto: evento.gastosOrdenados.first)
    }
    .environment(Navegador())
    .modelContainer(contenedor)
}
