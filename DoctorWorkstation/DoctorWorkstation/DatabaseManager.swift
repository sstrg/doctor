import Foundation
import PostgresClientKit

class DatabaseManager {
    static let shared = DatabaseManager()
    private var connection: PostgresConnection?
    
    // Конфигурация PostgreSQL
    private let host = "localhost"
    private let port = 5432
    private let database = "medical_system"
    private let user = "medical_user"
    private let password = "medical_password"
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            var configuration = PostgresClientKit.ConnectionConfiguration()
            configuration.host = host
            configuration.port = port
            configuration.database = database
            configuration.user = user
            configuration.credential = .scramSHA256(password: password)
            
            connection = try PostgresConnection(configuration: configuration)
            print("✅ Подключено к PostgreSQL: \(host):\(port)/\(database)")
            
            createTables()
            insertTestData()
            
        } catch {
            print("❌ Ошибка подключения к PostgreSQL: \(error)")
        }
    }
    
    private func executeQuery(_ query: String) -> [PostgresRow]? {
        guard let connection = connection else {
            print("❌ Нет подключения к БД")
            return nil
        }
        
        do {
            let result = try connection.execute(query)
            var rows: [PostgresRow] = []
            
            for row in result {
                rows.append(row)
            }
            
            return rows
        } catch {
            print("❌ Ошибка выполнения запроса: \(error)")
            return nil
        }
    }
    
    private func createTables() {
        do {
            // Таблица пользователей
            try connection?.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    role VARCHAR(50) NOT NULL,
                    full_name VARCHAR(255) NOT NULL,
                    twofa_secret VARCHAR(255) DEFAULT '',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            // Таблица медицинских записей
            try connection?.execute("""
                CREATE TABLE IF NOT EXISTS medical_records (
                    id SERIAL PRIMARY KEY,
                    patient_id INTEGER NOT NULL,
                    doctor_id INTEGER NOT NULL,
                    diagnosis TEXT,
                    treatment TEXT,
                    prescription TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE,
                    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            // Таблица лабораторных заказов
            try connection?.execute("""
                CREATE TABLE IF NOT EXISTS lab_orders (
                    id SERIAL PRIMARY KEY,
                    patient_id INTEGER NOT NULL,
                    doctor_id INTEGER NOT NULL,
                    analysis_type VARCHAR(255),
                    status VARCHAR(50) DEFAULT 'pending',
                    result TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE,
                    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)
            
            // Таблица дополнительной информации о пациентах
            try connection?.execute("""
                CREATE TABLE IF NOT EXISTS patient_info (
                    id SERIAL PRIMARY KEY,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    phone VARCHAR(50),
                    birth_date DATE,
                    address TEXT,
                    FOREIGN KEY (email) REFERENCES users(email) ON DELETE CASCADE
                )
            """)
            
            print("✅ Таблицы созданы")
        } catch {
            print("❌ Ошибка создания таблиц: \(error)")
        }
    }
    
    private func insertTestData() {
        do {
            // Проверяем, есть ли уже данные
            let checkUsers = try connection?.execute("SELECT COUNT(*) FROM users")
            if let count = checkUsers?.first?.columns[0].int(), count > 0 {
                print("✅ Данные уже существуют в БД")
                return
            }
            
            // Хэш для "doctor123"
            let doctorHash = "3d4f2bf07dc1be38b20cd6e46949a1071f9d0e3d9bd1fb35a26c8dabf3f31f4b"
            
            // Вставляем врача
            try connection?.execute("""
                INSERT INTO users (email, password_hash, role, full_name, twofa_secret)
                VALUES ('doctor@med.com', '\(doctorHash)', 'doctor', 'Dr. Smith', '')
            """)
            
            // Хэш для "password123"
            let patientHash = "482c811da5d5b4bc6d497ffa98491e38"
            
            // Вставляем пациента
            try connection?.execute("""
                INSERT INTO users (email, password_hash, role, full_name, twofa_secret)
                VALUES ('patient@med.com', '\(patientHash)', 'patient', 'John Doe', '')
            """)
            
            // Вставляем лаборанта
            let labHash = "3d4f2bf07dc1be38b20cd6e46949a1071f9d0e3d9bd1fb35a26c8dabf3f31f4b"
            try connection?.execute("""
                INSERT INTO users (email, password_hash, role, full_name, twofa_secret)
                VALUES ('lab@med.com', '\(labHash)', 'lab_technician', 'Dr. Lab', '')
            """)
            
            // Добавляем тестовую запись в медкарту
            try connection?.execute("""
                INSERT INTO medical_records (patient_id, doctor_id, diagnosis, treatment, prescription)
                VALUES (2, 1, 'Первичный осмотр', 'Рекомендован отдых', 'Витамины')
            """)
            
            print("✅ Тестовые данные добавлены")
            print("👨‍⚕️ Врач: doctor@med.com / doctor123")
            print("👤 Пациент: patient@med.com / password123")
            print("🔬 Лаборант: lab@med.com / doctor123")
            
        } catch {
            print("❌ Ошибка добавления тестовых данных: \(error)")
        }
    }
    
    // MARK: - Аутентификация
    
    func authenticateUser(email: String, passwordHash: String) -> (id: Int, role: String, twofaSecret: String)? {
        do {
            let query = """
                SELECT id, role, COALESCE(twofa_secret, '') 
                FROM users 
                WHERE email = '\(email)' AND password_hash = '\(passwordHash)'
            """
            let rows = try connection?.execute(query)
            
            if let row = rows?.first {
                let id = row.columns[0].int() ?? 0
                let role = row.columns[1].string() ?? ""
                let secret = row.columns[2].string() ?? ""
                print("✅ Пользователь найден: \(email), роль: \(role)")
                return (id, role, secret)
            }
            print("❌ Пользователь не найден: \(email)")
        } catch {
            print("❌ Ошибка аутентификации: \(error)")
        }
        return nil
    }
    
    // MARK: - Регистрация
    
    func registerUser(email: String, passwordHash: String, role: String, fullName: String) -> Bool {
        do {
            // Проверяем, существует ли пользователь
            let checkQuery = "SELECT id FROM users WHERE email = '\(email)'"
            let existingUser = try connection?.execute(checkQuery)
            
            if existingUser?.first != nil {
                print("❌ Пользователь с email \(email) уже существует")
                return false
            }
            
            // Создаём нового пользователя
            let insertQuery = """
                INSERT INTO users (email, password_hash, role, full_name, twofa_secret)
                VALUES ('\(email)', '\(passwordHash)', '\(role)', '\(fullName)', '')
            """
            try connection?.execute(insertQuery)
            
            print("✅ Новый пользователь зарегистрирован: \(email) (\(role))")
            return true
            
        } catch {
            print("❌ Ошибка регистрации: \(error)")
            return false
        }
    }
    
    func userExists(email: String) -> Bool {
        do {
            let query = "SELECT id FROM users WHERE email = '\(email)'"
            let rows = try connection?.execute(query)
            return rows?.first != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Работа с пациентами
    
    func savePatientInfo(email: String, phone: String, birthDate: Date, address: String) {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let birthDateString = dateFormatter.string(from: birthDate)
            
            let escapedAddress = address.replacingOccurrences(of: "'", with: "''")
            let escapedPhone = phone.replacingOccurrences(of: "'", with: "''")
            
            try connection?.execute("""
                INSERT INTO patient_info (email, phone, birth_date, address)
                VALUES ('\(email)', '\(escapedPhone)', '\(birthDateString)', '\(escapedAddress)')
                ON CONFLICT (email) DO UPDATE SET
                    phone = EXCLUDED.phone,
                    birth_date = EXCLUDED.birth_date,
                    address = EXCLUDED.address
            """)
            
            print("✅ Информация о пациенте сохранена")
        } catch {
            print("❌ Ошибка сохранения информации: \(error)")
        }
    }
    
    func getAllPatients() -> [(id: Int, name: String, email: String)] {
        var patients: [(Int, String, String)] = []
        do {
            let query = "SELECT id, full_name, email FROM users WHERE role = 'patient' ORDER BY full_name"
            let rows = try connection?.execute(query)
            
            for row in rows ?? [] {
                let id = row.columns[0].int() ?? 0
                let name = row.columns[1].string() ?? ""
                let email = row.columns[2].string() ?? ""
                patients.append((id, name, email))
            }
            print("📋 Загружено пациентов: \(patients.count)")
        } catch {
            print("❌ Ошибка получения списка пациентов: \(error)")
        }
        return patients
    }
    
    func searchPatients(query: String) -> [(id: Int, name: String, email: String)] {
        var patients: [(Int, String, String)] = []
        do {
            let searchQuery = """
                SELECT id, full_name, email FROM users 
                WHERE role = 'patient' 
                AND (full_name ILIKE '%\(query)%' OR email ILIKE '%\(query)%')
                ORDER BY full_name
            """
            let rows = try connection?.execute(searchQuery)
            
            for row in rows ?? [] {
                let id = row.columns[0].int() ?? 0
                let name = row.columns[1].string() ?? ""
                let email = row.columns[2].string() ?? ""
                patients.append((id, name, email))
            }
        } catch {
            print("❌ Ошибка поиска: \(error)")
        }
        return patients
    }
    
    func getPatientInfo(patientId: Int) -> (name: String, email: String, phone: String, birthDate: String, address: String)? {
        do {
            let query = """
                SELECT u.full_name, u.email, 
                       COALESCE(p.phone, ''), 
                       COALESCE(p.birth_date::TEXT, ''), 
                       COALESCE(p.address, '')
                FROM users u
                LEFT JOIN patient_info p ON u.email = p.email
                WHERE u.id = \(patientId) AND u.role = 'patient'
            """
            let rows = try connection?.execute(query)
            
            if let row = rows?.first {
                let name = row.columns[0].string() ?? ""
                let email = row.columns[1].string() ?? ""
                let phone = row.columns[2].string() ?? ""
                let birthDate = row.columns[3].string() ?? ""
                let address = row.columns[4].string() ?? ""
                return (name, email, phone, birthDate, address)
            }
        } catch {
            print("❌ Ошибка получения информации: \(error)")
        }
        return nil
    }
    
    func fetchPatients(forDoctorId doctorId: Int) -> [(id: Int, name: String)] {
        var patients: [(Int, String)] = []
        do {
            let query = """
                SELECT DISTINCT u.id, u.full_name 
                FROM users u 
                JOIN medical_records mr ON u.id = mr.patient_id 
                WHERE mr.doctor_id = \(doctorId)
            """
            let rows = try connection?.execute(query)
            
            for row in rows ?? [] {
                let id = row.columns[0].int() ?? 0
                let name = row.columns[1].string() ?? ""
                patients.append((id, name))
            }
            print("✅ Загружено пациентов: \(patients.count)")
        } catch {
            print("❌ Ошибка получения пациентов: \(error)")
        }
        return patients
    }
    
    // MARK: - Медицинские записи
    
    func addMedicalRecord(patientId: Int, doctorId: Int, diagnosis: String, treatment: String, prescription: String) {
        do {
            let escapedDiagnosis = diagnosis.replacingOccurrences(of: "'", with: "''")
            let escapedTreatment = treatment.replacingOccurrences(of: "'", with: "''")
            let escapedPrescription = prescription.replacingOccurrences(of: "'", with: "''")
            
            try connection?.execute("""
                INSERT INTO medical_records (patient_id, doctor_id, diagnosis, treatment, prescription)
                VALUES (\(patientId), \(doctorId), '\(escapedDiagnosis)', '\(escapedTreatment)', '\(escapedPrescription)')
            """)
            print("✅ Запись добавлена")
        } catch {
            print("❌ Ошибка добавления записи: \(error)")
        }
    }
    
    func getPatientHistory(patientId: Int) -> [(diagnosis: String, treatment: String, prescription: String, date: String)] {
        var records: [(String, String, String, String)] = []
        do {
            let query = """
                SELECT diagnosis, treatment, prescription, 
                       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
                FROM medical_records 
                WHERE patient_id = \(patientId) 
                ORDER BY created_at DESC
            """
            let rows = try connection?.execute(query)
            
            for row in rows ?? [] {
                let diagnosis = row.columns[0].string() ?? ""
                let treatment = row.columns[1].string() ?? ""
                let prescription = row.columns[2].string() ?? ""
                let date = row.columns[3].string() ?? ""
                records.append((diagnosis, treatment, prescription, date))
            }
        } catch {
            print("❌ Ошибка получения истории: \(error)")
        }
        return records
    }
    
    // MARK: - Управление записями
    
    func deletePatient(patientId: Int) -> Bool {
        do {
            try connection?.execute("BEGIN TRANSACTION")
            
            // Удаляем связанные записи (каскадное удаление сработает автоматически)
            try connection?.execute("DELETE FROM users WHERE id = \(patientId) AND role = 'patient'")
            
            try connection?.execute("COMMIT")
            print("✅ Пациент с ID \(patientId) удалён")
            return true
        } catch {
            try? connection?.execute("ROLLBACK")
            print("❌ Ошибка удаления пациента: \(error)")
            return false
        }
    }
    
    func updateMedicalRecord(recordId: Int, diagnosis: String, treatment: String, prescription: String) -> Bool {
        do {
            let escapedDiagnosis = diagnosis.replacingOccurrences(of: "'", with: "''")
            let escapedTreatment = treatment.replacingOccurrences(of: "'", with: "''")
            let escapedPrescription = prescription.replacingOccurrences(of: "'", with: "''")
            
            try connection?.execute("""
                UPDATE medical_records 
                SET diagnosis = '\(escapedDiagnosis)', 
                    treatment = '\(escapedTreatment)', 
                    prescription = '\(escapedPrescription)'
                WHERE id = \(recordId)
            """)
            print("✅ Запись ID \(recordId) обновлена")
            return true
        } catch {
            print("❌ Ошибка обновления записи: \(error)")
            return false
        }
    }
    
    func deleteMedicalRecord(recordId: Int) -> Bool {
        do {
            try connection?.execute("DELETE FROM medical_records WHERE id = \(recordId)")
            print("✅ Запись ID \(recordId) удалена")
            return true
        } catch {
            print("❌ Ошибка удаления записи: \(error)")
            return false
        }
    }
    
    func getMedicalRecordId(patientId: Int, date: String) -> Int? {
        do {
            let query = """
                SELECT id FROM medical_records 
                WHERE patient_id = \(patientId) 
                AND TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') = '\(date)'
            """
            let rows = try connection?.execute(query)
            
            if let row = rows?.first {
                return row.columns[0].int() ?? 0
            }
        } catch {
            print("❌ Ошибка получения ID записи: \(error)")
        }
        return nil
    }
    
    func getMedicalRecord(recordId: Int) -> (diagnosis: String, treatment: String, prescription: String, date: String)? {
        do {
            let query = """
                SELECT diagnosis, treatment, prescription, 
                       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
                FROM medical_records 
                WHERE id = \(recordId)
            """
            let rows = try connection?.execute(query)
            
            if let row = rows?.first {
                let diagnosis = row.columns[0].string() ?? ""
                let treatment = row.columns[1].string() ?? ""
                let prescription = row.columns[2].string() ?? ""
                let date = row.columns[3].string() ?? ""
                return (diagnosis, treatment, prescription, date)
            }
        } catch {
            print("❌ Ошибка получения записи: \(error)")
        }
        return nil
    }
    
    // MARK: - Лабораторные анализы
    
    func orderLabAnalysis(patientId: Int, doctorId: Int, analysisType: String) {
        do {
            let escapedType = analysisType.replacingOccurrences(of: "'", with: "''")
            
            try connection?.execute("""
                INSERT INTO lab_orders (patient_id, doctor_id, analysis_type, status)
                VALUES (\(patientId), \(doctorId), '\(escapedType)', 'pending')
            """)
            print("✅ Анализ назначен")
        } catch {
            print("❌ Ошибка назначения анализа: \(error)")
        }
    }
    
    func fetchPendingLabOrders() -> [(id: Int, patientName: String, analysisType: String)] {
        var orders: [(Int, String, String)] = []
        do {
            let query = """
                SELECT lo.id, u.full_name, lo.analysis_type 
                FROM lab_orders lo 
                JOIN users u ON lo.patient_id = u.id 
                WHERE lo.status = 'pending'
            """
            let rows = try connection?.execute(query)
            
            for row in rows ?? [] {
                let id = row.columns[0].int() ?? 0
                let name = row.columns[1].string() ?? ""
                let type = row.columns[2].string() ?? ""
                orders.append((id, name, type))
            }
        } catch {
            print("❌ Ошибка получения заказов: \(error)")
        }
        return orders
    }
    
    func updateLabResult(orderId: Int, result: String) {
        do {
            let escapedResult = result.replacingOccurrences(of: "'", with: "''")
            try connection?.execute("""
                UPDATE lab_orders 
                SET result = '\(escapedResult)', status = 'ready' 
                WHERE id = \(orderId)
            """)
            print("✅ Результат анализа сохранён")
        } catch {
            print("❌ Ошибка сохранения результата: \(error)")
        }
    }
}
