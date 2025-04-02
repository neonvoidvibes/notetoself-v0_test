import SwiftUI

struct WeeklyPatternsDetailContent: View {
  let entries: [JournalEntry]
  let styles = UIStyles.shared
  
  // Add missing properties
  private var weeklyEntries: [JournalEntry] {
      return entries.filter { Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 <= 7 }
  }
  
  private var weekdayMoodData: [DayOfWeek: [JournalEntry]] {
      var result: [DayOfWeek: [JournalEntry]] = [:]
      for entry in weeklyEntries {
          let dayOfWeek = DayOfWeek(from: entry.date)
          if result[dayOfWeek] == nil {
              result[dayOfWeek] = []
          }
          result[dayOfWeek]?.append(entry)
      }
      return result
  }
  
  private var timeOfDayMoodData: [TimeOfDay: [JournalEntry]] {
      var result: [TimeOfDay: [JournalEntry]] = [:]
      for entry in weeklyEntries {
          let timeOfDay = TimeOfDay(from: entry.date)
          if result[timeOfDay] == nil {
              result[timeOfDay] = []
          }
          result[timeOfDay]?.append(entry)
      }
      return result
  }
  
  var body: some View {
      ScrollView {
          VStack(spacing: styles.layout.spacingXL) {
              // Header
              VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                  Text("Weekly Patterns")
                      .font(.largeTitle)
                      .fontWeight(.bold)
                  
                  Text("Insights based on your journal entries from the past week")
                      .font(.body)
                      .foregroundColor(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              
              // Day of Week Analysis
              VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                  Text("Day of Week Analysis")
                      .font(.title2)
                      .fontWeight(.bold)
                  
                  Text("How your mood varies across different days of the week")
                      .font(.body)
                      .foregroundColor(.secondary)
                  
                  // Day of Week Chart
                  dayOfWeekChart()
                      .frame(height: 200)
                      .padding(.vertical)
                  
                  // Day of Week Insights
                  ForEach(generateDayOfWeekInsights(), id: \.self) { insight in
                      Text("• \(insight)")
                          .font(.body)
                          .padding(.vertical, 4)
                  }
              }
              .padding()
              .background(Color(.secondarySystemBackground))
              .cornerRadius(styles.layout.radiusL)
              .padding(.horizontal)
              
              // Time of Day Analysis
              VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                  Text("Time of Day Analysis")
                      .font(.title2)
                      .fontWeight(.bold)
                  
                  Text("How your mood varies throughout the day")
                      .font(.body)
                      .foregroundColor(.secondary)
                  
                  // Time of Day Chart
                  timeOfDayChart()
                      .frame(height: 200)
                      .padding(.vertical)
                  
                  // Time of Day Insights
                  ForEach(generateTimeOfDayInsights(), id: \.self) { insight in
                      Text("• \(insight)")
                          .font(.body)
                          .padding(.vertical, 4)
                  }
              }
              .padding()
              .background(Color(.secondarySystemBackground))
              .cornerRadius(styles.layout.radiusL)
              .padding(.horizontal)
              
              // Combined Insights
              VStack(alignment: .leading, spacing: styles.layout.spacingM) {
                  Text("Combined Insights")
                      .font(.title2)
                      .fontWeight(.bold)
                  
                  Text("Patterns that emerge when combining day and time analysis")
                      .font(.body)
                      .foregroundColor(.secondary)
                  
                  // Combined Insights
                  ForEach(generateCombinedInsights(), id: \.self) { insight in
                      Text("• \(insight)")
                          .font(.body)
                          .padding(.vertical, 4)
                  }
              }
              .padding()
              .background(Color(.secondarySystemBackground))
              .cornerRadius(styles.layout.radiusL)
              .padding(.horizontal)
          }
          .padding(.vertical)
      }
  }
  
  // MARK: - Helper Methods
  
  private func dayOfWeekChart() -> some View {
      HStack(alignment: .bottom, spacing: 12) {
          ForEach(DayOfWeek.allCases, id: \.self) { day in
              // Break down complex expressions
              let entries = weekdayMoodData[day] ?? []
              let moodValues = entries.map { moodToDouble($0.mood) }
              let avgMood: Double = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
              let barHeight = avgMood * 150 / 5.0 // Scale to fit in 150pt height
              
              VStack {
                  ZStack(alignment: .bottom) {
                      Rectangle()
                          .fill(Color.gray.opacity(0.2))
                          .frame(width: 30, height: 150)
                      
                      Rectangle()
                          .fill(moodColor(for: avgMood))
                          .frame(width: 30, height: max(barHeight, 5))
                  }
                  .cornerRadius(5)
                  
                  Text(day.shortName)
                      .font(.caption)
                      .padding(.top, 4)
              }
          }
      }
      .padding(.horizontal)
  }
  
  private func timeOfDayChart() -> some View {
      HStack(alignment: .bottom, spacing: 12) {
          ForEach(TimeOfDay.allCases, id: \.self) { time in
              // Break down complex expressions
              let entries = timeOfDayMoodData[time] ?? []
              let moodValues = entries.map { moodToDouble($0.mood) }
              let avgMood: Double = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
              let barHeight = avgMood * 150 / 5.0 // Scale to fit in 150pt height
              
              VStack {
                  ZStack(alignment: .bottom) {
                      Rectangle()
                          .fill(Color.gray.opacity(0.2))
                          .frame(width: 30, height: 150)
                      
                      Rectangle()
                          .fill(moodColor(for: avgMood))
                          .frame(width: 30, height: max(barHeight, 5))
                  }
                  .cornerRadius(5)
                  
                  Text(time.name)
                      .font(.caption)
                      .padding(.top, 4)
              }
          }
      }
      .padding(.horizontal)
  }
  
  // Helper function to convert Mood to Double
  private func moodToDouble(_ mood: Mood) -> Double {
    // Map moods to numeric values based on valence (negative to positive)
    switch mood {
    case .sad, .depressed: return 1.0 // Most negative
    case .bored, .anxious, .angry: return 2.0 // Somewhat negative
    case .neutral, .stressed: return 3.0 // Neutral
    case .calm, .relaxed, .content: return 4.0 // Somewhat positive
    case .happy, .excited, .alert: return 5.0 // Most positive
    }
  }
  
  private func moodColor(for moodValue: Double) -> Color {
      // Determine the approximate mood enum based on the numeric value
      // This is an approximation and might need adjustment based on moodToDouble logic
      if moodValue >= 4.5 { return Mood.excited.color }
      else if moodValue >= 3.5 { return Mood.happy.color }
      else if moodValue >= 2.5 { return Mood.neutral.color }
      else if moodValue >= 1.5 { return Mood.stressed.color } // Or anxious/angry
      else if moodValue > 0 { return Mood.sad.color } // Or depressed
      else { return styles.colors.textSecondary } // Default for 0 (no entry)
  }
  
  private func generateDayOfWeekInsights() -> [String] {
      var insights: [String] = []
      
      if weeklyEntries.isEmpty {
          insights.append("Not enough data to generate insights. Try journaling more regularly throughout the week.")
          return insights
      }
      
      // Find best and worst days
      var bestDay: (day: DayOfWeek, mood: Double) = (.monday, 0)
      var worstDay: (day: DayOfWeek, mood: Double) = (.monday, 5)
      
      for (day, entries) in weekdayMoodData {
          if !entries.isEmpty {
              // Break down complex expressions
              let moodValues = entries.map { moodToDouble($0.mood) }
              let avgMood: Double = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
              
              if avgMood > bestDay.mood {
                  bestDay = (day, avgMood)
              }
              
              if avgMood < worstDay.mood {
                  worstDay = (day, avgMood)
              }
          }
      }
      
      if bestDay.mood > 0 {
          insights.append("\(bestDay.day.name) is your best day of the week with an average mood of \(String(format: "%.1f", bestDay.mood))/5.")
      }
      
      if worstDay.mood < 5 {
          insights.append("\(worstDay.day.name) is your most challenging day with an average mood of \(String(format: "%.1f", worstDay.mood))/5.")
      }
      
      // Compare weekday vs weekend moods
      let weekdayMoods = weeklyEntries.filter { !$0.date.isWeekend }
      let weekendMoods = weeklyEntries.filter { $0.date.isWeekend }
      
      if !weekdayMoods.isEmpty && !weekendMoods.isEmpty {
          // Break down complex expressions
          let weekdayMoodValues = weekdayMoods.map { moodToDouble($0.mood) }
          let avgWeekdayMood: Double = weekdayMoodValues.isEmpty ? 0 : weekdayMoodValues.reduce(0, +) / Double(weekdayMoodValues.count)
          
          let weekendMoodValues = weekendMoods.map { moodToDouble($0.mood) }
          let avgWeekendMood: Double = weekendMoodValues.isEmpty ? 0 : weekendMoodValues.reduce(0, +) / Double(weekendMoodValues.count)
          
          if avgWeekendMood > avgWeekdayMood + 0.5 {
              insights.append("Your mood is significantly better on weekends compared to weekdays. Consider how you might bring more weekend-like activities into your weekdays.")
          } else if avgWeekdayMood > avgWeekendMood + 0.5 {
              insights.append("Interestingly, your mood is better during weekdays than on weekends. Reflect on what aspects of your work or routine might be contributing positively.")
          }
      }
      
      return insights
  }
  
  private func generateTimeOfDayInsights() -> [String] {
      var insights: [String] = []
      
      if weeklyEntries.isEmpty {
          insights.append("Not enough data to generate insights. Try journaling at different times of the day.")
          return insights
      }
      
      // Find best and worst times
      var bestTime: (time: TimeOfDay, mood: Double) = (.morning, 0)
      var worstTime: (time: TimeOfDay, mood: Double) = (.morning, 5)
      
      for (time, entries) in timeOfDayMoodData {
          if !entries.isEmpty {
              // Break down complex expressions
              let moodValues = entries.map { moodToDouble($0.mood) }
              let avgMood: Double = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
              
              if avgMood > bestTime.mood {
                  bestTime = (time, avgMood)
              }
              
              if avgMood < worstTime.mood {
                  worstTime = (time, avgMood)
              }
          }
      }
      
      if bestTime.mood > 0 {
          insights.append("Your mood is typically best during the \(bestTime.time.name.lowercased()) with an average of \(String(format: "%.1f", bestTime.mood))/5.")
      }
      
      if worstTime.mood < 5 {
          insights.append("Your mood tends to dip during the \(worstTime.time.name.lowercased()) with an average of \(String(format: "%.1f", worstTime.mood))/5.")
      }
      
      return insights
  }
  
  private func generateCombinedInsights() -> [String] {
      var insights: [String] = []
      
      if weeklyEntries.isEmpty {
          insights.append("Not enough data to generate combined insights. Continue journaling regularly at different times and days.")
          return insights
      }
      
      // Find best day-time combination
      var bestCombination: (day: DayOfWeek, time: TimeOfDay, mood: Double) = (.monday, .morning, 0)
      
      for (day, dayEntries) in weekdayMoodData {
          for (time, _) in timeOfDayMoodData {
              // Find entries that match both this day and time
              let combinedEntries = dayEntries.filter { entry in
                  TimeOfDay(from: entry.date) == time
              }
              
              if !combinedEntries.isEmpty {
                  // Break down complex expressions
                  let moodValues = combinedEntries.map { moodToDouble($0.mood) }
                  let avgMood: Double = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
                  
                  if avgMood > bestCombination.mood {
                      bestCombination = (day, time, avgMood)
                  }
              }
          }
      }
      
      if bestCombination.mood > 0 {
          insights.append("Your optimal time appears to be \(bestCombination.day.name) \(bestCombination.time.name.lowercased()), when your average mood is \(String(format: "%.1f", bestCombination.mood))/5.")
          insights.append("Consider scheduling important or challenging activities during this time when possible.")
      }
      
      return insights
  }
}

