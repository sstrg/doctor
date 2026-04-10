import SwiftUI
import AppKit

struct PatientDetailView: View {
    let patientId: Int
    let doctorId: Int
    @Binding var diagnosis: String
    @Binding var treatment: String
    @Binding var prescription: String
    @Binding var analysisType: String
    @Binding var patientHistory: [(diagnosis: String, treatment: String, prescription: String, date: String)]
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    // Замыкания для обратной связи с родительским view
    var onPatientDeleted: (() -> Void)?
    var onRecordChanged: (() -> Void)?
    
    @State private var patientInfo: (name: String, email: String, phone: String, birthDate: String, address: String)?
    @State private var selectedRecordForEdit: (id: Int, diagnosis: String, treatment: String, prescription: String, date: String)?
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var recordToDelete: (id: Int, date: String)?
    @State private var showDeletePatientConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Информация о пациенте с кнопкой удаления
            if let info = patientInfo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(info.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(info.email)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Кнопка удаления пациента
                        Button(action: { showDeletePatientConfirmation = true }) {
                            Label("Удалить пациента", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .help("Удалить пациента и все его записи")
                    }
                    
                    Divider()
                    
                    HStack(spacing: 20) {
                        if !info.phone.isEmpty {
                            Label(info.phone, systemImage: "phone")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if !info.birthDate.isEmpty {
                            Label(info.birthDate, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if !info.address.isEmpty {
                            Label(info.address, systemImage: "location")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // MARK: - История болезни
            HStack {
                Text("История болезни")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Всего записей: \(patientHistory.count)")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            if patientHistory.isEmpty {
                // Пустое состояние
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Нет записей в истории")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Используйте форму ниже, чтобы добавить первую запись")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            } else {
                // Список записей
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(patientHistory.indices, id: \.self) { index in
                            let record = patientHistory[index]
                            recordCard(record: record)
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            
            Divider()
                .padding(.vertical, 5)
            
            // MARK: - Форма добавления новой записи
            Text("➕ Новая запись в медкарту")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Диагноз:")
                    .fontWeight(.semibold)
                TextEditor(text: $diagnosis)
                    .frame(height: 60)
                    .padding(4)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text("Лечение:")
                    .fontWeight(.semibold)
                TextEditor(text: $treatment)
                    .frame(height: 60)
                    .padding(4)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text("Рецепт:")
                    .fontWeight(.semibold)
                TextEditor(text: $prescription)
                    .frame(height: 60)
                    .padding(4)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Button(action: saveMedicalRecord) {
                    Text("Сохранить в медкарту")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(diagnosis.isEmpty || treatment.isEmpty)
            }
            .padding(.bottom, 10)
            
            Divider()
                .padding(.vertical, 5)
            
            // MARK: - Форма назначения анализов
            Text("🔬 Назначить лабораторный анализ")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Тип анализа (например: Общий анализ крови)", text: $analysisType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: orderAnalysis) {
                    Text("Отправить в лабораторию")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .disabled(analysisType.isEmpty)
            }
        }
        .padding()
        .onAppear {
            loadPatientInfo()
        }
        .sheet(isPresented: $showEditSheet) {
            if let record = selectedRecordForEdit {
                EditMedicalRecordView(
                    recordId: record.id,
                    patientName: patientInfo?.name ?? "",
                    diagnosis: record.diagnosis,
                    treatment: record.treatment,
                    prescription: record.prescription
                )
            }
        }
        .onChange(of: showEditSheet) { newValue in
            if !newValue {
                refreshPatientHistory()
            }
        }
        .alert("Подтверждение удаления", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let record = recordToDelete {
                    deleteMedicalRecord(recordId: record.id)
                }
            }
        } message: {
            if let record = recordToDelete {
                Text("Вы уверены, что хотите удалить запись от \(record.date)?\nЭто действие нельзя отменить.")
            }
        }
        .alert("Подтверждение удаления пациента", isPresented: $showDeletePatientConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                deletePatient()
            }
        } message: {
            Text("Вы уверены, что хотите удалить пациента \(patientInfo?.name ?? "") и ВСЕ его медицинские записи?\nЭто действие нельзя отменить.")
        }
    }
    
    // MARK: - Карточка записи
    @ViewBuilder
    private func recordCard(record: (diagnosis: String, treatment: String, prescription: String, date: String)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text(record.date)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Кнопка редактирования
                Button(action: {
                    if let recordId = DatabaseManager.shared.getMedicalRecordId(patientId: patientId, date: record.date) {
                        selectedRecordForEdit = (recordId, record.diagnosis, record.treatment, record.prescription, record.date)
                        showEditSheet = true
                    }
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Редактировать запись")
                
                // Кнопка удаления записи
                Button(action: {
                    if let recordId = DatabaseManager.shared.getMedicalRecordId(patientId: patientId, date: record.date) {
                        recordToDelete = (recordId, record.date)
                        showDeleteConfirmation = true
                    }
                }) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Удалить запись")
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("📋 Диагноз:")
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .leading)
                    Text(record.diagnosis)
                        .foregroundColor(.primary)
                }
                
                HStack(alignment: .top) {
                    Text("💊 Лечение:")
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .leading)
                    Text(record.treatment)
                        .foregroundColor(.primary)
                }
                
                HStack(alignment: .top) {
                    Text("📄 Рецепт:")
                        .fontWeight(.bold)
                        .frame(width: 80, alignment: .leading)
                    Text(record.prescription)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Функции
    func loadPatientInfo() {
        patientInfo = DatabaseManager.shared.getPatientInfo(patientId: patientId)
    }
    
    func refreshPatientHistory() {
        onRecordChanged?()
    }
    
    func saveMedicalRecord() {
        DatabaseManager.shared.addMedicalRecord(
            patientId: patientId,
            doctorId: doctorId,
            diagnosis: diagnosis,
            treatment: treatment,
            prescription: prescription
        )
        
        diagnosis = ""
        treatment = ""
        prescription = ""
        
        refreshPatientHistory()
        
        alertMessage = "✅ Запись добавлена в медицинскую карту"
        showingAlert = true
    }
    
    func orderAnalysis() {
        DatabaseManager.shared.orderLabAnalysis(
            patientId: patientId,
            doctorId: doctorId,
            analysisType: analysisType
        )
        
        analysisType = ""
        
        alertMessage = "🔬 Анализ назначен и отправлен в лабораторию"
        showingAlert = true
    }
    
    func deleteMedicalRecord(recordId: Int) {
        if DatabaseManager.shared.deleteMedicalRecord(recordId: recordId) {
            refreshPatientHistory()
            alertMessage = "🗑️ Запись успешно удалена"
            showingAlert = true
        } else {
            alertMessage = "❌ Ошибка при удалении записи"
            showingAlert = true
        }
    }
    
    func deletePatient() {
        if DatabaseManager.shared.deletePatient(patientId: patientId) {
            onPatientDeleted?()
            alertMessage = "🗑️ Пациент успешно удалён"
            showingAlert = true
        } else {
            alertMessage = "❌ Ошибка при удалении пациента"
            showingAlert = true
        }
    }
}
