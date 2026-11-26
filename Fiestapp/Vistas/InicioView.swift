//  InicioView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct InicioView: View {
    let perfil: Perfil

    @Environment(Navegador.self) private var navegador
    @Query(sort: \Evento.fecha) private var eventos: [Evento]

    @Environment(\.scenePhase) private var fase

    @State private var verPasados = false
    @State private var editandoPerfil = false
    @State private var ahora = Date.now

    private let columnas = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var eventosFiltrados: [Evento] {
        if verPasados {
            return eventos
                .filter { $0.esPasado(ahora) }
                .sorted { $0.fin > $1.fin }
        } else {
            return eventos.filter { !$0.esPasado(ahora) }
        }
    }

    var body: some View {
        PantallaFiesta(barra: [
            BotonBarra(titulo: "Crear", icono: "plus") { navegador.ir(.editarEvento(nil)) },
            BotonBarra(titulo: "Activos", icono: "checkmark", activo: !verPasados) {
                withAnimation { verPasados = false }
            },
            BotonBarra(titulo: "Pasados", icono: "clock.arrow.circlepath", activo: verPasados) {
                withAnimation { verPasados = true }
            },
            BotonBarra(titulo: "Amigos", icono: "person.2.fill") { navegador.ir(.amigos) }
        ]) {
            HStack {
                Text(perfil.nombre)
                    .font(.fiesta(30, .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Button { editandoPerfil = true } label: {
                    AvatarView(nombre: perfil.nombre, foto: perfil.foto, tamano: 54)
                }
            }
            .padding(.top, 20)
        } contenido: {
            VStack(spacing: 14) {
                Text(verPasados ? "Pasados" : "Activos")
                    .font(.fiesta(14))
                    .foregroundStyle(Tema.texto.opacity(0.7))
                    .frame(maxWidth: .infinity)

                if eventosFiltrados.isEmpty {
                    estadoVacio
                } else {
                    LazyVGrid(columns: columnas, spacing: 12) {
                        ForEach(eventosFiltrados) { evento in
                            Button { navegador.ir(.detalle(evento)) } label: {
                                TarjetaEvento(evento: evento)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
        .sheet(isPresented: $editandoPerfil) {
            PerfilView(perfil: perfil)
        }
        .onAppear { ahora = .now }
        .onChange(of: fase) { _, nuevaFase in
            if nuevaFase == .active { ahora = .now }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                ahora = .now
            }
        }
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: verPasados ? "archivebox" : "party.popper")
                .font(.system(size: 44))
                .foregroundStyle(Tema.teal)
            Text(verPasados ? "Aún no tienes eventos pasados" : "No tienes eventos activos")
                .font(.fiesta(16, .medium))
            if !verPasados {
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
    let contenedor = DatosEjemplo.contenedor()
    return NavigationStack {
        InicioView(perfil: DatosEjemplo.perfil(en: contenedor))
    }
    .environment(Navegador())
    .modelContainer(contenedor)
}
