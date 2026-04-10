import SwiftUI
import AppKit

struct EditMedicalRecordView: View {
    let recordId: Int
    let patientName: String
    @State private var diagnosis: String
    @State private var treatment: String
    @State private var prescription: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) var dismiss
    
    init(recordId: Int, patientName: String, diagnosis: String, treatment: String, prescription: String) {
        self.recordId = recordId
        self.patientName = patientName
        _diagnosis = State(initialValue: diagnosis)
        _treatment = State(initialValue: treatment)
        _prescription = State(initialValue: prescription)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Редактирование записи")
                .font(.largeTitle)
                .padding(.bottom, 10)
            
            Text("Пациент: \(patientName)")
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Диагноз:")
                    .fontWeight(.semibold)
                TextEditor(text: $diagnosis)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                
                Text("Лечение:")
                    .fontWeight(.semibold)
                TextEditor(text: $treatment)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                
                Text("Рецепт:")
                    .fontWeight(.semibold)
                TextEditor(text: $prescription)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Сохранить изменения") {
                    saveRecord()
                }
                .buttonStyle(.borderedProminent)
                .disabled(diagnosis.isEmpty || treatment.isEmpty)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 500, height: 500)
        .alert("Уведомление", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("сохранена") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    func saveRecord() {
        if DatabaseManager.shared.updateMedicalRecord(
            recordId: recordId,
            diagnosis: diagnosis,
            treatment: treatment,
            prescription: prescription
        ) {
            alertMessage = "Запись успешно сохранена"
            showingAlert = true
        } else {
            alertMessage = "Ошибка при сохранении записи"
            showingAlert = true
        }
    }
}
