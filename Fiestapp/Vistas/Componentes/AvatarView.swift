//  AvatarView.swift
//  Fiestapp

import SwiftUI

struct AvatarView: View {
    let nombre: String
    let foto: Data?
    var tamano: CGFloat = 40
    var borde: Color = .white

    var body: some View {
        Group {
            if let foto, let ui = UIImage(data: foto) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    color
                    Text(iniciales)
                        .font(.fiesta(tamano * 0.38, .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: tamano, height: tamano)
        .clipShape(Circle())
        .overlay(Circle().stroke(borde, lineWidth: tamano > 30 ? 2 : 1))
    }

    private var iniciales: String {
        let partes = nombre.split(separator: " ").prefix(2)
        let letras = partes.compactMap { $0.first }.map { String($0) }.joined()
        return letras.isEmpty ? "?" : letras.uppercased()
    }

    private var color: Color {
        let suma = nombre.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Tema.coloresAvatar[suma % Tema.coloresAvatar.count]
    }
}

extension AvatarView {
    init(_ persona: Participante, tamano: CGFloat = 40, borde: Color = .white) {
        self.init(nombre: persona.nombre, foto: persona.foto, tamano: tamano, borde: borde)
    }
}

struct AvataresApilados: View {
    let personas: [Participante]
    var tamano: CGFloat = 40
    var maximo: Int = 6

    var body: some View {
        HStack(spacing: -tamano * 0.35) {
            ForEach(personas.prefix(maximo)) { persona in
                AvatarView(persona, tamano: tamano)
            }
            if personas.count > maximo {
                ZStack {
                    Circle().fill(Tema.tealOscuro)
                    Text("+\(personas.count - maximo)")
                        .font(.fiesta(tamano * 0.32, .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: tamano, height: tamano)
                .overlay(Circle().stroke(.white, lineWidth: 2))
            }
        }
    }
}

struct BotonMas: View {
    var tamano: CGFloat = 44
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Image(systemName: "plus")
                .font(.system(size: tamano * 0.5, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: tamano, height: tamano)
                .background(Circle().fill(Tema.tealOscuro))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(nombre: "Santiago B.", foto: nil, tamano: 60)
        HStack {
            BotonMas {}
            AvatarView(nombre: "Kiara", foto: nil)
            AvatarView(nombre: "Paulo", foto: nil)
        }
    }
    .padding()
    .background(Tema.fondo)
}
