//  EventoDetalleView.swift
//  Fiestapp

import SwiftUI

struct EventoDetalleView: View {
    @EnvironmentObject private var navegador: Navegador
    @EnvironmentObject private var store: FiestappStore
    @StateObject private var viewModel: EventoDetalleViewModel

    init(eventoID: UUID, store: FiestappStore) {
        _viewModel = StateObject(wrappedValue: EventoDetalleViewModel(eventoID: eventoID, store: store))
    }

    var body: some View {
        if let evento = viewModel.evento {
            contenido(evento)
        } else {
            ContentUnavailableView("Este evento ya no existe", systemImage: "calendar.badge.exclamationmark")
        }
    }

    private func contenido(_ evento: Evento) -> some View {
        PantallaFiesta(imagen: evento.portada, barra: [
            BotonBarra(titulo: "Inicio", icono: "arrow.left") { navegador.inicio() },
            BotonBarra(titulo: "Evento", icono: evento.tipo.icono, activo: true),
            BotonBarra(titulo: "Editar", icono: "pencil", destino: .editarEvento(evento.id))
        ]) {
            encabezado(evento)
        } contenido: {
            VStack(alignment: .leading, spacing: 18) {
                if let estado = viewModel.estado(de: evento) {
                    Label(estado, systemImage: evento.cerrado ? "lock.fill" : "clock.arrow.circlepath")
                        .font(.fiesta(14, .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Tema.tealOscuro))
                        .frame(maxWidth: .infinity)
                }

                EncabezadoSeccion("Detalles:")
                Text(evento.detalles.isEmpty ? "Sin detalles." : evento.detalles)
                    .font(.fiesta(15))
                    .foregroundStyle(evento.detalles.isEmpty ? .secondary : Tema.texto)
                    .padding(.horizontal, 20)

                EncabezadoSeccion("Lugar:")
                MapaLugar(lugar: evento.lugar, latitud: evento.latitud, longitud: evento.longitud)
                LineaSeccion()

                invitados(evento)

                ListaGastos(evento: evento)
                BalanceGrupo(evento: evento, acciones: AccionesCuentas(
                    alternarParte: { gastoID, personaID in viewModel.alternarParte(gastoID: gastoID, participanteID: personaID) },
                    saldar: { viewModel.saldar($0) },
                    deshacerPago: { viewModel.deshacerPago($0) }
                ))

                ShareLink(item: Balance.resumen(evento)) {
                    Label("Compartir cuentas", systemImage: "square.and.arrow.up")
                        .font(.fiesta(15, .medium))
                        .foregroundStyle(Tema.tealOscuro)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Tema.teal, lineWidth: 1.5))
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $viewModel.agregandoInvitado) {
            ElegirInvitadosSheet(store: store, yaInvitados: evento.participantes.map(\.nombre)) { nuevos in
                viewModel.agregarInvitados(nuevos)
            }
        }
    }

    private func encabezado(_ evento: Evento) -> some View {
        let fechas = viewModel.textoFecha(evento)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Detalles").font(.fiesta(13))
                Spacer()
                NavigationLink(value: Ruta.editarEvento(evento.id)) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            Text(evento.nombre)
                .font(.fiesta(30, .medium))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Label(evento.tipo.rawValue, systemImage: evento.tipo.icono)
                .font(.fiesta(13, .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.white.opacity(0.2)))
            VStack(alignment: .leading, spacing: 0) {
                Text("Organizador:").font(.fiesta(13))
                Text(evento.organizador?.nombre ?? "—").font(.fiesta(16, .semibold))
            }
            .padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(fechas.inicio)
                if let fin = fechas.fin {
                    Text(fin)
                }
            }
            .font(.fiesta(15, .semibold))
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
    }

    private func invitados(_ evento: Evento) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invitados:")
                .font(.fiesta(17, .medium))
                .foregroundStyle(Tema.texto)
            HStack(spacing: 8) {
                if !evento.cerrado {
                    BotonMas { viewModel.agregandoInvitado = true }
                }
                AvataresApilados(personas: evento.participantesOrdenados, tamano: 44, maximo: 7)
                Spacer()
                Text("\(evento.participantes.count)")
                    .font(.fiesta(14, .semibold))
                    .foregroundStyle(Tema.tealOscuro)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    let store = DatosEjemplo.store()
    return NavigationStack {
        EventoDetalleView(eventoID: DatosEjemplo.eventoConGastos(en: store), store: store)
    }
    .environmentObject(store)
    .environmentObject(Navegador())
}
