import SwiftUI
import AppKit

struct LabMainView: View {
    @State private var orders: [(id: Int, patientName: String, analysisType: String)] = []
    @State private var selectedOrderId: Int?
    @State private var resultText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var refreshTimer: Timer?
    
    var body: some View {
        HSplitView {
            // Левая панель - список заказов
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Активные заказы")
                        .font(.headline)
                        .padding(.leading, 10)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    Button(action: refreshOrders) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .padding(.trailing, 10)
                    .padding(.top, 10)
                    .help("Обновить список")
                }
                
                List(orders, id: \.id, selection: $selectedOrderId) { order in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(order.patientName)
                            .font(.headline)
                        Text(order.analysisType)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 5)
                    .tag(order.id)
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 250, idealWidth: 300)
            
            // Правая панель - ввод результата
            VStack(alignment: .leading, spacing: 15) {
                if let orderId = selectedOrderId {
                    // Находим выбранный заказ
                    if let selectedOrder = orders.first(where: { $0.id == orderId }) {
                        Text("Анализ: \(selectedOrder.analysisType)")
                            .font(.largeTitle)
                            .padding(.bottom, 5)
                        
                        Text("Пациент: \(selectedOrder.patientName)")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        Text("Введите результат анализа:")
                            .font(.headline)
                        
                        TextEditor(text: $resultText)
                            .font(.body)
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        HStack {
                            Button("Сохранить и отправить") {
                                saveResult(orderId: orderId)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(resultText.isEmpty)
                            
                            Button("Очистить") {
                                resultText = ""
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 10)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "microscope")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Выберите заказ из списка слева")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Чтобы ввести результат анализа")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .frame(minWidth: 400)
        }
        .onAppear {
            refreshOrders()
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .alert("Уведомление", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    func refreshOrders() {
        orders = DatabaseManager.shared.fetchPendingLabOrders()
        print("🔄 Обновлено заказов: \(orders.count)")
    }
    
    func startAutoRefresh() {
        // Автоматическое обновление списка каждые 10 секунд
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            refreshOrders()
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func saveResult(orderId: Int) {
        DatabaseManager.shared.updateLabResult(orderId: orderId, result: resultText)
        
        // Очищаем поля
        resultText = ""
        selectedOrderId = nil
        
        // Обновляем список
        refreshOrders()
        
        alertMessage = "Результат анализа сохранён и отправлен врачу"
        showingAlert = true
    }
}

#Preview {
    LabMainView()
}