// MARK: - Helper Types

enum DayOfWeek: Int, CaseIterable {
  case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
  
  var name: String {
      switch self {
      case .sunday: return "Sunday"
      case .monday: return "Monday"
      case .tuesday: return "Tuesday"
      case .wednesday: return "Wednesday"
      case .thursday: return "Thursday"
      case .friday: return "Friday"
      case .saturday: return "Saturday"
      }
  }
  
  var shortName: String {
      return String(name.prefix(3))
  }
  
  init(from date: Date) {
      let weekday = Calendar.current.component(.weekday, from: date)
      self = DayOfWeek(rawValue: weekday) ?? .sunday
  }
}

enum TimeOfDay: Int, CaseIterable {
  case morning, afternoon, evening, night
  
  var name: String {
      switch self {
      case .morning: return "Morning"
      case .afternoon: return "Afternoon"
      case .evening: return "Evening"
      case .night: return "Night"
      }
  }
  
  init(from date: Date) {
      let hour = Calendar.current.component(.hour, from: date)
      switch hour {
      case 5..<12: self = .morning
      case 12..<17: self = .afternoon
      case 17..<21: self = .evening
      default: self = .night
      }
  }
}

extension Date {
  var isWeekend: Bool {
      let weekday = Calendar.current.component(.weekday, from: self)
      return weekday == 1 || weekday == 7 // Sunday or Saturday
  }
}