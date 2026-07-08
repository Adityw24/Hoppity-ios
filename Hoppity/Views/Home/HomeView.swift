import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showFilter = false

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.bgFeed.ignoresSafeArea()

            if vm.isLoading && vm.tours.isEmpty {
                ProgressView().tint(AppTheme.primary)
                    .frame(maxWidth:.infinity, maxHeight:.infinity)
            } else if vm.tours.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName:"map.fill").font(.system(size:52)).foregroundColor(.white.opacity(0.4))
                    Text("No tours found").font(AppTheme.F.bodyB).foregroundColor(.white.opacity(0.7))
                    Button("Refresh") { Task { await vm.load() } }
                        .foregroundColor(AppTheme.primary)
                }.frame(maxWidth:.infinity, maxHeight:.infinity)
            } else {
                // ── Vertical paging feed ──────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.tours) { tour in
                            NavigationLink(destination: TourDetailView(tour: tour)) {
                                TourFeedCard(tour: tour)
                                    .containerRelativeFrame([.horizontal, .vertical])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
            }

            // ── White top navbar ──────────────────────────────────
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 0)
                HStack {
                    Text("Hoppity")
                        .font(AppTheme.F.appName)
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: { shareTour(tours: vm.tours) }) {
                        Image(systemName: "paperplane")
                            .font(.system(size:22)).foregroundColor(.black)
                    }
                    Button(action: { showFilter = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size:22)).foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.white)
                Divider()
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showFilter) {
            CategoryFilterSheet(selectedCategory: $vm.selectedCategory) {
                Task { await vm.load() }
            }
        }
    }
}

// MARK: - Feed Card
struct TourFeedCard: View {
    let tour: Tour

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // Full bleed image
                HoppityImage(url: tour.primaryImage)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // Bottom gradient
                LinearGradient(
                    colors: [.black.opacity(0.85), .black.opacity(0.4), .clear],
                    startPoint: .bottom, endPoint: .init(x: 0.5, y: 0.45)
                )
                .ignoresSafeArea()

                // Content
                VStack(alignment: .leading, spacing: 10) {
                    // Category
                    if let cat = tour.tag ?? tour.category {
                        Text(cat)
                            .font(AppTheme.F.bodyB).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(
                                LinearGradient(
                                    colors: [.black.opacity(0.2), tour.categoryColor],
                                    startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }

                    // Title
                    Text(tour.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 4)

                    // Location
                    if let loc = tour.location {
                        Label(loc, systemImage: "mappin.circle.fill")
                            .font(AppTheme.F.bodyB)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    HStack(spacing: 10) {
                        // Price
                        Text(tour.formattedPrice)
                            .font(AppTheme.F.captionB).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.black.opacity(0.8))
                            .clipShape(Capsule())

                        if !tour.durationText.isEmpty {
                            Text("⏱ \(tour.durationText)")
                                .font(AppTheme.F.captionB)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()

                        // Explore pill
                        HStack(spacing: 4) {
                            Text("Explore").font(AppTheme.F.bodyB).foregroundColor(.white)
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.white)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110) // above bottom nav
            }
        }
    }
}

// MARK: - Category filter sheet
struct CategoryFilterSheet: View {
    @Binding var selectedCategory: String
    @Environment(\.dismiss) var dismiss
    var onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, 12)

            Text("Filter by Category")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            FlowLayout(spacing: 8) {
                ForEach(TourService.categories, id: \.self) { cat in
                    Button(action: {
                        selectedCategory = cat
                        onSelect()
                        dismiss()
                    }) {
                        Text(cat).font(AppTheme.F.label)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(cat == selectedCategory
                                ? AppTheme.primary
                                : Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1A1A1A"))
        .presentationDetents([.fraction(0.45)])
    }
}

// MARK: - Share
func shareTour(tours: [Tour]) {
    guard let tour = tours.first else { return }
    let msg = "Check out \"\(tour.title)\" on Hoppity!\nhoppity.in"
    let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: "https://wa.me/?text=\(encoded)") {
        UIApplication.shared.open(url)
    }
}

// MARK: - ViewModel
@MainActor final class HomeViewModel: ObservableObject {
    @Published var tours: [Tour] = []
    @Published var selectedCategory = "All"
    @Published var isLoading = false

    func load() async {
        isLoading = true
        let cat = selectedCategory == "All" ? nil : selectedCategory
        tours = (try? await TourService.shared.fetchTours(category: cat, limit: 40)) ?? []
        isLoading = false
    }
}
