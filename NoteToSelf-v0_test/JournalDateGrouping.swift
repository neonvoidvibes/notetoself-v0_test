import SwiftUI

// Structure to handle date grouping for journal entries
struct JournalDateGrouping {
    // Group entries by time period
    static func groupEntriesByTimePeriod(_ entries: [JournalEntry]) -> [(String, [JournalEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Calculate start of current week and last week
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        // Remove this line: let twoWeeksAgoStart = calendar.date(byAdding: .weekOfYear, value: -1, to: lastWeekStart)!

        // Calculate start of current month
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        // Dictionary to store entries by section
        var entriesBySection: [String: [JournalEntry]] = [:]
        
        for entry in entries {
            let entryDate = calendar.startOfDay(for: entry.date)
            let entryMonth = calendar.component(.month, from: entry.date)
            let entryYear = calendar.component(.year, from: entry.date)
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            if calendar.isDate(entryDate, inSameDayAs: today) {
                // Today
                let sectionKey = "Today"
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            } else if calendar.isDate(entryDate, inSameDayAs: yesterday) {
                // Yesterday
                let sectionKey = "Yesterday"
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            } else if entryDate >= currentWeekStart && entryDate < yesterday {
                // This Week (excluding today and yesterday)
                let sectionKey = "This Week"
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            } else if entryDate >= lastWeekStart && entryDate < currentWeekStart {
                // Last Week
                let sectionKey = "Last Week"
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            } else if entryDate >= currentMonthStart && entryDate < lastWeekStart {
                // This Month (excluding this week and last week)
                let sectionKey = "This Month"
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            } else if entryYear == currentYear && entryMonth != currentMonth {
                // Same year, different month
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMMM"
                let sectionKey = monthFormatter.string(from: entry.date)
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            } else {
                // Different year
                let yearMonthFormatter = DateFormatter()
                yearMonthFormatter.dateFormat = "yyyy\nMMMM"
                let sectionKey = yearMonthFormatter.string(from: entry.date)
                if entriesBySection[sectionKey] == nil {
                    entriesBySection[sectionKey] = []
                }
                entriesBySection[sectionKey]?.append(entry)
            }
        }
        
        // Sort entries within each section by date (newest first)
        for (key, value) in entriesBySection {
            entriesBySection[key] = value.sorted(by: { $0.date > $1.date })
        }
        
        // Sort sections by chronological order (newest first)
        let sortedSections = entriesBySection.sorted { (section1, section2) -> Bool in
            let order: [String] = ["Today", "Yesterday", "This Week", "Last Week", "This Month"]
            
            if let index1 = order.firstIndex(of: section1.key), let index2 = order.firstIndex(of: section2.key) {
                return index1 < index2
            } else if order.contains(section1.key) {
                return true
            } else if order.contains(section2.key) {
                return false
            } else {
                // For month and year\nmonth sections, sort by the date of the first entry
                return section1.value.first?.date ?? Date() > section2.value.first?.date ?? Date()
            }
        }
        
        return sortedSections
    }
}

// Removed DateGroupSectionHeader component as it's replaced by StickyListHeader