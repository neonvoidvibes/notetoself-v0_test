# Document 11. Detailed User Workflows & Concrete UI Plan

Below is a comprehensive plan outlining **how users will flow through each part of the app** and exactly **what UI elements** they’ll see and interact with. This document expands on **Document 7 (UI/UX)** to provide step‑by‑step workflows, specific layouts, and style guidelines for each view. The goal: produce a **polished, highly engaging app** that feels complete while strictly following our minimalist, fast‑journaling philosophy.

---

## 1. Onboarding Workflow

### 1.1 Purpose
- Introduce new users to the app’s main concept (quick journaling).
- Keep it frictionless—no login, minimal text, an immediate path to the main journal screen.

### 1.2 User Flow

1. **App Launch → OnboardingView**
   - **Visual Layout:**
     - **Background:** Dark charcoal (AppBackground).
     - **Top Spacing:** Generous vertical space at top.
     - **Main Title (“Note to Self”):** 
       - Font: `UIStyles.headingFont` (large, bold, rounded).
       - Color: `UIStyles.textColor`.
       - Centered horizontally.
     - **Subtitle:** 
       - Brief text: “Capture your day in under 30 seconds. No sign-ups, no hassle, just quick reflections.”
       - Font: `UIStyles.bodyFont`.
       - Color: `UIStyles.textColor.opacity(0.8)`.
       - Multiline, centered.
     - **“Get Started” Button:** 
       - Centered below subtitle, uses `UIStyles.PrimaryButtonStyle()` for a bright accent color fill.
       - Tapping triggers transition to **Main Journal View**.
   - **Animated Entry:** 
     - A subtle fade-in or slight spring effect for the text, so it feels inviting.

2. **Transition → MainJournalView**
   - **Animation:** A soft vertical slide or fade (SwiftUI’s `.easeInOut`) to convey momentum into the main experience.

### 1.3 Visual & Interaction Notes
- **No Additional Steps** or sign-up screens—this is crucial to our frictionless promise.
- **Reminders**: We do not overwhelm users with questions; all advanced settings or premium prompts come later.

---

## 2. Main Journal View

### 2.1 Purpose
- Provide a quick overview of daily entries, streaks, and an easy “Add Entry” action.
- Present the timeline in a clear, scrollable list (or card layout) with minimal clutter.

### 2.2 Layout & Elements

1. **Top Bar / Header Row**
   - **Title:** “Daily Journal”
     - Font: `UIStyles.headingFont` (bold, ~26pt).
     - Color: `UIStyles.textColor`.
   - **New Entry Button (Plus Icon):**
     - Icon: system “plus.circle.fill”.
     - Size: ~28×28 points.
     - Color: `UIStyles.accentColor`.
     - Right‑aligned in the header row.
     - Tapping opens the **New Entry Sheet** (covered below).

2. **Daily Streak View**
   - A small subheading (or horizontal block) displaying “Current Streak: X day(s)”
     - Font: `UIStyles.bodyFont`.
     - Color: `UIStyles.textColor`.
   - **Placement**: Immediately under the header row (slight padding).
   - Example styling: `HStack` with a flame icon or simple dot icons to highlight the streak if desired. Keep subtle so it doesn't distract.

3. **Timeline / Scrollable List of Entries**
   - **Container**: A `ScrollView` or `List` that holds a vertical stack of entry “cards.”
   - **Entry Cards**:
     - **Appearance**:
       - Use `UIStyles.Card` for a dark, rounded rectangle look (`cardBackground` color, cornerRadius=12, a slight shadow).
       - Within each card:
         - **Date:** Larger or smaller label showing the date in short format (e.g., “Mar 18, 2025”).
           - Style: `UIStyles.smallLabelFont`, color ~ `UIStyles.textColor.opacity(0.6)`.
         - **Mood** (if present): “Mood: <mood string>” in `UIStyles.bodyFont` with `UIStyles.accentColor`.
         - **Text** (if present): The actual journal note, using `UIStyles.bodyFont` and `UIStyles.textColor`.
       - **Vertical spacing**: ~8-12 points inside the card between these items.
     - **Ordering**: Reverse chronological (newest at the top).
   - **Behavior**:
     - Tapping on a card (if we want an expanded state later) can show a slightly larger view or text. But in v1, we might keep it read-only.

4. **Screen Background & Padding**
   - Entire view sits on `UIStyles.appBackground`.
   - Outer padding: `UIStyles.globalHorizontalPadding` horizontally, `UIStyles.globalVerticalPadding` top/bottom.

