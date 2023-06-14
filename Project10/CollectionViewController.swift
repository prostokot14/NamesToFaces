//
//  CollectionViewController.swift
//  Project10
//
//  Created by Антон Кашников on 11.06.2023.
//

import UIKit

final class CollectionViewController: UICollectionViewController {
    private var people = [Person]()

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
    }

    // MARK: - Private Methods
    @objc private func addNewPerson() {
        chooseSourceType()
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func chooseSourceType() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Take photo", style: .default) { [weak self] _ in
            self?.makeImagePickerController(with: .camera)
        })
        alertController.addAction(UIAlertAction(title: "Photo library", style: .default) { [weak self] _ in
            self?.makeImagePickerController(with: .photoLibrary)
        })
        present(alertController, animated: true)
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
        } else {
            imagePath = getDocumentsDirectory().appendingPathComponent(person.image)
        }

        cell.imageView.image = UIImage(contentsOfFile: imagePath.path)
        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]

        let alertController = UIAlertController(title: "What do you want to do?", message: "Rename the picture or delete the person?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            let renameAlertController = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
            renameAlertController.addTextField()
            renameAlertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak renameAlertController] _ in
                guard let newName = renameAlertController?.textFields?[0].text else {
                    return
                }

                person.name = newName
                self?.collectionView.reloadData()
            })
            renameAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            self?.present(renameAlertController, animated: true)
        })
        alertController.addAction(UIAlertAction(title: "Delete", style: .default) { [weak self] _ in
            self?.people.remove(at: indexPath.item)
            self?.collectionView.reloadData()
        })
        present(alertController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension CollectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return
        }

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
        collectionView.reloadData()

        dismiss(animated: true)
    }
}
