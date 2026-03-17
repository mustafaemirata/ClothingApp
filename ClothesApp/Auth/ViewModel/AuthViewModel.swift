//
//  RegisterViewModel.swift
//  ClothesApp
//
//  Created by Mustafa Emir Ata on 15.03.2026.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class RegisterViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var selectedStyle = "Kadın"
    
    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var isRegistrationSuccess = false
    
    private let db = Firestore.firestore()
    let styleOptions = ["Kadın", "Erkek", "Çocuk", "Unisex"]

    func createAccount() {
        guard validate() else { return }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.alertMessage = self.handleAuthError(error)
                return
            }
            
            guard let uid = authResult?.user.uid else {
                self.isLoading = false
                return
            }
            
            self.saveUserDataToFirestore(uid: uid)
        }
    }
    
    private func saveUserDataToFirestore(uid: String) {
        let userData: [String: Any] = [
            "id": uid,
            "fullName": fullName,
            "email": email,
            "stylePreference": selectedStyle,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.alertMessage = "Profil bilgileri kaydedilemedi: \(error.localizedDescription)"
            } else {
                self.isRegistrationSuccess = true
            }
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        switch AuthErrorCode(rawValue: errorCode) {
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kullanımda."
        case .invalidEmail:
            return "Lütfen geçerli bir e-posta adresi yazın."
        case .weakPassword:
            return "Şifreniz çok zayıf. Daha karmaşık bir şifre deneyin."
        default:
            return error.localizedDescription
        }
    }
    
    private func validate() -> Bool {
        if fullName.trimmingCharacters(in: .whitespaces).count < 3 {
            alertMessage = "Lütfen adınızı ve soyadınızı tam girin."
            return false
        }
        if !email.contains("@") || email.count < 5 {
            alertMessage = "Geçerli bir e-posta adresi giriniz."
            return false
        }
        if password.count < 6 {
            alertMessage = "Şifreniz güvenliğiniz için en az 6 karakter olmalıdır."
            return false
        }
        alertMessage = nil
        return true
    }
}
