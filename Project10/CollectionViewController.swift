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
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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

        let alertController = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak alertController] _ in
            guard let newName = alertController?.textFields?[0].text else {
                return
            }

            person.name = newName
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
