//  GastoEditorView.swift
//  Fiestapp

import SwiftUI

struct GastoEditorView: View {
    @EnvironmentObject private var navegador: Navegador
    @EnvironmentObject private var store: FiestappStore
    @StateObject private var viewModel: GastoEditorViewModel

    init(eventoID: UUID, gastoID: UUID?, store: FiestappStore) {
        _viewModel = StateObject(wrappedValue: GastoEditorViewModel(eventoID: eventoID, gastoID: gastoID, store: store))
    }

    var body: some View {
        PantallaFiesta(barra: [
            BotonBarra(titulo: "Detalles", icono: "arrow.left") { navegador.atras() },
            BotonBarra(titulo: "Ticket", icono: "paperclip", activo: true),
            BotonBarra(titulo: "Listo", icono: "checkmark", deshabilitado: viewModel.cerrado) {
                if viewModel.guardar() { navegador.atras() }
            }
        ]) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.esNuevo ? "Registrar Gasto" : "Editar Gasto").font(.fiesta(13))
                    Text("Ticket").font(.fiesta(30, .medium))
                }
                Spacer()
                if !viewModel.esNuevo && !viewModel.cerrado {
                    Button { viewModel.confirmarBorrado = true } label: {
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
            .disabled(viewModel.cerrado)
        }
        .task { await viewModel.cargarSugerencias() }
        .sheet(isPresented: $viewModel.agregandoInvitado) {
            ElegirInvitadosSheet(store: store, yaInvitados: viewModel.personas.map(\.nombre)) { nuevos in
                viewModel.agregarInvitados(nuevos)
            }
        }
        .sheet(isPresented: $viewModel.verFotoCompleta) {
            if let foto = viewModel.foto, let ui = UIImage(data: foto) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Revisa el gasto", isPresented: Binding(
            get: { viewModel.alerta != nil },
            set: { if !$0 { viewModel.alerta = nil } }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(viewModel.alerta ?? "")
        }
        .confirmationDialog("¿Eliminar este gasto?", isPresented: $viewModel.confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar gasto", role: .destructive) {
                viewModel.eliminar()
                navegador.atras()
            }
        }
    }

    private var divisor: some View {
        Rectangle().fill(Tema.teal).frame(height: 2).padding(.vertical, 14)
    }

    // MARK: - Formulario

    private var formulario: some View {
        VStack(spacing: 4) {
            Rectangle().fill(Tema.teal).frame(height: 2).padding(.bottom, 8)
            fila("Concepto") {
                TextField("Comida", text: $viewModel.concepto)
                    .multilineTextAlignment(.trailing)
            }
            SugerenciasView(estado: viewModel.sugerencias,
                            elegir: { viewModel.usarSugerencia($0) },
                            reintentar: { Task { await viewModel.cargarSugerencias() } })
                .padding(.vertical, 4)
            fila("Monto") {
                HStack(spacing: 2) {
                    Text("$")
                        .foregroundStyle(viewModel.montoTexto.isEmpty ? Color.secondary : Tema.texto)
                    TextField("0", text: $viewModel.montoTexto)
                        .keyboardType(.decimalPad)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: 30, alignment: .leading)
                }
            }
            fila("Fecha") {
                DatePicker("Fecha", selection: $viewModel.fecha, displayedComponents: .date)
                    .labelsHidden()
            }
            fila("Fecha límite de pago") {
                DatePicker("Fecha límite de pago", selection: $viewModel.fechaLimite, displayedComponents: .date)
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

    // MARK: - División

    private var seccionDivision: some View {
        VStack(spacing: 12) {
            Text("¿Entre quiénes se divide?")
                .font(.fiesta(18, .medium))
                .foregroundStyle(Tema.texto)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    BotonMas(tamano: 46) { viewModel.agregandoInvitado = true }
                    ForEach(viewModel.personas) { persona in
                        let activo = viewModel.seleccionados.contains(persona.id)
                        Button { viewModel.alternar(persona) } label: {
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

            Picker("División", selection: $viewModel.division) {
                ForEach(TipoDivision.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if viewModel.division == .iguales {
                if let texto = viewModel.textoPorPersona {
                    Text(texto)
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
            ForEach(viewModel.elegidos) { persona in
                HStack {
                    AvatarView(persona, tamano: 28)
                    Text(persona.nombre).font(.fiesta(14))
                    Spacer()
                    HStack(spacing: 2) {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: Binding(
                            get: { viewModel.montosPersonalizados[persona.id] ?? "" },
                            set: { viewModel.montosPersonalizados[persona.id] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                    }
                    .font(.fiesta(14))
                    .frame(width: 90)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                }
            }
            let restante = viewModel.restantePersonalizado
            Text(restante == 0 ? "¡Cuadra exacto!" : "Faltan por asignar \(Dinero.texto(restante))")
                .font(.fiesta(13, .medium))
                .foregroundStyle(restante == 0 ? Tema.tealOscuro : .orange)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Pagador

    private var seccionPagador: some View {
        VStack(spacing: 12) {
            Text("¿Quién pagó?")
                .font(.fiesta(18, .medium))
                .foregroundStyle(Tema.texto)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(viewModel.personas) { persona in
                        let activo = viewModel.pagadorID == persona.id
                        Button { viewModel.pagadorID = persona.id } label: {
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

    // MARK: - Recibo

    private var seccionRecibo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recibo")
                .font(.fiesta(17, .medium))
                .foregroundStyle(Tema.texto)
                .padding(.horizontal, 20)

            HStack {
                Spacer()
                if let foto = viewModel.foto, let ui = UIImage(data: foto) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { viewModel.verFotoCompleta = true }
                        .overlay(alignment: .bottomTrailing) {
                            SelectorFoto(foto: $viewModel.foto, permitirEscaner: true, ajuste: .libre) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, Tema.teal)
                                    .padding(6)
                            }
                        }
                } else {
                    SelectorFoto(foto: $viewModel.foto, permitirEscaner: true, ajuste: .libre) {
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
}

#Preview("Nuevo") {
    let store = DatosEjemplo.store()
    return NavigationStack {
        GastoEditorView(eventoID: DatosEjemplo.eventoConGastos(en: store), gastoID: nil, store: store)
    }
    .environmentObject(store)
    .environmentObject(Navegador())
}

#Preview("Editar") {
    let store = DatosEjemplo.store()
    let evento = store.evento(DatosEjemplo.eventoConGastos(en: store))
    return NavigationStack {
        GastoEditorView(eventoID: evento?.id ?? UUID(), gastoID: evento?.gastosOrdenados.first?.id, store: store)
    }
    .environmentObject(store)
    .environmentObject(Navegador())
}
