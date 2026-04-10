import Foundation
import SQLite
import Network

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    private var isNetworkDB = false
    
    // Конфигурация сетевой БД
    struct DBConfig {
        var host: String = "192.168.1.100"  // IP адрес компьютера с БД
        var port: Int = 3306
        var username: String = "user"
        var password: String = "password"
        var databaseName: String = "medical_system"
    }
    
    private var config = DBConfig()
    
    private init() {
        setupDatabase()
    }
    
    func configureRemoteDB(host: String, port: Int, username: String, password: String, database: String) {
        config.host = host
        config.port = port
        config.username = username
        config.password = password
        config.databaseName = database
        isNetworkDB = true
        setupDatabase()
    }
    
    private func setupDatabase() {
        if isNetworkDB {
            setupNetworkDatabase()
        } else {
            setupLocalDatabase()
        }
    }
    
    private func setupLocalDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("medical_system.db").path
            
            print("📁 Локальная БД: \(dbPath)")
            
            let fileExists = FileManager.default.fileExists(atPath: dbPath)
            db = try Connection(dbPath)
            
            if !fileExists {
                createTables()
                insertTestData()
            } else {
                print("✅ Подключено к существующей локальной БД")
                verifyDatabaseStructure()
            }
            
        } catch {
            print("❌ Ошибка локальной БД: \(error)")
        }
    }
    
    private func setupNetworkDatabase() {
        // Для сетевой БД нужно использовать другую библиотеку (например, MySQL или PostgreSQL)
        // Пример с использованием URLSession для REST API
        print("🌐 Подключение к удаленной БД: \(config.host):\(config.port)")
        
        // Здесь можно реализовать запрос к серверному API
        // или использовать MySQL-клиент для Swift
    }
    
    // MARK: - Экспорт/Импорт БД
    
    func exportDatabase() -> URL? {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("medical_system.db")
            let exportPath = documentsPath.appendingPathComponent("medical_system_backup_\(Date().timeIntervalSince1970).db")
            
            try FileManager.default.copyItem(at: dbPath, to: exportPath)
            print("✅ БД экспортирована: \(exportPath)")
            return exportPath
        } catch {
            print("❌ Ошибка экспорта: \(error)")
            return nil
        }
    }
    
    func importDatabase(from url: URL) -> Bool {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = documentsPath.appendingPathComponent("medical_system.db")
            
            // Создаем резервную копию текущей БД
            if FileManager.default.fileExists(atPath: dbPath.path) {
                let backupPath = documentsPath.appendingPathComponent("medical_system_backup_before_import.db")
                try FileManager.default.copyItem(at: dbPath, to: backupPath)
                print("📦 Создана резервная копия")
            }
            
            // Заменяем файл БД
            try FileManager.default.removeItem(at: dbPath)
            try FileManager.default.copyItem(at: url, to: dbPath)
            
            // Переподключаемся
            db = try Connection(dbPath.path)
            print("✅ БД импортирована успешно")
            return true
        } catch {
            print("❌ Ошибка импорта: \(error)")
            return false
        }
    }
    
    // MARK: - Синхронизация с удаленной БД
    
    func syncWithRemoteServer(serverURL: String) {
        // Отправка локальных изменений на сервер
        guard let url = URL(string: serverURL + "/sync") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Получаем все записи для синхронизации
        let localData = getAllRecordsForSync()
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: localData)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Ошибка синхронизации: \(error)")
                    return
                }
                
                if let data = data {
                    // Обработка ответа от сервера
                    self.processSyncResponse(data)
                }
            }
            task.resume()
        } catch {
            print("❌ Ошибка подготовки данных: \(error)")
        }
    }
    
    private func getAllRecordsForSync() -> [String: Any] {
        var syncData: [String: Any] = [:]
        
        // Собираем все записи для синхронизации
        do {
            let users = try db?.prepare("SELECT * FROM users")
            var usersArray: [[String: Any]] = []
            for user in users! {
                usersArray.append(["id": user[0], "email": user[1], "role": user[3]])
            }
            syncData["users"] = usersArray
            
            let records = try db?.prepare("SELECT * FROM medical_records")
            var recordsArray: [[String: Any]] = []
            for record in records! {
                recordsArray.append(["id": record[0], "patient_id": record[1], "diagnosis": record[3]])
            }
            syncData["medical_records"] = recordsArray
            
        } catch {
            print("❌ Ошибка сбора данных: \(error)")
        }
        
        return syncData
    }
    
    private func processSyncResponse(_ data: Data) {
        // Обработка ответа от сервера
        print("✅ Получен ответ от сервера")
    }
}
