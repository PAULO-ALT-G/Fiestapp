//  EventoDetalleView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct EventoDetalleView: View {
    @Bindable var evento: Evento

    @Environment(Navegador.self) private var navegador
    @Environment(\.modelContext) private var contexto

    @State private var agregandoInvitado = false

    var body: some View {
        PantallaFiesta(imagen: evento.portada, barra: [
            BotonBarra(titulo: "Inicio", icono: "arrow.left") { navegador.inicio() },
            BotonBarra(titulo: "Evento", icono: evento.tipo.icono, activo: true) {},
            BotonBarra(titulo: "Editar", icono: "pencil") { navegador.ir(.editarEvento(evento)) }
        ]) {
            encabezado
        } contenido: {
            VStack(alignment: .leading, spacing: 18) {
                if evento.cerrado || evento.esPasado() {
                    Label(evento.cerrado ? "Cuentas cerradas" : "Este evento ya pasó",
                          systemImage: evento.cerrado ? "lock.fill" : "clock.arrow.circlepath")
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

                invitados

                ListaGastos(evento: evento)
                BalanceGrupo(evento: evento)

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
        .sheet(isPresented: $agregandoInvitado) {
            ElegirInvitadosSheet(yaInvitados: evento.participantes.map(\.nombre)) { nuevos in
                for nuevo in nuevos {
                    let persona = Participante(nombre: nuevo.nombre, foto: nuevo.foto)
                    contexto.insert(persona)
                    persona.evento = evento
                }
                try? contexto.save()
            }
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Detalles").font(.fiesta(13))
                Spacer()
                Button { navegador.ir(.editarEvento(evento)) } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
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
                Text("Inicio: \(Formato.diaMesLargo(evento.fecha)) · \(Formato.hora(evento.fecha))")
                if evento.fin > evento.fecha {
                    Text("Fin: \(Formato.diaMesLargo(evento.fin)) · \(Formato.hora(evento.fin))")
                }
            }
            .font(.fiesta(15, .semibold))
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
    }

    private var invitados: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invitados:")
                .font(.fiesta(17, .medium))
                .foregroundStyle(Tema.texto)
            HStack(spacing: 8) {
                if !evento.cerrado {
                    BotonMas { agregandoInvitado = true }
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
    let contenedor = DatosEjemplo.contenedor()
    return NavigationStack {
        EventoDetalleView(evento: DatosEjemplo.evento(en: contenedor))
    }
    .environment(Navegador())
    .modelContainer(contenedor)
}