5. **Navigation**
   - No dedicated back button here because this is the main screen. The left side could be empty or we might have a subtle Settings button in the future on the left. But currently, the doc just uses the “Settings” or “Back” in top-left if we add more sections. For now, we can keep it minimal.

### 2.3 Interaction & Transitions
- **Pull to Refresh** not necessary since data is local. The timeline updates instantly when returning from a new entry.
- **Sheet Presentation** for “New Entry” to maintain the single-screen approach.

---

## 3. New Entry Sheet

### 3.1 Purpose
- Let users add a **quick** entry: choose mood + short text. 
- Keep the flow minimal and fluid so it “feels like a 30-second daily reflection.”

### 3.2 Layout & Elements

1. **Navigation Bar (Modal)**
   - **Title**: “Add Quick Entry”
     - Font: `UIStyles.headingFont`.
     - Color: `UIStyles.textColor`.
   - **Cancel Button**: top-left “Cancel” link, color `UIStyles.accentColor`, dismisses the sheet (no entry saved).
   - **Done/Save Button** could appear in top-right, or we can place a dedicated “Save” button within the body. (See next point.)

2. **Body Content**
   - **Mood Picker**:
     - A horizontal scroll of mood “chips” or “buttons.”  
       - Example moods: “Happy,” “Neutral,” “Sad,” “Stressed,” “Excited.”
       - Each chip uses a small pill shape with background color:
         - If selected → fill with `UIStyles.accentColor`, text color = `.white`.
         - If not selected → fill with `UIStyles.cardBackground`, text color = `UIStyles.textColor`.
       - Spacing ~12 points between chips.
     - The user taps to select exactly one mood. Tapping again can re-select or switch.
   - **TextEditor**:
     - Large multiline area for typed text (height ~120 points).
     - Font: `UIStyles.bodyFont`.
     - Background color: `UIStyles.cardBackground`.
     - Corner radius ~8. 
     - Optional placeholder “Write a short note...” or we rely on SwiftUI placeholders.
   - **Save Button**:
     - Positioned at the bottom in a horizontal row:
       - Possibly an alignment with “Cancel” on the left, “Save” on the right or a single centered “Save” if we rely on the nav bar for Cancel. 
       - Using `UIStyles.PrimaryButtonStyle()` for a bold accent.
       - Tapping triggers immediate creation of a new JournalEntry in Core Data, closes the sheet.

3. **Background & Style**
   - Entire sheet background: `UIStyles.appBackground`.
   - Use `.sheet(...)` or `NavigationView` with `.toolbar` for the top bar.

### 3.3 Interaction & Transitions
- **Appear**: Slide up from bottom (default iOS sheet).
- **Disappear**: Slide down or “Cancel,” returns to MainJournalView with new entry inserted at top.

---

## 4. Settings / Customization (Future or Optional for v1)

*(If we follow Document 7’s minimal approach, we might not have a dedicated settings screen in v1, but here’s the plan if we include it soon.)*

### 4.1 Purpose
- Provide user with accent color choices, dark/light mode toggle, basic preferences (reminders on/off, etc.)

### 4.2 Layout & Elements
1. **Header**: 
   - “Settings” label in large heading font.
   - “Close” or “Back” button on left, or a top-left chevron. 
2. **List of Toggles & Options**:
   - **Dark/Light Mode**: Switch or segment to pick system default, or always dark, or always light.  
   - **Accent Color**: Horizontal list of color swatches in small circles. Tapping changes `UIStyles.accentColor`.  
   - **Notifications**: Toggle to allow daily reminders. (We’d prompt for permission, then store preference.)
   - Possibly a link “Upgrade to Premium” or in-app purchase screen if we have it. Keep minimal for now.

3. **Styling**:
   - A `List` or `VStack` with each row in `UIStyles.cardBackground`, spaced with generous padding.
   - Headings in `UIStyles.bodyFont`, accent on toggles.

### 4.3 Navigation & Transition
- Access via a small gear icon top-left or top-right from the main screen.
- Slide in from right (push navigation) or present modally.

---

## 5. Extended Analytics / Mood Charts (Planned for Future Release)

### 5.1 Purpose
- Show the user a line chart or calendar heat map with moods, streak data, etc.

