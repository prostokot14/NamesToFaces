//
//  CollectionViewController.swift
//  Project10
//
//  Created by Антон Кашников on 11.06.2023.
//

import UIKit
import PhotosUI

final class CollectionViewController: UICollectionViewController {
    // MARK: - Private Properties
    private var people = [Person]()

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Names to Faces"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
        
        if let savedPeople = UserDefaults.standard.object(forKey: "people") as? Data {
            do {
                people = try JSONDecoder().decode([Person].self, from: savedPeople)
            } catch {
                print("Failes to load people.")
            }
        }
    }

    // MARK: - Private Methods
    @objc private func addNewPerson() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Take photo", style: .default) { [weak self] _ in
            self?.makeImagePickerController(with: .camera)
        })
        alertController.addAction(UIAlertAction(title: "Photo library", style: .default) { [weak self] _ in
            if #available(iOS 14.0, *) {
                self?.makePickerViewController()
            } else {
                self?.makeImagePickerController(with: .photoLibrary)
            }
        })
        present(alertController, animated: true)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    @available(iOS 14.0, *)
    private func makePickerViewController() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images

        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }

    private func makeImagePickerController(with sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            return
        }
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }

    private func saveImage(_ image: UIImage) {
        let imageName = UUID().uuidString
        let imagePath: URL

        if #available(iOS 16.0, *) {
            imagePath = getDocumentsDirectory().appending(path: imageName)
        } else {
            imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        }

        if let jpegData = image.jpegData(compressionQuality: 1) {
            try? jpegData.write(to: imagePath)
        }

        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        saveData()
        collectionView.reloadData()
    }

    private func croppedImage(_ image: UIImage) -> UIImage {
        // The shortest side
        let sideLength = min(image.size.width, image.size.height)

        // Determines the x,y coordinate of a centered sideLength by sideLength square
        let sourceSize = image.size
        let xOffset = (sourceSize.width - sideLength) / 2
        let yOffset = (sourceSize.height - sideLength) / 2

        // The cropRect is the rect of the image to keep, in this case centered
        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength).integral

        // Center crop the image
        let sourceCGImage = image.cgImage
        guard let croppedCGImage = sourceCGImage?.cropping(to: cropRect) else {
            return UIImage()
        }
        return UIImage(cgImage: croppedCGImage)
    }
    
    private func saveData() {
        if let savedData = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(savedData, forKey: "people")
        } else {
            print("Failed to save people.")
        }
    }
}

// MARK: - UICollectionViewController
extension CollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        people.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
            fatalError("Unable to dequeue PersonCell.")
        }

        let person = people[indexPath.item]
        cell.nameLabel.text = person.name

        let imagePath: URL
        if #available(iOS 16.0, *) {
            imagePath = getDocumentsDirectory().appending(path: person.image)
            cell.imageView.image = UIImage(contentsOfFile: imagePath.path())
        } else {
            imagePath = getDocumentsDirectory().appendingPathComponent(person.image)
            cell.imageView.image = UIImage(contentsOfFile: imagePath.path)
        }

        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "What do you want to do?", message: "Rename the picture or delete the person?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            let renameAlertController = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
            renameAlertController.addTextField()
            renameAlertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak renameAlertController] _ in
                guard let self, let newName = renameAlertController?.textFields?[0].text else {
                    return
                }

                self.people[indexPath.item].name = newName
                self.saveData()
                self.collectionView.reloadData()
            })
            renameAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            self?.present(renameAlertController, animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Delete", style: .default) { [weak self] _ in
            self?.people.remove(at: indexPath.item)
            self?.saveData()
            self?.collectionView.reloadData()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension CollectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        saveImage(image)
        dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14.0, *)
extension CollectionViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider else {
            return
        }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                DispatchQueue.main.async {
                    if let image = object as? UIImage, let croppedImage = self?.croppedImage(image) {
                        self?.saveImage(croppedImage)
                    } else if error != nil {
                        self?.saveImage(UIImage(systemName: "exclamationmark.circle") ?? UIImage())
                    }
                }
            }
        }
    }
}
