import SwiftUI
import Foundation

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize font manager to load custom fonts
        _ = FontManager.shared
        
        let contentView = ContentView()
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("PersianCalendar")
        window.contentView = NSHostingView(rootView: contentView)
        window.title = "تقویم شمسی"
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

struct ContentView: View {
    @StateObject private var persianCalendar = PersianCalendarViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with current Persian date
            VStack(spacing: 5) {
                Text("تقویم شمسی")
                    .font(.yekanBakh(size: 24, weight: .bold))
                
                Text(persianCalendar.currentPersianDateString)
                    .font(.yekanBakh(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Month navigation
            HStack {
                Button(action: { persianCalendar.previousMonth() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                
                Spacer()
                
                Text(persianCalendar.currentMonthYearString)
                    .font(.yekanBakh(size: 18, weight: .semibold))
                
                Spacer()
                
                Button(action: { persianCalendar.nextMonth() }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            PersianCalendarGrid(viewModel: persianCalendar)
            
            // Today button
            Button("برو به امروز") {
                persianCalendar.goToToday()
            }
            .font(.yekanBakh(size: 14))
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .frame(width: 400, height: 500)
        .padding()
    }
}

struct PersianCalendarGrid: View {
    @ObservedObject var viewModel: PersianCalendarViewModel
    
    let weekDays = ["ش", "ی", "د", "س", "چ", "پ", "ج"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 10) {
            // Week day headers
            HStack {
                ForEach(weekDays.indices, id: \.self) { index in
                    Text(weekDays[index])
                        .font(.yekanBakh(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.calendarDays, id: \.id) { day in
                    DayView(day: day, isToday: viewModel.isToday(day))
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct DayView: View {
    let day: CalendarDay
    let isToday: Bool
    
    var body: some View {
        Text(day.persianDay)
            .font(.yekanBakh(size: 14, weight: isToday ? .bold : .regular))
            .foregroundColor(day.isCurrentMonth ? .primary : .secondary)
            .frame(width: 30, height: 30)
            .background(
                Circle()
                    .fill(isToday ? Color.accentColor : Color.clear)
            )
            .foregroundColor(isToday ? .white : nil)
    }
}

// MARK: - Persian Calendar Models and Logic

struct CalendarDay {
    let id = UUID()
    let persianDay: String
    let gregorianDate: Date
    let isCurrentMonth: Bool
}

class PersianCalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var calendarDays: [CalendarDay] = []
    
    private let persianCalendar: Calendar
    private let gregorianCalendar = Calendar(identifier: .gregorian)
    private let persianFormatter: DateFormatter
    
    init() {
        // Setup Persian calendar
        persianCalendar = Calendar(identifier: .persian)
        
        // Setup Persian formatter
        persianFormatter = DateFormatter()
        persianFormatter.calendar = persianCalendar
        persianFormatter.locale = Locale(identifier: "fa_IR")
        
        generateCalendarDays()
    }
    
    var currentPersianDateString: String {
        persianFormatter.dateFormat = "EEEE، d MMMM yyyy"
        return persianFormatter.string(from: Date())
    }
    
    var currentMonthYearString: String {
        persianFormatter.dateFormat = "MMMM yyyy"
        return persianFormatter.string(from: currentDate)
    }
    
    func nextMonth() {
        if let newDate = persianCalendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
            generateCalendarDays()
        }
    }
    
    func previousMonth() {
        if let newDate = persianCalendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
            generateCalendarDays()
        }
    }
    
    func goToToday() {
        currentDate = Date()
        generateCalendarDays()
    }
    
    func isToday(_ day: CalendarDay) -> Bool {
        return gregorianCalendar.isDate(day.gregorianDate, inSameDayAs: Date())
    }
    
    private func generateCalendarDays() {
        guard let monthRange = persianCalendar.range(of: .day, in: .month, for: currentDate) else {
            return
        }
        
        let firstDayOfMonth = persianCalendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        let firstWeekday = persianCalendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [CalendarDay] = []
        
        // Add previous month's trailing days
        let previousMonthDaysToShow = (firstWeekday - 1) % 7
        if previousMonthDaysToShow > 0,
           let previousMonth = persianCalendar.date(byAdding: .month, value: -1, to: currentDate),
           let previousMonthRange = persianCalendar.range(of: .day, in: .month, for: previousMonth) {
            
            let startDay = previousMonthRange.count - previousMonthDaysToShow + 1
            for day in startDay...previousMonthRange.count {
                if let date = persianCalendar.date(byAdding: .day, value: day - 1, to: persianCalendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth) {
                    let persianDay = String(day)
                    days.append(CalendarDay(persianDay: persianDay, gregorianDate: date, isCurrentMonth: false))
                }
            }
        }
        
        // Add current month's days
        for day in monthRange {
            if let date = persianCalendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let persianDay = String(day)
                days.append(CalendarDay(persianDay: persianDay, gregorianDate: date, isCurrentMonth: true))
            }
        }
        
        // Add next month's leading days to fill the grid
        let remainingCells = 42 - days.count // 6 rows × 7 days
        if remainingCells > 0,
           let nextMonth = persianCalendar.date(byAdding: .month, value: 1, to: currentDate) {
            
            for day in 1...remainingCells {
                if let date = persianCalendar.date(byAdding: .day, value: day - 1, to: persianCalendar.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth) {
                    let persianDay = String(day)
                    days.append(CalendarDay(persianDay: persianDay, gregorianDate: date, isCurrentMonth: false))
                }
            }
        }
        
        calendarDays = days
    }
}
