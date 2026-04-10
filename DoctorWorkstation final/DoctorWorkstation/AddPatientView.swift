import SwiftUI
import AppKit

struct AddPatientView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var birthDate = Date()
    @State private var address = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var registrationSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Добавление нового пациента")
                .font(.largeTitle)
                .padding(.bottom, 10)
            
            Text("Заполните информацию о пациенте")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Основная информация
                    GroupBox("Личная информация") {
                        VStack(spacing: 12) {
                            TextField("Полное имя *", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Email *", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Телефон", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            DatePicker("Дата рождения", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                            
                            TextField("Адрес", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Данные для входа
                    GroupBox("Данные для входа в систему") {
                        VStack(spacing: 12) {
                            SecureField("Пароль *", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            SecureField("Подтвердите пароль *", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Пациент сможет войти в мобильное приложение с этими данными")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .frame(width: 400)
            }
            .frame(height: 500)
            
            HStack(spacing: 20) {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Добавить пациента") {
                    addPatient()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 500, height: 700)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if registrationSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        email.contains("@") &&
        email.contains(".")
    }
    
    func addPatient() {
        if password.count < 6 {
            alertTitle = "Ошибка"
            alertMessage = "Пароль должен содержать минимум 6 символов"
            showingAlert = true
            return
        }
        
        if !email.contains("@") || !email.contains(".") {
            alertTitle = "Ошибка"
            alertMessage = "Введите корректный email"
            showingAlert = true
            return
        }
        
        let passwordHash = OTPGenerator.sha256(password)
        
        if DatabaseManager.shared.registerUser(
            email: email,
            passwordHash: passwordHash,
            role: "patient",
            fullName: fullName
        ) {
            DatabaseManager.shared.savePatientInfo(
                email: email,
                phone: phone,
                birthDate: birthDate,
                address: address
            )
            
            alertTitle = "Успешно! 🎉"
            alertMessage = "Пациент \(fullName) добавлен в систему"
            registrationSuccess = true
            showingAlert = true
        } else {
            alertTitle = "Ошибка"
            alertMessage = "Пользователь с таким email уже существует"
            showingAlert = true
        }
    }
}
