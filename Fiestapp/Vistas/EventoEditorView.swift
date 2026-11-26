//  EventoEditorView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct InvitadoBorrador: Identifiable {
    let id = UUID()
    var nombre: String
    var foto: Data?
    var existente: Participante?
    var esOrganizador: Bool
}

struct EventoEditorView: View {
    let evento: Evento?
    let perfil: Perfil

    @Environment(Navegador.self) private var navegador
    @Environment(\.modelContext) private var contexto

    @State private var nombre: String
    @State private var tipo: TipoSalida
    @State private var detalles: String
    @State private var lugar: String
    @State private var latitud: Double?
    @State private var longitud: Double?
    @State private var fecha: Date
    @State private var fechaFin: Date
    @State private var portada: Data?
    @State private var cerrado: Bool
    @State private var invitados: [InvitadoBorrador]

    @State private var agregandoInvitado = false
    @State private var eligiendoOrganizador = false
    @State private var invitadoEditando: InvitadoBorrador?
    @State private var alerta: String?
    @State private var confirmarBorrado = false

    init(evento: Evento?, perfil: Perfil) {
        self.evento = evento
        self.perfil = perfil
        _nombre = State(initialValue: evento?.nombre ?? "")
        _tipo = State(initialValue: evento?.tipo ?? .fiesta)
        _detalles = State(initialValue: evento?.detalles ?? "")
        _lugar = State(initialValue: evento?.lugar ?? "")
        _latitud = State(initialValue: evento?.latitud)
        _longitud = State(initialValue: evento?.longitud)
        let inicio = evento?.fecha ?? .now
        _fecha = State(initialValue: inicio)
        _fechaFin = State(initialValue: evento?.fechaFin ?? Formato.finDelDia(inicio))
        _portada = State(initialValue: evento?.portada)
        _cerrado = State(initialValue: evento?.cerrado ?? false)

        if let evento {
            _invitados = State(initialValue: evento.participantesOrdenados.map {
                InvitadoBorrador(nombre: $0.nombre, foto: $0.foto, existente: $0, esOrganizador: $0.esOrganizador)
            })
        } else {
            _invitados = State(initialValue: [
                InvitadoBorrador(nombre: perfil.nombre, foto: perfil.foto, existente: nil, esOrganizador: true)
            ])
        }
    }

    private var organizador: String {
        invitados.first { $0.esOrganizador }?.nombre ?? perfil.nombre
    }

