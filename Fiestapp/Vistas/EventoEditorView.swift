//  EventoEditorView.swift
//  Fiestapp

import SwiftUI

struct EventoEditorView: View {
    @EnvironmentObject private var navegador: Navegador
    @EnvironmentObject private var store: FiestappStore
    @StateObject private var viewModel: EventoEditorViewModel

    init(eventoID: UUID?, store: FiestappStore) {
        _viewModel = StateObject(wrappedValue: EventoEditorViewModel(eventoID: eventoID, store: store))
    }

    var body: some View {
        PantallaFiesta(imagen: viewModel.portada, barra: [
            BotonBarra(titulo: "Detalles", icono: "arrow.left") { navegador.atras() },
            BotonBarra(titulo: "Editor", icono: "pencil", activo: true),
            BotonBarra(titulo: "Listo", icono: "checkmark") { guardar() }
        ]) {
            encabezado
        } contenido: {
            VStack(alignment: .leading, spacing: 18) {
                EncabezadoSeccion("Detalles:")
                TextField("Escriba los detalles del evento.", text: $viewModel.detalles, axis: .vertical)
                    .lineLimit(3...8)
                    .font(.fiesta(15))
                    .padding(.horizontal, 20)

                EncabezadoSeccion("Lugar:")
                BuscadorLugar(lugar: $viewModel.lugar, latitud: $viewModel.latitud, longitud: $viewModel.longitud)
                LineaSeccion()

                seccionInvitados

                if let evento = viewModel.eventoGuardado {
                    ListaGastos(evento: evento, editable: false, abierta: false)
                    BalanceGrupo(evento: evento, abierta: false)
                    opcionesEventoExistente
                }
            }
        }
        .sheet(isPresented: $viewModel.agregandoInvitado) {
            ElegirInvitadosSheet(store: store, yaInvitados: viewModel.nombresInvitados) { nuevos in
                viewModel.agregarInvitados(nuevos)
            }
        }
        .sheet(isPresented: $viewModel.eligiendoOrganizador) {
            ElegirInvitadosSheet(store: store, yaInvitados: viewModel.nombresInvitados) { nuevos in
                viewModel.agregarComoOrganizador(nuevos)
            }
        }
        .sheet(item: $viewModel.invitadoEditando) { invitado in
            InvitadoSheet(
                titulo: invitado.esOrganizador ? "Organizador" : "Editar invitado",
                nombre: invitado.nombre,
                foto: invitado.foto,
                alGuardar: { nombre, foto in viewModel.actualizar(invitado, nombre: nombre, foto: foto) },
                alEliminar: viewModel.puedeEliminar(invitado) ? { viewModel.eliminar(invitado) } : nil
            )
        }
        .confirmationDialog("¿Eliminar este evento?", isPresented: $viewModel.confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar evento", role: .destructive) {
                viewModel.eliminarEvento()
                navegador.inicio()
            }
        } message: {
            Text("Se borran también sus gastos y fotos. No se puede deshacer.")
        }
    }

    private func guardar() {
        let id = viewModel.guardar()
        if viewModel.esNuevo {
            navegador.reemplazar(con: .detalle(id))
        } else {
            navegador.atras()
        }
    }

    // MARK: - Partes de la vista

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(viewModel.esNuevo ? "Crear" : "Editor")
                    .font(.fiesta(13))
                Spacer()
                SelectorFoto(foto: $viewModel.portada, ajuste: .portada) {
                    Image(systemName: viewModel.portada == nil ? "photo" : "photo.fill")
                        .font(.system(size: 22))
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.2)))
                }
            }

            TextField("", text: $viewModel.nombre, prompt: Text("Nombre del evento").foregroundStyle(.white.opacity(0.75)))
                .font(.fiesta(30, .medium))
                .textInputAutocapitalization(.sentences)

            Menu {
                Picker("Tipo de salida", selection: $viewModel.tipo) {
                    ForEach(TipoSalida.allCases) { opcion in
                        Label(opcion.rawValue, systemImage: opcion.icono).tag(opcion)
                    }
                }
            } label: {
                Label(viewModel.tipo.rawValue, systemImage: viewModel.tipo.icono)
                    .font(.fiesta(13, .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.2)))
            }

            Menu {
                Section("¿Quién organiza?") {
                    ForEach(viewModel.invitados) { invitado in
                        Button {
                            viewModel.hacerOrganizador(invitado)
                        } label: {
                            if invitado.esOrganizador {
                                Label(invitado.nombre, systemImage: "checkmark")
                            } else {
                                Text(invitado.nombre)
                            }
                        }
                    }
                }
                Button("Alguien más…", systemImage: "person.badge.plus") { viewModel.eligiendoOrganizador = true }
            } label: {
                HStack(alignment: .bottom, spacing: 6) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Organizador:").font(.fiesta(13))
                        Text(viewModel.organizador).font(.fiesta(16, .semibold))
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
                    DatePicker("Inicio", selection: $viewModel.fecha, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                HStack {
                    Text("Fin").font(.fiesta(14, .medium))
                    Spacer()
                    DatePicker("Fin", selection: $viewModel.fechaFin, in: viewModel.fecha..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
            .colorScheme(.dark)
            .padding(.top, 6)
            .onChange(of: viewModel.fecha) { _, nuevoInicio in
                viewModel.inicioCambio(a: nuevoInicio)
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
                    BotonMas { viewModel.agregandoInvitado = true }
                    ForEach(viewModel.invitados) { invitado in
                        Button { viewModel.invitadoEditando = invitado } label: {
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
            Toggle(isOn: $viewModel.cerrado) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cerrar cuentas").font(.fiesta(15, .medium))
                    Text("Ya nadie puede agregar ni editar gastos. Ojo: el evento se mueve solo a \"Pasados\" cuando termina su fecha de fin.")
                        .font(.fiesta(12))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Tema.teal)

            Button(role: .destructive) { viewModel.confirmarBorrado = true } label: {
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
}

#Preview("Crear") {
    let store = DatosEjemplo.store()
    return NavigationStack {
        EventoEditorView(eventoID: nil, store: store)
    }
    .environmentObject(store)
    .environmentObject(Navegador())
}

#Preview("Editar") {
    let store = DatosEjemplo.store()
    return NavigationStack {
        EventoEditorView(eventoID: DatosEjemplo.eventoConGastos(en: store), store: store)
    }
    .environmentObject(store)
    .environmentObject(Navegador())
}