### 5.2 Layout & Elements
1. **Summary Header**: “Your Weekly/Monthly Mood,” large bold font. 
2. **Chart**: SwiftUI’s `Chart` with a single stroke line in `UIStyles.accentColor`.  
3. **Stats**: e.g., average mood, total entries, longest streak.  
4. **Background**: same dark style, with partial card backgrounds for each stat.  
5. **Navigation**: Possibly a tab or a button from Main Journal to “View Insights,” transitions to the chart view.

---

## 6. Style Details & Visual Elements (Expanded)

Below are more explicit style references to ensure consistency across all views.

### 6.1 Colors & Theme

- **`UIStyles.appBackground`**:  
  - Named “AppBackground” in Assets. A near-black (RGB ~ 0.09,0.09,0.09).
- **`UIStyles.cardBackground`**:  
  - Slightly lighter charcoal (RGB ~ 0.15,0.15,0.15).
  - Used behind cards, text fields.
- **`UIStyles.accentColor`**:  
  - Vibrant highlight (we currently use a greenish or bright color from the assets). 
  - Used on buttons, icons, mood highlights.

### 6.2 Typography

- **Heading Font**: `UIStyles.headingFont` = system size ~26–28, .bold, .rounded  
  - Typically near-white text color (`UIStyles.textColor`).
- **Body Font**: `UIStyles.bodyFont` = system size 16–18, .regular, .rounded  
- **Small Label Font**: `UIStyles.smallLabelFont` = system size 14, .regular, .rounded

### 6.3 Spacing & Corners

- **Global Horizontal Padding**: 20 points left/right on major views.  
- **Global Vertical Padding**: 16 points top/bottom for major screens.  
- **Card CornerRadius**: 12 points.  
- **Button CornerRadius**: 8 points (for primary CTA).

### 6.4 Animations & Transitions

- **Taps**: Slight scale effect on press (0.95 scale).  
- **Sheets**: Standard iOS bottom-to-top.  
- **Navigation**: Usually a slide from right for pushes, fade for modals if we want subtlety.

---

## 7. Example Screen Flow Summary

Here’s the simplest path a user might take on a typical day:

1. **Open App →** sees the OnboardingView **only once** if new, else it goes directly to MainJournalView.  
2. **MainJournalView**:
   - Title = “Daily Journal.”
   - Sees “Current Streak: 4 days.”
   - Scrolls to see previous entries in card form.
   - Taps the plus icon → triggers NewEntrySheet.
3. **NewEntrySheet**:
   - Selects “Happy” mood chip.
   - Types a quick note: “Feeling productive after finishing my tasks!”
   - Taps “Save.”
   - Sheet dismisses, returning to MainJournalView with a new card at the top.

This entire process should feel **instant, minimal,** and **visually consistent** with the dark theme, accent color, and neat typography.

---

## 8. Polishing Touches

- **Shadows on Cards**: A subtle drop shadow (`.shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)`) to lift them from the background.  
- **Hover Effects / Press States**: For iPad or macOS Catalyst, we could show a mild highlight when hovering. (Not mandatory for v1 mobile.)  
- **Haptic Feedback**: 
  - A soft “tap” haptic upon saving entry or toggling a mood chip can make the app feel refined. 
  - Use `.impactOccurred(intensity: 0.5)` in Swift.

---

## 9. Future “Premium” UI Callouts (Optional)

If we introduce an upgrade path:

- **Premium Banner**: A small card or banner on the MainJournalView: “Unlock advanced insights—Get Premium.”
- **Settings**: “Upgrade to Premium” item. Tapping it → a sheet describing extra features (mood charts, custom themes, etc.) with a purchase button. Maintain the **same styling** as the rest: minimal, accent color, dark background.

---

## 10. Conclusion

This **Document 11** provides the **step‑by‑step user flows** and **exact UI structures** for every main view:

1. **Onboarding** → minimal, gets user started.
2. **Main Journal** → displays streak, scrollable entries, easy “+” button.
3. **New Entry** → ultra-fast mood + text, saving back to main timeline.
4. *(Optional)* **Settings** → toggles, theme or accent color selection.
5. *(Future)* **Analytics** → mood charts, advanced stats in a dedicated view.

Throughout, we adhere to the **dark, high-contrast minimalism** from Document 7. The final look is **sleek, frictionless**, and elegantly encourages daily micro-journaling with as few taps as possible. By **implementing these specific layouts and styles**, we’ll deliver a **polished, complete-feeling app** that stands out for its simplicity and speed—fulfilling our core promise: **“Capture your day in under 30 seconds.”**