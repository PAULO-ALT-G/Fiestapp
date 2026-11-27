//  RootView.swift
//  Fiestapp

import SwiftUI

struct RootView: View {
    @StateObject private var store: FiestappStore
    @StateObject private var navegador = Navegador()
    @State private var mostrarBienvenida = true

    init(store: FiestappStore = FiestappStore()) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        Group {
            if mostrarBienvenida {
                CargandoView(mensaje: "Cargando tus eventos…")
                    .transition(.opacity)
            } else {
                contenido
            }
        }
        .environmentObject(store)
        .environmentObject(navegador)
        .task {
            if store.estado == .cargando { store.cargar() }
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.3)) { mostrarBienvenida = false }
        }
        .alert("No se pudo guardar", isPresented: Binding(
            get: { store.errorGuardado != nil },
            set: { if !$0 { store.errorGuardado = nil } }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(store.errorGuardado ?? "")
        }
    }

    @ViewBuilder
    private var contenido: some View {
        Group {
            switch store.estado {
            case .cargando:
                CargandoView(mensaje: "Cargando tus eventos…")
            case .error(let mensaje):
                ErrorDatosView(mensaje: mensaje,
                               reintentar: { store.cargar() },
                               empezarDeCero: { store.empezarDeCero() })
            case .listo:
                if store.perfil == nil {
                    PerfilView(store: store)
                } else {
                    NavigationStack(path: $navegador.ruta) {
                        InicioView()
                            .navigationDestination(for: Ruta.self) { ruta in
                                destino(ruta)
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destino(_ ruta: Ruta) -> some View {
        switch ruta {
        case .detalle(let id):
            EventoDetalleView(eventoID: id, store: store)
        case .editarEvento(let id):
            EventoEditorView(eventoID: id, store: store)
        case .gasto(let eventoID, let gastoID):
            GastoEditorView(eventoID: eventoID, gastoID: gastoID, store: store)
        case .amigos:
            AmigosView(store: store)
        }
    }
}

#Preview("Con datos") {
    RootView(store: DatosEjemplo.store())
}

#Preview("Primera vez") {
    RootView(store: DatosEjemplo.store(vacio: true, sinPerfil: true))
}