    var body: some View {
        PantallaFiesta(imagen: portada, barra: [
            BotonBarra(titulo: "Detalles", icono: "arrow.left") { navegador.atras() },
            BotonBarra(titulo: "Editor", icono: "pencil", activo: true) {},
            BotonBarra(titulo: "Listo", icono: "checkmark") { guardar() }
        ]) {
            encabezado
        } contenido: {
            VStack(alignment: .leading, spacing: 18) {
                EncabezadoSeccion("Detalles:")
                TextField("Escriba los detalles del evento.", text: $detalles, axis: .vertical)
                    .lineLimit(3...8)
                    .font(.fiesta(15))
                    .padding(.horizontal, 20)

                EncabezadoSeccion("Lugar:")
                BuscadorLugar(lugar: $lugar, latitud: $latitud, longitud: $longitud)
                LineaSeccion()

                seccionInvitados

                if let evento {
                    ListaGastos(evento: evento, editable: false, abierta: false)
                    BalanceGrupo(evento: evento, editable: false, abierta: false)
                    opcionesEventoExistente
                }
            }
        }
        .sheet(isPresented: $agregandoInvitado) {
            ElegirInvitadosSheet(yaInvitados: invitados.map(\.nombre)) { nuevos in
                for nuevo in nuevos {
                    invitados.append(InvitadoBorrador(nombre: nuevo.nombre, foto: nuevo.foto, existente: nil, esOrganizador: false))
                }
            }
        }
        .sheet(isPresented: $eligiendoOrganizador) {
            ElegirInvitadosSheet(yaInvitados: invitados.map(\.nombre)) { nuevos in
                for nuevo in nuevos {
                    invitados.append(InvitadoBorrador(nombre: nuevo.nombre, foto: nuevo.foto, existente: nil, esOrganizador: false))
                }
                if let primero = nuevos.first,
                   let nuevoOrganizador = invitados.last(where: { $0.nombre == primero.nombre }) {
                    hacerOrganizador(nuevoOrganizador)
                }
            }
        }
        .sheet(item: $invitadoEditando) { invitado in
            InvitadoSheet(
                titulo: invitado.esOrganizador ? "Organizador" : "Editar invitado",
                nombre: invitado.nombre,
                foto: invitado.foto,
                alGuardar: { nombre, foto in
                    if let i = invitados.firstIndex(where: { $0.id == invitado.id }) {
                        invitados[i].nombre = nombre
                        invitados[i].foto = foto
                    }
                },
                alEliminar: puedeEliminar(invitado) ? { eliminar(invitado) } : nil
            )
        }
        .alert("Ojo", isPresented: Binding(get: { alerta != nil }, set: { if !$0 { alerta = nil } })) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(alerta ?? "")
        }
        .confirmationDialog("¿Eliminar este evento?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar evento", role: .destructive) { eliminarEvento() }
        } message: {
            Text("Se borran también sus gastos y fotos. No se puede deshacer.")
        }
    }

    // MARK: - Partes de la vista

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(evento == nil ? "Crear" : "Editor")
                    .font(.fiesta(13))
                Spacer()
                SelectorFoto(foto: $portada, ajuste: .portada) {
                    Image(systemName: portada == nil ? "photo" : "photo.fill")
                        .font(.system(size: 22))
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.2)))
                }
            }

            TextField("", text: $nombre, prompt: Text("Nombre del evento").foregroundStyle(.white.opacity(0.75)))
                .font(.fiesta(30, .medium))
                .textInputAutocapitalization(.sentences)

            Menu {
                Picker("Tipo de salida", selection: $tipo) {
                    ForEach(TipoSalida.allCases) { opcion in
                        Label(opcion.rawValue, systemImage: opcion.icono).tag(opcion)
                    }
                }
            } label: {
                Label(tipo.rawValue, systemImage: tipo.icono)
                    .font(.fiesta(13, .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.2)))
            }

            Menu {
                Section("¿Quién organiza?") {
                    ForEach(invitados) { invitado in
                        Button {
                            hacerOrganizador(invitado)
                        } label: {
                            if invitado.esOrganizador {
                                Label(invitado.nombre, systemImage: "checkmark")
                            } else {
                                Text(invitado.nombre)
                            }
                        }
                    }
                }
                Button("Alguien más…", systemImage: "person.badge.plus") { eligiendoOrganizador = true }
            } label: {
                HStack(alignment: .bottom, spacing: 6) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Organizador:").font(.fiesta(13))
                        Text(organizador).font(.fiesta(16, .semibold))
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.bottom, 3)
                }
            }
            .padding(.top, 6)

            VStack(spacing: 6) {
                HStack {
                    Text("Inicio").font(.fiesta(14, .medium))
                    Spacer()
                    DatePicker("Inicio", selection: $fecha, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                HStack {
                    Text("Fin").font(.fiesta(14, .medium))
                    Spacer()
                    DatePicker("Fin", selection: $fechaFin, in: fecha..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
            .colorScheme(.dark)
            .padding(.top, 6)
            .onChange(of: fecha) { _, nuevoInicio in
                if fechaFin < nuevoInicio {
                    let finDelDia = Formato.finDelDia(nuevoInicio)
                    fechaFin = finDelDia > nuevoInicio ? finDelDia : nuevoInicio.addingTimeInterval(3600)
                }
            }
        }
        .foregroundStyle(.white)
    }

    private var seccionInvitados: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invitados")
                .font(.fiesta(17, .medium))
                .foregroundStyle(Tema.texto)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    BotonMas { agregandoInvitado = true }
                    ForEach(invitados) { invitado in
                        Button { invitadoEditando = invitado } label: {
                            VStack(spacing: 4) {
                                AvatarView(nombre: invitado.nombre, foto: invitado.foto, tamano: 44,
                                           borde: invitado.esOrganizador ? Tema.teal : .white)
                                Text(invitado.nombre.split(separator: " ").first.map(String.init) ?? "")
                                    .font(.fiesta(11))
                                    .foregroundStyle(Tema.texto)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -20)
            Text("Toca a alguien para renombrarlo o quitarlo. Quien ya está en un gasto no se puede quitar.")
                .font(.fiesta(12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }

    private var opcionesEventoExistente: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $cerrado) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cerrar cuentas").font(.fiesta(15, .medium))
                    Text("Ya nadie puede agregar ni editar gastos. Ojo: el evento se mueve solo a \"Pasados\" cuando termina su fecha de fin.")
                        .font(.fiesta(12))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Tema.teal)

            Button(role: .destructive) { confirmarBorrado = true } label: {
                Label("Eliminar evento", systemImage: "trash")
                    .font(.fiesta(15, .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
        .padding(.horizontal, 16)
    }

    // MARK: - Acciones

    private func puedeEliminar(_ invitado: InvitadoBorrador) -> Bool {
        if invitado.esOrganizador { return false }
        if let persona = invitado.existente, let evento, Balance.participaEnCuentas(persona, evento: evento) {
            return false
        }
        return true
    }

    private func eliminar(_ invitado: InvitadoBorrador) {
        invitados.removeAll { $0.id == invitado.id }
    }

    private func hacerOrganizador(_ elegido: InvitadoBorrador) {
        for i in invitados.indices {
            invitados[i].esOrganizador = (invitados[i].id == elegido.id)
        }
    }

    private func guardar() {
        let nombreFinal = nombre.limpio.isEmpty ? "Evento" : nombre.limpio

        let destino: Evento
        if let evento {
            destino = evento
        } else {
            destino = Evento(nombre: nombreFinal)
            contexto.insert(destino)
        }

        destino.nombre = nombreFinal
        destino.tipo = tipo
        destino.detalles = detalles.limpio
        destino.lugar = lugar
        destino.latitud = latitud
        destino.longitud = longitud
        destino.fecha = fecha
        destino.fechaFin = max(fechaFin, fecha)
        destino.portada = portada
        destino.cerrado = cerrado

        let conservados = Set(invitados.compactMap { $0.existente?.persistentModelID })
        for persona in destino.participantes where !conservados.contains(persona.persistentModelID) {
            contexto.delete(persona)
        }

        for invitado in invitados {
            if let persona = invitado.existente {
                persona.nombre = invitado.nombre
                persona.foto = invitado.foto
                persona.esOrganizador = invitado.esOrganizador
            } else {
                let persona = Participante(nombre: invitado.nombre, foto: invitado.foto, esOrganizador: invitado.esOrganizador)
                contexto.insert(persona)
                persona.evento = destino
            }
        }

        try? contexto.save()

        if evento == nil {
            navegador.reemplazar(con: .detalle(destino))
        } else {
            navegador.atras()
        }
    }

    private func eliminarEvento() {
        guard let evento else { return }
        contexto.delete(evento)
        try? contexto.save()
        navegador.inicio()
    }
}

#Preview("Crear") {
    let contenedor = DatosEjemplo.contenedor()
    return NavigationStack {
        EventoEditorView(evento: nil, perfil: DatosEjemplo.perfil(en: contenedor))
    }
    .environment(Navegador())
    .modelContainer(contenedor)
}

#Preview("Editar") {
    let contenedor = DatosEjemplo.contenedor()
    return NavigationStack {
        EventoEditorView(evento: DatosEjemplo.evento(en: contenedor), perfil: DatosEjemplo.perfil(en: contenedor))
    }
    .environment(Navegador())
    .modelContainer(contenedor)
}
