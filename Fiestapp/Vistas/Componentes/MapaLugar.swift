//  MapaLugar.swift
//  Fiestapp

import SwiftUI
import MapKit

private let centroCDMX = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)

struct MapaLugar: View {
    let lugar: String
    let latitud: Double?
    let longitud: Double?
    var alto: CGFloat = 180

    @Environment(\.openURL) private var abrirURL

    private var coordenada: CLLocationCoordinate2D? {
        guard let latitud, let longitud else { return nil }
        return CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let coordenada {
                Map(initialPosition: .region(MKCoordinateRegion(center: coordenada, latitudinalMeters: 1500, longitudinalMeters: 1500)),
                    interactionModes: []) {
                    Marker(lugar, coordinate: coordenada)
                        .tint(Tema.teal)
                    MapCircle(center: coordenada, radius: 350)
                        .foregroundStyle(Tema.teal.opacity(0.15))
                        .stroke(Tema.tealOscuro, lineWidth: 1)
                }
                .id("\(coordenada.latitude),\(coordenada.longitude)")
            } else {
                Map(initialPosition: .region(MKCoordinateRegion(center: centroCDMX, latitudinalMeters: 30000, longitudinalMeters: 30000)),
                    interactionModes: [])
            }

            LinearGradient(colors: [.clear, Tema.teal.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)

            Text(lugar.isEmpty ? "Calle y número" : lugar)
                .font(.fiesta(16, .semibold))
                .foregroundStyle(.white)
                .padding(12)
        }
        .frame(height: alto)
        .contentShape(Rectangle())
        .onTapGesture { abrirEnMapas() }
    }

    private func abrirEnMapas() {
        guard let coordenada else { return }
        let nombre = lugar.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://maps.apple.com/?ll=\(coordenada.latitude),\(coordenada.longitude)&q=\(nombre)") {
            abrirURL(url)
        }
    }
}

struct BuscadorLugar: View {
    @Binding var lugar: String
    @Binding var latitud: Double?
    @Binding var longitud: Double?

    @State private var texto = ""
    @State private var resultados: [MKMapItem] = []
    @State private var buscando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MapaLugar(lugar: lugar, latitud: latitud, longitud: longitud)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Tema.teal)
                TextField("Busca la calle y número", text: $texto)
                    .submitLabel(.search)
                    .onSubmit { Task { await buscar() } }
                if buscando {
                    ProgressView()
                } else if !texto.isEmpty {
                    Button("Buscar") { Task { await buscar() } }
                        .font(.fiesta(14, .medium))
                }
            }
            .font(.fiesta(15))
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white))
            .padding(.horizontal, 16)

            if !resultados.isEmpty || (!texto.isEmpty && !buscando) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(resultados, id: \.self) { item in
                        Button { elegir(item) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Sin nombre")
                                    .font(.fiesta(14, .medium))
                                Text(item.address?.shortAddress ?? item.address?.fullAddress ?? "")
                                    .font(.fiesta(12))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                    if !texto.isEmpty {
                        Button {
                            lugar = texto.limpio
                            latitud = nil
                            longitud = nil
                            limpiar()
                        } label: {
                            Label("Usar \"\(texto.limpio)\" sin mapa", systemImage: "text.cursor")
                                .font(.fiesta(13))
                                .padding(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .foregroundStyle(Tema.texto)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                .padding(.horizontal, 16)
            }
        }
    }

    private func buscar() async {
        let consulta = texto.limpio
        guard !consulta.isEmpty else { return }
        let peticion = MKLocalSearch.Request()
        peticion.naturalLanguageQuery = consulta
        peticion.region = MKCoordinateRegion(center: centroCDMX, latitudinalMeters: 60000, longitudinalMeters: 60000)
        buscando = true
        let respuesta = try? await MKLocalSearch(request: peticion).start()
        resultados = Array((respuesta?.mapItems ?? []).prefix(5))
        buscando = false
    }

    private func elegir(_ item: MKMapItem) {
        let coordenada = item.location.coordinate
        latitud = coordenada.latitude
        longitud = coordenada.longitude
        lugar = item.name ?? texto.limpio
        limpiar()
    }

    private func limpiar() {
        texto = ""
        resultados = []
    }
}
