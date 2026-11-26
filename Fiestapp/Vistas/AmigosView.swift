//  AmigosView.swift
//  Fiestapp

import SwiftUI
import SwiftData

struct AmigosView: View {
    @Environment(Navegador.self) private var navegador
    @Environment(\.modelContext) private var contexto

    @Query(sort: \Amigo.nombre) private var amigos: [Amigo]

    @State private var agregando = false
    @State private var editando: Amigo?
    @State private var busqueda = ""

    private let columnas = [GridItem(.adaptive(minimum: 84), spacing: 12)]

    private var filtrados: [Amigo] {
        let texto = busqueda.limpio
        guard !texto.isEmpty else { return amigos }
        return amigos.filter { $0.nombre.localizedCaseInsensitiveContains(texto) }
    }

    var body: some View {
        PantallaFiesta(barra: [
            BotonBarra(titulo: "Inicio", icono: "arrow.left") { navegador.atras() },
            BotonBarra(titulo: "Amigos", icono: "person.2.fill", activo: true) {},
            BotonBarra(titulo: "Agregar", icono: "person.badge.plus") { agregando = true }
        ]) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Mis").font(.fiesta(13))
                Text("Amigos").font(.fiesta(30, .medium))
            }
            .foregroundStyle(.white)
            .padding(.top, 20)
        } contenido: {
            VStack(spacing: 14) {
                Text(amigos.count == 1 ? "1 amigo" : "\(amigos.count) amigos")
                    .font(.fiesta(14))
                    .foregroundStyle(Tema.texto.opacity(0.7))
                    .frame(maxWidth: .infinity)

                if amigos.isEmpty {
                    estadoVacio
                } else {
                    buscador

                    LazyVGrid(columns: columnas, spacing: 16) {
                        ForEach(filtrados) { amigo in
                            Button { editando = amigo } label: {
                                VStack(spacing: 6) {
                                    AvatarView(nombre: amigo.nombre, foto: amigo.foto, tamano: 64, borde: Tema.teal)
                                    Text(amigo.nombre)
                                        .font(.fiesta(13, .medium))
                                        .foregroundStyle(Tema.texto)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }

                        Button { agregando = true } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Circle().fill(Tema.tealOscuro))
                                Text("Agregar")
                                    .font(.fiesta(13, .medium))
                                    .foregroundStyle(Tema.tealOscuro)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    Text("Toca a un amigo para cambiar su nombre o foto, o para quitarlo.")
                        .font(.fiesta(12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $agregando) {
            InvitadoSheet(titulo: "Nuevo amigo", nombre: "", foto: nil,
                          alGuardar: { nombre, foto in
                              contexto.insert(Amigo(nombre: nombre, foto: foto))
                              try? contexto.save()
                          },
                          textoCampo: "Nombre de tu amigo")
        }
        .sheet(item: $editando) { amigo in
            InvitadoSheet(titulo: "Editar amigo", nombre: amigo.nombre, foto: amigo.foto,
                          alGuardar: { nombre, foto in
                              amigo.nombre = nombre
                              amigo.foto = foto
                              try? contexto.save()
                          },
                          alEliminar: {
                              contexto.delete(amigo)
                              try? contexto.save()
                          },
                          textoEliminar: "Quitar de mis amigos",
                          textoCampo: "Nombre de tu amigo")
        }
    }

    private var buscador: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Tema.teal)
            TextField("Buscar amigo", text: $busqueda)
            if !busqueda.isEmpty {
                Button { busqueda = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .font(.fiesta(15))
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
        .padding(.horizontal, 16)
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 48))
                .foregroundStyle(Tema.teal)
            Text("Aún no tienes amigos guardados")
                .font(.fiesta(16, .medium))
            Text("Guárdalos una vez con su nombre y foto, y luego solo los palomeas al invitar.")
                .font(.fiesta(14))
                .foregroundStyle(.secondary)
            Button { agregando = true } label: {
                Label("Agregar amigo", systemImage: "person.badge.plus")
                    .font(.fiesta(15, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Tema.teal))
            }
            .padding(.top, 6)
        }
        .foregroundStyle(Tema.texto)
        .multilineTextAlignment(.center)
        .padding(.vertical, 50)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        AmigosView()
    }
    .environment(Navegador())
    .modelContainer(DatosEjemplo.contenedor())
}
