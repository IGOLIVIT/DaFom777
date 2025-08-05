//
//  Extensions.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI
import Foundation

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // App Color Scheme
    static let appBackground = Color(hex: "#3e4464")
    static let appAccent = Color(hex: "#fcc418")
    static let appSuccess = Color(hex: "#3cc45b")
    static let appDanger = Color(hex: "#e74c3c")
    static let appWarning = Color(hex: "#f39c12")
    static let appInfo = Color(hex: "#3498db")
    
    // Task Priority Colors
    static let priorityLow = Color(hex: "#3cc45b")
    static let priorityMedium = Color(hex: "#fcc418")
    static let priorityHigh = Color(hex: "#ff6b35")
    static let priorityUrgent = Color(hex: "#e74c3c")
    
    // Card and Surface Colors
    static let cardBackground = Color(.systemBackground)
    static let surfaceBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
}

// MARK: - Date Extensions

extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func timeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func relativeDateString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func endOfDay() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay()) ?? self
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - String Extensions

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    var initials: String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        let initials = components.compactMap { $0.first }.map { String($0).uppercased() }
        return initials.joined()
    }
    
    func highlight(query: String, color: Color = .appAccent) -> AttributedString {
        var attributed = AttributedString(self)
        
        if !query.isEmpty,
           let range = self.range(of: query, options: .caseInsensitive) {
            let attributedRange = AttributedString.Index(range.lowerBound, within: attributed)!..<AttributedString.Index(range.upperBound, within: attributed)!
            attributed[attributedRange].backgroundColor = color.opacity(0.3)
        }
        
        return attributed
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.appAccent)
            .foregroundColor(.black)
            .cornerRadius(25)
            .font(.headline)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.clear)
            .foregroundColor(.appAccent)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.appAccent, lineWidth: 2)
            )
            .font(.headline)
    }
    
    func navigationBarTitleStyle() -> some View {
        self
            .font(.largeTitle.bold())
            .foregroundColor(.primary)
    }
    
    func sectionHeaderStyle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
    
    func taskRowStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .cornerRadius(8)
    }
    
    func priorityBadge(_ priority: TaskPriority) -> some View {
        self
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: priority.color))
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.caption)
            .font(.headline.weight(.semibold))
    }
    
    func statusBadge(_ status: TaskStatus) -> some View {
        let color: Color = switch status {
        case .todo: .appInfo
        case .inProgress: .appWarning
        case .review: .appAccent
        case .completed: .appSuccess
        case .cancelled: .appDanger
        }
        
        return self
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
            .font(.caption)
            .font(.headline.weight(.semibold))
    }
    
    func progressBar(progress: Double, color: Color = .appAccent) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress / 100), height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
        }
    }
    
    func errorAlert(isPresented: Binding<Bool>, message: String) -> some View {
        self.alert("Error", isPresented: isPresented) {
            Button("OK") { }
        } message: {
            Text(message)
        }
    }
    
    func confirmationAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmAction: @escaping () -> Void
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                confirmAction()
            }
        } message: {
            Text(message)
        }
    }
}

// MARK: - Custom View Modifiers

struct ShakeEffect: ViewModifier {
    let shakes: Int
    let animatableData: CGFloat
    
    init(shakes: Int) {
        self.shakes = shakes
        self.animatableData = CGFloat(shakes)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: sin(animatableData * .pi * 2) * 5)
    }
}

struct PulseEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .blur(radius: radius)
                    .opacity(0.6)
            )
            .foregroundColor(color)
    }
}

// MARK: - View Modifier Extensions

extension View {
    func shake(with shakes: Int) -> some View {
        modifier(ShakeEffect(shakes: shakes))
    }
    
    func pulse() -> some View {
        modifier(PulseEffect())
    }
    
    func glow(color: Color = .appAccent, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Custom Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Loading States

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .appAccent))
                .scaleEffect(1.5)
            
            Text(message)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceBackground.opacity(0.8))
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(.appAccent)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .primaryButtonStyle()
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Performance Extensions

extension View {
    func animationsDisabled(_ disabled: Bool = true) -> some View {
        transaction { transaction in
            transaction.animation = disabled ? nil : transaction.animation
        }
    }
}

// MARK: - Accessibility Extensions

extension View {
    func accessibilityLabel(_ key: String, value: String) -> some View {
        self.accessibilityLabel("\(key): \(value)")
    }
    
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }
}