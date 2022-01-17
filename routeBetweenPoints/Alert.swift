//
//  Alert.swift
//  routeBetweenPoints
//
//  Created by pioner on 17.01.2022.
//

import UIKit

extension UIViewController {
    
    func alertAddAddres(title: String, placeholder: String, completionHandler: @escaping (String) -> Void ) {
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let actionOk = UIAlertAction(title: "Ok", style: .default) { (_) in
            
            let tf = alert.textFields?.first
            guard let text = tf?.text else {return}
            completionHandler(text)
        }
        
        alert.addTextField { (tf) in
            tf.placeholder = placeholder
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) in
        }
        
        alert.addAction(actionOk)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func alertError(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let actionOk = UIAlertAction(title: "Ok", style: .default)
        
        alert.addAction(actionOk)
        
        present(alert, animated: true, completion: nil)
    }
    
}
