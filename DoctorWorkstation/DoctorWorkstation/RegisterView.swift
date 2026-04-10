import SwiftUI
import AppKit

struct RegisterView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole = "doctor"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var registrationSuccess = false
    @Environment(\.dismiss) var dismiss
    
    let roles = ["doctor", "nurse", "lab_technician"]
    let roleDisplayNames = ["Врач", "Медсестра", "Лаборант"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Регистрация медицинского персонала")
                .font(.largeTitle)
                .padding(.bottom, 10)
            
            Text("Заполните форму для создания аккаунта")
                .font(.caption)
                .foregroundColor(.gray)
            
            Group {
                TextField("Полное имя", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Подтвердите пароль", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Роль", selection: $selectedRole) {
                    ForEach(0..<roles.count, id: \.self) { index in
                        Text(roleDisplayNames[index]).tag(roles[index])
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            }
            .frame(width: 350)
            
            HStack(spacing: 20) {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Зарегистрироваться") {
                    register()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 450, height: 450)
        .alert(alertTitle, isPresented: $showAlert) {
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
    
    func register() {
        if password.count < 6 {
            alertTitle = "Ошибка"
            alertMessage = "Пароль должен содержать минимум 6 символов"
            showAlert = true
            return
        }
        
        if !email.contains("@") || !email.contains(".") {
            alertTitle = "Ошибка"
            alertMessage = "Введите корректный email"
            showAlert = true
            return
        }
        
        let passwordHash = OTPGenerator.sha256(password)
        
        if DatabaseManager.shared.registerUser(
            email: email,
            passwordHash: passwordHash,
            role: selectedRole,
            fullName: fullName
        ) {
            alertTitle = "Успешно! 🎉"
            alertMessage = "Аккаунт создан. Теперь вы можете войти в систему."
            registrationSuccess = true
            showAlert = true
        } else {
            alertTitle = "Ошибка"
            alertMessage = "Пользователь с таким email уже существует"
            showAlert = true
        }
    }
}

#Preview {
    RegisterView()
}
