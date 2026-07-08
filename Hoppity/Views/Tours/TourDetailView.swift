import SwiftUI

struct TourDetailView: View {
    let tour: Tour
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthManager

    @State private var selectedImage = 0
    @State private var isSaved = false
    @State private var showBooking = false
    @State private var showAuth = false

    private var allImages: [String] {
        var imgs = [String]()
        if let p = tour.coverImageUrl { imgs.append(p) }
        imgs += (tour.images ?? []).filter { $0 != tour.coverImageUrl }
        return imgs
    }

    var body: some View {
        ZStack {
            Color(hex: "#F7F1FF").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    thumbnailStrip
                    contentPanel
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        // safeAreaInset stacks above our dark nav (which also uses safeAreaInset)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(isPresented: $showBooking) {
            BookingReviewView(tour: tour).environmentObject(auth)
        }
        .sheet(isPresented: $showAuth) {
            SignInView().environmentObject(auth)
        }
        .onAppear {
            Task {
                if let uid = auth.currentUser?.userId {
                    isSaved = await TourService.shared.isTourSaved(tourId: tour.id, userId: uid)
                }
            }
        }
    }

    // MARK: - Hero (300px full bleed, Figma spec)
    // FIX: uses .overlay() instead of .position() — position() removes view from
    // layout flow causing ZStack to mis-calculate bounds on selectedImage change
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Full bleed image — changes on selectedImage tap
            HoppityImage(url: allImages.isEmpty ? nil : allImages[selectedImage])
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()

