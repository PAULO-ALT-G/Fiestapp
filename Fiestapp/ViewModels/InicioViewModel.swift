//  InicioViewModel.swift
//  Fiestapp

import Foundation
import Combine

final class InicioViewModel: ObservableObject {
    @Published var verPasados = false
    @Published var editandoPerfil = false
    @Published private(set) var ahora = Date.now

    func actualizarHora() {
        ahora = .now
    }

    func eventosVisibles(de eventos: [Evento]) -> [Evento] {
        if verPasados {
            return eventos
                .filter { $0.esPasado(ahora) }
                .sorted { $0.fin > $1.fin }
        }
        return eventos
            .filter { !$0.esPasado(ahora) }
            .sorted { $0.fecha < $1.fecha }
    }

    var tituloSeccion: String {
        verPasados ? "Pasados" : "Activos"
    }

    var mensajeVacio: String {
        verPasados ? "Aún no tienes eventos pasados" : "No tienes eventos activos"
    }
}
