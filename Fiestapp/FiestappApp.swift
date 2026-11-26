//  FiestappApp.swift
//  Fiestapp

import SwiftUI
import SwiftData

@main
struct FiestappApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Tema.teal)
        }
        .modelContainer(for: [
            Perfil.self,
            Amigo.self,
            Evento.self,
            Participante.self,
            Gasto.self,
            Parte.self,
            Pago.self
        ])
    }
}
