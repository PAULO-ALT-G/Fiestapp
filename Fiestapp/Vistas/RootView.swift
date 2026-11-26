//  RootView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var perfiles: [Perfil]
    @State private var navegador = Navegador()

    var body: some View {
        if let perfil = perfiles.first {
            NavigationStack(path: $navegador.ruta) {
                InicioView(perfil: perfil)
                    .navigationDestination(for: Ruta.self) { ruta in
                        switch ruta {
                        case .detalle(let evento):
                            EventoDetalleView(evento: evento)
                        case .editarEvento(let evento):
                            EventoEditorView(evento: evento, perfil: perfil)
                        case .gasto(let evento, let gasto):
                            GastoEditorView(evento: evento, gasto: gasto)
                        case .amigos:
                            AmigosView()
                        }
                    }
            }
            .environment(navegador)
        } else {
            PerfilView(perfil: nil)
        }
    }
}

#Preview("Con datos") {
    RootView()
        .modelContainer(DatosEjemplo.contenedor())
}

#Preview("Primera vez") {
    RootView()
        .modelContainer(DatosEjemplo.contenedor(vacio: true))
}
