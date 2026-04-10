import SwiftUI
import AppKit

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var show2FA = false
    @State private var otpCode = ""
    @State private var userId: Int?
    @State private var userRole: String?
    @State private var twofaSecret = ""
    @State private var loginError = ""
    @State private var showRegister = false
    @State private var timerSeconds = 30
    @State private var timer: Timer?
    @State private var canResend = false
    @State private var isLoggingIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Медицинская система")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            Text("Вход для медицинского персонала")
                .font(.title2)
                .foregroundColor(.gray)
            
            if !show2FA {
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                        .onSubmit {
                            if !password.isEmpty {
                                login()
                            }
                        }
                    
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                        .onSubmit {
                            login()
                        }
                    
                    if !loginError.isEmpty {
                        Text(loginError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: login) {
                            if isLoggingIn {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                    .frame(width: 80)
                            } else {
                                Text("Войти")
                                    .frame(width: 80)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty || isLoggingIn)
                        
                        Button("Регистрация") {
                            showRegister = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 5)
                }
            } else {
                VStack(spacing: 15) {
                    Text("Двухфакторная аутентификация")
                        .font(.headline)
                    
                    Text("📧 Код подтверждения отправлен")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("на \(email)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if !canResend {
                        Text("Код действителен: \(timerSeconds) сек")
                            .font(.caption)
                            .foregroundColor(timerSeconds < 10 ? .red : .gray)
                            .padding(.top, 5)
                    }
                    
                    TextField("Введите 6-значный код", text: $otpCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            if otpCode.count == 6 {
                                verify2FA()
                            }
                        }
                    
                    if !loginError.isEmpty {
                        Text(loginError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    
                    Button(action: verify2FA) {
                        Text("Подтвердить")
                            .frame(width: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(otpCode.count != 6)
                    
                    HStack(spacing: 20) {
                        Button("Назад") {
                            show2FA = false
                            otpCode = ""
                            loginError = ""
                            timer?.invalidate()
                        }
                        .font(.caption)
                        
                        Button("Отправить код повторно") {
                            resendCode()
                        }
                        .font(.caption)
                        .disabled(!canResend)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding()
        .frame(width: 450, height: 400)
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .onAppear {
            resetLoginState()
        }
    }
    
    // MARK: - Functions
    
    func resetLoginState() {
        email = ""
        password = ""
        otpCode = ""
        loginError = ""
        show2FA = false
        isLoggingIn = false
        timer?.invalidate()
        timer = nil
    }
    
    func login() {
        guard !isLoggingIn else { return }
        guard !email.isEmpty, !password.isEmpty else {
            loginError = "Введите email и пароль"
            return
        }
        
        isLoggingIn = true
        loginError = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let passwordHash = OTPGenerator.sha256(password)
            print("📧 Попытка входа: \(email)")
            
            if let user = DatabaseManager.shared.authenticateUser(email: email, passwordHash: passwordHash) {
                userId = user.id
                userRole = user.role
                twofaSecret = user.twofaSecret
                
                sendCode()
                show2FA = true
                isLoggingIn = false
            } else {
                loginError = "Неверный email или пароль"
                isLoggingIn = false
            }
        }
    }
    
    func sendCode() {
        let code = OTPGenerator.generateTOTP(secret: twofaSecret)
        OTPGenerator.sendCodeToEmail(email: email, code: code)
        
        timerSeconds = 30
        canResend = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if timerSeconds > 0 {
                    timerSeconds -= 1
                } else {
                    timer?.invalidate()
                    canResend = true
                    loginError = "Время действия кода истекло. Запросите новый код."
                }
            }
        }
    }
    
    func resendCode() {
        sendCode()
        otpCode = ""
        loginError = ""
    }
    
    func verify2FA() {
        let expectedCode = OTPGenerator.generateTOTP(secret: twofaSecret)
        
        if otpCode == expectedCode {
            timer?.invalidate()
            
            if let window = NSApplication.shared.windows.first {
                if userRole == "doctor" {
                    window.contentView = NSHostingView(rootView: DoctorMainView(doctorId: userId!))
                } else if userRole == "lab_technician" {
                    window.contentView = NSHostingView(rootView: LabMainView())
                } else {
                    let alert = NSAlert()
                    alert.messageText = "Ошибка"
                    alert.informativeText = "Роль '\(userRole ?? "unknown")' пока не поддерживается"
                    alert.runModal()
                }
                window.title = "Медицинская система - \(userRole ?? "")"
            }
        } else {
            loginError = "❌ Неверный код подтверждения. Попробуйте снова."
            otpCode = ""
        }
    }
}

#Preview {
    LoginView()
}
