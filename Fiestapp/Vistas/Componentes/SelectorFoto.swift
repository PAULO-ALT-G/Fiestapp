//  SelectorFoto.swift
//  Fiestapp

import SwiftUI
import PhotosUI
import UIKit
import VisionKit

struct SelectorFoto<Etiqueta: View>: View {
    @Binding var foto: Data?
    var permitirCamara: Bool = true
    var permitirEscaner: Bool = false
    var ajuste: AjusteImagen? = nil
    @ViewBuilder let etiqueta: () -> Etiqueta

    private enum Hoja: Identifiable {
        case camara
        case escaner
        case ajustar(UIImage)

        var id: String {
            switch self {
            case .camara: "camara"
            case .escaner: "escaner"
            case .ajustar: "ajustar"
            }
        }
    }

    @State private var hoja: Hoja?
    @State private var fotoDeCamara: UIImage?
    @State private var itemGaleria: PhotosPickerItem?
    @State private var mostrarGaleria = false

    private var hayCamara: Bool {
        permitirCamara && UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var hayEscaner: Bool {
        permitirEscaner && VNDocumentCameraViewController.isSupported
    }

    var body: some View {
        Menu {
            if hayCamara {
                Button("Tomar foto", systemImage: "camera") { hoja = .camara }
            }
            Button("Subir foto", systemImage: "photo.on.rectangle") { mostrarGaleria = true }
            if hayEscaner {
                Button("Escanear documento", systemImage: "doc.viewfinder") { hoja = .escaner }
            }
            if let foto, ajuste != nil, let actual = UIImage(data: foto) {
                Button("Ajustar foto actual", systemImage: "crop") { hoja = .ajustar(actual) }
            }
            if foto != nil {
                Button("Quitar foto", systemImage: "trash", role: .destructive) { foto = nil }
            }
        } label: {
            etiqueta()
        }
        .photosPicker(isPresented: $mostrarGaleria, selection: $itemGaleria, matching: .images)
        .fullScreenCover(item: $hoja, onDismiss: {
            if let imagen = fotoDeCamara {
                fotoDeCamara = nil
                recibir(imagen)
            }
        }) { pantalla in
            switch pantalla {
            case .camara:
                CamaraView { imagen in fotoDeCamara = imagen }
                    .ignoresSafeArea()
            case .escaner:
                EscanerView { imagen in foto = Imagenes.comprimir(imagen, maximo: 2000) }
                    .ignoresSafeArea()
            case .ajustar(let imagen):
                vistaAjuste(imagen)
            }
        }
        .onChange(of: itemGaleria) { _, nuevo in
            guard let nuevo else { return }
            Task {
                if let datos = try? await nuevo.loadTransferable(type: Data.self),
                   let imagen = UIImage(data: datos) {
                    try? await Task.sleep(for: .milliseconds(400))
                    recibir(imagen)
                }
                itemGaleria = nil
            }
        }
    }

    @ViewBuilder
    private func vistaAjuste(_ imagen: UIImage) -> some View {
        if let ajuste {
            if ajuste.libre {
                RecorteLibreView(imagen: imagen) { recortada in
                    foto = Imagenes.comprimir(recortada, maximo: 2000)
                }
            } else {
                AjustarImagenView(imagen: imagen, ajuste: ajuste) { recortada in
                    foto = Imagenes.comprimir(recortada)
                }
            }
        }
    }

    private func recibir(_ imagen: UIImage) {
        if ajuste != nil {
            hoja = .ajustar(imagen)
        } else {
            foto = Imagenes.comprimir(imagen)
        }
    }
}

// MARK: - Cámara

struct CamaraView: UIViewControllerRepresentable {
    let alTomarFoto: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(self) }

    final class Coordinador: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let padre: CamaraView

        init(_ padre: CamaraView) { self.padre = padre }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let imagen = info[.originalImage] as? UIImage {
                padre.alTomarFoto(imagen)
            }
            padre.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            padre.dismiss()
        }
    }
}

// MARK: - Escáner de documentos

struct EscanerView: UIViewControllerRepresentable {
    let alTerminar: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let escaner = VNDocumentCameraViewController()
        escaner.delegate = context.coordinator
        return escaner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(self) }

    final class Coordinador: NSObject, VNDocumentCameraViewControllerDelegate {
        let padre: EscanerView

        init(_ padre: EscanerView) { self.padre = padre }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let paginas = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            if let unida = Imagenes.unirVerticalmente(paginas) {
                padre.alTerminar(unida)
            }
            padre.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            padre.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            padre.dismiss()
        }
    }
}