            // Bottom gradient
            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .bottom,
                endPoint: .init(x: 0.5, y: 0.4)
            )
            .frame(height: 120)
        }
        .frame(height: 300)
        // Back button — top left via overlay (safe, doesn't affect layout flow)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.40))
                    .clipShape(Circle())
            }
            .padding(.top, 56)   // below status bar
            .padding(.leading, 16)
        }
        // Heart + Share — top right via overlay
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                Button(action: toggleSave) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundColor(isSaved ? AppTheme.primary : .white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.40))
                        .clipShape(Circle())
                }
                Button(action: shareTour) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.40))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 56)
            .padding(.trailing, 16)
        }
    }

    // MARK: - Thumbnail strip (Figma: 56×32, radius 6, white bg)
    @ViewBuilder
    private var thumbnailStrip: some View {
        if allImages.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(allImages.enumerated()), id: \.offset) { i, img in
                        HoppityImage(url: img)
                            .frame(width: 56, height: 32)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        i == selectedImage ? AppTheme.primary : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .onTapGesture { selectedImage = i }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.white)
        }
    }

    // MARK: - White content panel
    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title block
            VStack(alignment: .leading, spacing: 12) {
                // Category badge (#FFEDD5 peach, teal text)
                if let cat = tour.tag ?? tour.category {
                    Text(cat)
                        .font(AppTheme.F.smallB)
                        .foregroundColor(AppTheme.teal)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Color(hex: "#FFEDD5"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Title
                Text(tour.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#020617"))
                    .fixedSize(horizontal: false, vertical: true)

                // Location + duration
                HStack(spacing: 16) {
                    if let loc = tour.location {
                        Label(loc, systemImage: "mappin.circle.fill")
                            .font(AppTheme.F.caption)
                            .foregroundColor(AppTheme.textSub)
                    }
                    if !tour.durationText.isEmpty {
                        Label(tour.durationText, systemImage: "clock")
                            .font(AppTheme.F.caption)
                            .foregroundColor(AppTheme.textSub)
                    }
                }

                // Stat chips
                FlowLayout(spacing: 8) {
                    if let diff = tour.difficulty {
                        StatChip(icon: "chart.bar.fill", label: diff, color: tour.difficultyColor)
                    }
                    if let max = tour.maxGroupSize {
                        StatChip(icon: "person.2.fill", label: "Max \(max)")
                    }
                    if let r = tour.rating, r > 0 {
                        StatChip(icon: "star.fill",
                                 label: "\(String(format: "%.1f", r)) (\(tour.reviewCount ?? 0))",
                                 color: .yellow)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            panelDivider

            // Description
            if let blurb = tour.blurb, !blurb.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("About this tour").font(AppTheme.F.sectionH)
                    Text(blurb)
                        .font(.system(size: 15, design: .rounded)).italic()
                        .foregroundColor(.black.opacity(0.75))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)
                panelDivider
            }

            // Highlights
            if let h = tour.highlights, !h.isEmpty {
                sectionBlock("Highlights") {
                    ForEach(h, id: \.self) {
                        BulletItem(text: $0, icon: "checkmark.circle.fill", color: AppTheme.success)
                    }
                }
                panelDivider
            }

            // Inclusions
            if let inc = tour.inclusions, !inc.isEmpty {
                sectionBlock("What's Included") {
                    ForEach(inc, id: \.self) {
                        BulletItem(text: $0, icon: "plus.circle.fill", color: AppTheme.success)
                    }
                }
                panelDivider
            }

            // Exclusions
            if let exc = tour.exclusions, !exc.isEmpty {
                sectionBlock("Exclusions") {
                    ForEach(exc, id: \.self) {
                        BulletItem(text: $0, icon: "minus.circle.fill", color: AppTheme.error)
                    }
                }
                panelDivider
            }

            // Itinerary
            if let days = tour.itineraryDays, !days.isEmpty {
                sectionBlock("Itinerary") {
                    ForEach(days) { ItineraryDayRow(day: $0) }
                }
                panelDivider
            }

            // Meeting Point
            if let mp = tour.meetingPoint, !mp.isEmpty {
                sectionBlock("Meeting Point") {
                    Label(mp, systemImage: "mappin.and.ellipse")
                        .font(AppTheme.F.body)
                        .foregroundColor(.black.opacity(0.80))
                }
                panelDivider
            }

            // Languages
            if let langs = tour.languages, !langs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Languages").font(AppTheme.F.sectionH)
                    FlowLayout(spacing: 8) {
                        ForEach(langs, id: \.self) { l in
                            Text(l).font(AppTheme.F.small)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(AppTheme.grey100)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 16)
            }

            Spacer().frame(height: 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.top, 2)
    }

    // MARK: - Bottom bar
    // .safeAreaInset on this view + safeAreaInset on ContentView stack correctly —
    // this bar appears above the dark nav, not hidden behind it
    private var bottomBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("From")
                    .font(AppTheme.F.tiny)
                    .foregroundColor(.black.opacity(0.45))
                Text(tour.hasPrice ? "\(tour.formattedPrice)/person" : "On Request")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#020617"))
            }
            Spacer()
            Button(action: bookOrEnquire) {
                Text(tour.hasPrice ? "Book Tour" : "Enquire on WhatsApp")
                    .font(.system(
                        size: tour.hasPrice ? 17 : 14,
                        weight: .bold,
                        design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 50)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.10), radius: 16, y: -4)
        )
    }

    // MARK: - Helpers
    private var panelDivider: some View {
        Divider().padding(.horizontal, 16)
    }

    private func sectionBlock<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(AppTheme.F.sectionH).foregroundColor(Color(hex: "#020617"))
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func toggleSave() {
        guard let uid = auth.currentUser?.userId else { showAuth = true; return }
        isSaved.toggle()
        if isSaved { Task { await TourService.shared.saveTour(tourId: tour.id, userId: uid) } }
        else        { Task { await TourService.shared.unsaveTour(tourId: tour.id, userId: uid) } }
    }

    private func bookOrEnquire() {
        if tour.hasPrice {
            auth.isAuthenticated ? (showBooking = true) : (showAuth = true)
        } else {
            launchWhatsApp(tourTitle: tour.title)
        }
    }

    private func shareTour() {
        let msg = "Check out \"\(tour.title)\" on Hoppity!\nhoppity.in"
        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Padding helper
struct Padding<Content: View>: View {
    let h: CGFloat; let top: CGFloat; let content: Content
    init(h: CGFloat, top: CGFloat, @ViewBuilder _ content: () -> Content) {
        self.h = h; self.top = top; self.content = content()
    }
    var body: some View { content.padding(.horizontal, h).padding(.top, top) }
}
