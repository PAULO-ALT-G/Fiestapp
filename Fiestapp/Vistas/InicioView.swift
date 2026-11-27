//  InicioView.swift
//  Fiestapp

import SwiftUI

struct InicioView: View {
    @EnvironmentObject private var store: FiestappStore
    @StateObject private var viewModel = InicioViewModel()
    @Environment(\.scenePhase) private var fase

    private let columnas = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let eventos = viewModel.eventosVisibles(de: store.eventos)

        PantallaFiesta(barra: [
            BotonBarra(titulo: "Crear", icono: "plus", destino: .editarEvento(nil)),
            BotonBarra(titulo: "Activos", icono: "checkmark", activo: !viewModel.verPasados) {
                withAnimation { viewModel.verPasados = false }
            },
            BotonBarra(titulo: "Pasados", icono: "clock.arrow.circlepath", activo: viewModel.verPasados) {
                withAnimation { viewModel.verPasados = true }
            },
            BotonBarra(titulo: "Amigos", icono: "person.2.fill", destino: .amigos)
        ]) {
            HStack {
                Text(store.perfil?.nombre ?? "")
                    .font(.fiesta(30, .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Button { viewModel.editandoPerfil = true } label: {
                    AvatarView(nombre: store.perfil?.nombre ?? "", foto: store.perfil?.foto, tamano: 54)
                }
            }
            .padding(.top, 20)
        } contenido: {
            VStack(spacing: 14) {
                Text(viewModel.tituloSeccion)
                    .font(.fiesta(14))
                    .foregroundStyle(Tema.texto.opacity(0.7))
                    .frame(maxWidth: .infinity)

                if eventos.isEmpty {
                    estadoVacio
                } else {
                    LazyVGrid(columns: columnas, spacing: 12) {
                        ForEach(eventos) { evento in
                            NavigationLink(value: Ruta.detalle(evento.id)) {
                                TarjetaEvento(evento: evento)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
        .sheet(isPresented: $viewModel.editandoPerfil) {
            PerfilView(store: store)
        }
        .onAppear { viewModel.actualizarHora() }
        .onChange(of: fase) { _, nuevaFase in
            if nuevaFase == .active { viewModel.actualizarHora() }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                viewModel.actualizarHora()
            }
        }
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.verPasados ? "archivebox" : "party.popper")
                .font(.system(size: 44))
                .foregroundStyle(Tema.teal)
            Text(viewModel.mensajeVacio)
                .font(.fiesta(16, .medium))
            if !viewModel.verPasados {
                Text("Toca **Crear** para organizar tu primera salida.")
                    .font(.fiesta(14))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Tema.texto)
        .multilineTextAlignment(.center)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tarjeta de evento

struct TarjetaEvento: View {
    let evento: Evento

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(evento.nombre)
                    .font(.fiesta(15, .semibold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Tema.teal)

            Color.clear
                .frame(height: 120)
                .overlay {
                    if let portada = evento.portada, let ui = UIImage(data: portada) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            LinearGradient(colors: [Tema.teal.opacity(0.55), Tema.tealOscuro],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                            Image(systemName: evento.tipo.icono)
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .clipped()
                .overlay(alignment: .bottom) {
                    HStack {
                        Text(Formato.diaMes(evento.fecha))
                        Spacer()
                        Label("\(evento.participantes.count)", systemImage: "person.2.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .font(.fiesta(12, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Tema.teal.opacity(0.85))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Tema.teal, lineWidth: 2))
        .overlay(alignment: .topTrailing) {
            if evento.totalCentavos > 0 {
                Text(Dinero.texto(evento.totalCentavos))
                    .font(.fiesta(11, .semibold))
                    .foregroundStyle(Tema.tealOscuro)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white.opacity(0.9)))
                    .padding(.top, 40)
                    .padding(.trailing, 8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        InicioView()
    }
    .environmentObject(DatosEjemplo.store())
    .environmentObject(Navegador())
}
