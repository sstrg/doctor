import SwiftUI
import AppKit

struct DoctorMainView: View {
    let doctorId: Int
    @State private var patients: [(id: Int, name: String)] = []
    @State private var allPatients: [(id: Int, name: String, email: String)] = []
    @State private var selectedPatientId: Int?
    @State private var diagnosis = ""
    @State private var treatment = ""
    @State private var prescription = ""
    @State private var analysisType = ""
    @State private var patientHistory: [(diagnosis: String, treatment: String, prescription: String, date: String)] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showAddPatient = false
    @State private var searchText = ""
    
    // Вычисляемое свойство для фильтрации пациентов
    var filteredPatients: [(id: Int, name: String)] {
        if searchText.isEmpty {
            return patients
        } else {
            return allPatients
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
                .map { ($0.id, $0.name) }
        }
    }
    
    var body: some View {
        HSplitView {
            // MARK: - Левая панель - список пациентов
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Мои пациенты")
                        .font(.headline)
                        .padding(.leading, 10)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    Button(action: { showAddPatient = true }) {
                        Image(systemName: "person.badge.plus")
                        Text("Добавить")
                    }
                    .padding(.trailing, 10)
                    .padding(.top, 10)
                    .help("Добавить нового пациента")
                }
                
                // Поле поиска
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Поиск по имени или email", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
                
                // Список пациентов
                List(selection: $selectedPatientId) {
                    ForEach(filteredPatients, id: \.id) { patient in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(patient.name)
                                .font(.headline)
                            if !searchText.isEmpty {
                                if let patientData = allPatients.first(where: { $0.id == patient.id }) {
                                    Text(patientData.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 3)
                        .tag(patient.id)
                        .contextMenu {
                            Button(action: {
                                showDeletePatientConfirmation(patientId: patient.id, patientName: patient.name)
                            }) {
                                Label("Удалить пациента", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 280, idealWidth: 320)
            .onAppear {
                loadAllPatients()
                loadPatients()
            }
            .onChange(of: selectedPatientId) { newValue in
                if let id = newValue {
                    loadPatientHistory(patientId: id)
                }
            }
            
            // MARK: - Правая панель - рабочая область
            ScrollView {
                if let patientId = selectedPatientId {
                    PatientDetailView(
                        patientId: patientId,
                        doctorId: doctorId,
                        diagnosis: $diagnosis,
                        treatment: $treatment,
                        prescription: $prescription,
                        analysisType: $analysisType,
                        patientHistory: $patientHistory,
                        showingAlert: $showingAlert,
                        alertMessage: $alertMessage,
                        onPatientDeleted: {
                            // Обработчик удаления пациента
                            loadPatients()
                            selectedPatientId = nil
                            patientHistory = []
                        },
                        onRecordChanged: {
                            // Обработчик изменения записи
                            if let id = selectedPatientId {
                                loadPatientHistory(patientId: id)
                            }
                        }
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Выберите пациента из списка слева")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Или нажмите «Добавить» чтобы создать нового пациента")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: { showAddPatient = true }) {
                            Label("Добавить пациента", systemImage: "person.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAddPatient) {
            AddPatientView()
        }
        .onChange(of: showAddPatient) { newValue in
            if !newValue {
                // Обновляем списки после закрытия окна добавления
                loadAllPatients()
                loadPatients()
            }
        }
        .alert("Уведомление", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Функции загрузки данных
    
    func loadAllPatients() {
        allPatients = DatabaseManager.shared.getAllPatients()
        print("📋 Загружено всех пациентов: \(allPatients.count)")
    }
    
    func loadPatients() {
        patients = DatabaseManager.shared.fetchPatients(forDoctorId: doctorId)
        if patients.isEmpty {
            print("⚠️ Нет пациентов для врача ID: \(doctorId)")
        } else {
            print("✅ Загружено пациентов: \(patients.count)")
        }
        loadAllPatients()
    }
    
    func loadPatientHistory(patientId: Int) {
        patientHistory = DatabaseManager.shared.getPatientHistory(patientId: patientId)
        print("📋 Загружено записей для пациента \(patientId): \(patientHistory.count)")
    }
    
    // MARK: - Функции удаления
    
    func showDeletePatientConfirmation(patientId: Int, patientName: String) {
        let alert = NSAlert()
        alert.messageText = "Удаление пациента"
        alert.informativeText = "Вы уверены, что хотите удалить пациента \"\(patientName)\" и ВСЕ его медицинские записи?\n\nЭто действие нельзя отменить."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Удалить")
        alert.addButton(withTitle: "Отмена")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            _ = DatabaseManager.shared.deletePatient(patientId: patientId)
            loadPatients()
            if selectedPatientId == patientId {
                selectedPatientId = nil
                patientHistory = []
            }
            
            let successAlert = NSAlert()
            successAlert.messageText = "Успешно"
            successAlert.informativeText = "Пациент удалён из системы"
            successAlert.alertStyle = .informational
            successAlert.addButton(withTitle: "OK")
            successAlert.runModal()
        }
    }
}

// MARK: - Preview
#Preview {
    DoctorMainView(doctorId: 1)
}
