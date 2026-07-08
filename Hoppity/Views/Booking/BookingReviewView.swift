import SwiftUI
import UIKit
import Supabase

struct BookingReviewView: View {
    let tour: Tour
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var numPersons = 1
    @State private var selectedDate = Date()
    @State private var specialRequest = ""
    @State private var isBooking = false
    @State private var bookingDone = false

    private var subtotal: Double  { Double(numPersons) * (tour.pricePerPerson ?? 0) }
    private var platformFee: Double { (subtotal * 0.03).rounded() }
    private var total: Double     { subtotal + platformFee }

    private func formatPrice(_ p: Double) -> String {
        if p >= 100000 { return "₹\(String(format: "%.1f", p/100000))L" }
        if p >= 1000   { return "₹\(String(format: "%.0f", p/1000))K" }
        return "₹\(Int(p))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Hero
                    HoppityImage(url: tour.coverImageUrl)
                        .frame(maxWidth: .infinity).frame(height: 200).clipped()

                    VStack(alignment: .leading, spacing: 16) {

                        // Tour name + location
                        Text(tour.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#020617"))

                        if let loc = tour.location {
                            Label(loc, systemImage: "mappin.circle.fill")
                                .font(AppTheme.F.body)
                                .foregroundColor(AppTheme.textSub)
                        }

                        Divider()

                        // Number of persons
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Number of Persons")
                                .font(AppTheme.F.sectionH)
                            HStack(spacing: 20) {
                                Button(action: { if numPersons > 1 { numPersons -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppTheme.primary)
                                }
                                Text("\(numPersons)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                Button(action: { numPersons += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppTheme.primary)
                                }
                                Spacer()
                            }
                        }

                        Divider()

                        // Date picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Date").font(AppTheme.F.sectionH)
                            DatePicker(
                                "Travel Date",
                                selection: $selectedDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        }

                        Divider()

                        // Special request
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Special Request (optional)")
                                .font(AppTheme.F.sectionH)
                            TextEditor(text: $specialRequest)
                                .font(AppTheme.F.body)
                                .frame(height: 80)
                                .padding(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.border)
                                )
                        }

                        Divider()

                        // Price breakdown
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Price Summary").font(AppTheme.F.sectionH)
                            priceRow(
                                label: "\(numPersons) × \(tour.formattedPrice)",
                                value: formatPrice(subtotal)
                            )
                            priceRow(
                                label: "Platform fee (3%)",
                                value: formatPrice(platformFee)
                            )
                            Divider()
                            priceRow(
                                label: "Total",
                                value: formatPrice(total),
                                bold: true
                            )
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(16)
                }
            }
            .background(Color.white)
            .navigationTitle("Review Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { confirmButton }
            .alert("Booking Confirmed!", isPresented: $bookingDone) {
                Button("Done") { dismiss() }
            } message: {
                Text("We'll contact you shortly to confirm your trip.")
            }
        }
    }

    private func priceRow(label: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? AppTheme.F.bodyB : AppTheme.F.body)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .font(bold ? AppTheme.F.bodyB : AppTheme.F.body)
                .foregroundColor(bold ? AppTheme.primary : .black)
        }
    }

    private var confirmButton: some View {
        Button(action: confirmBooking) {
            HStack {
                if isBooking {
                    ProgressView().tint(.white).scaleEffect(0.8)
                }
                Text("Confirm — \(formatPrice(total))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.black).clipShape(Capsule())
            .padding(.horizontal, 24).padding(.vertical, 14)
        }
        .background(
            Color.white.shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
        .disabled(isBooking)
    }

    private func confirmBooking() {
        let dateStr = DateFormatter.localizedString(
            from: selectedDate, dateStyle: .medium, timeStyle: .none
        )
        let msg = "Hi Hoppity, I'd like to book \"\(tour.title)\" for \(numPersons) person(s) on \(dateStr). Total: \(formatPrice(total))"
        launchWhatsApp(tourTitle: msg)
        bookingDone = true
    }
}
