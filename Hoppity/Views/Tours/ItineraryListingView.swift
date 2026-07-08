import SwiftUI
import Combine

struct ItineraryListingView: View {
    @StateObject private var vm = ItineraryListingVM()
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    categoryChips
                    Divider()

                    HStack {
                        Text("Popular tours")
                            .font(AppTheme.F.bodyB).foregroundColor(.black)
                        Spacer()
                        Button(action: {}) {
                            Text("Sort ↕").font(AppTheme.F.tiny).foregroundColor(AppTheme.textSub)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)

                    if vm.isLoading {
                        LoadingView()
                    } else if vm.displayTours.isEmpty {
                        // Inline empty state — no external EmptyView2 dependency
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48)).foregroundColor(AppTheme.textMuted)
                            Text("No tours found")
                                .font(AppTheme.F.h3).foregroundColor(.black)
                            Text("Try a different search or category")
                                .font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(vm.displayTours) { tour in
                                    NavigationLink(
                                        destination: TourDetailView(tour: tour)
                                            .environmentObject(auth)
                                    ) {
                                        TourListCard(tour: tour)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Hoppity")
                        .font(AppTheme.F.appName)
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Image(systemName: "envelope")
                                .foregroundColor(.black)
                        }
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
        .task { await vm.loadAll() }
    }

    // MARK: - Search bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textMuted)
                .font(.system(size: 15))
            TextField("Search tours, places, experiences...", text: $vm.query)
                .font(AppTheme.F.caption)
                .foregroundColor(.black)
                .autocapitalization(.none)
                .onSubmit { Task { await vm.search() } }
            if !vm.query.isEmpty {
                Button(action: { vm.query = ""; vm.results = [] }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textMuted)
                }
            }
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Category chips
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TourService.categories, id: \.self) { cat in
                    Button(action: {
                        vm.selectedCategory = (vm.selectedCategory == cat && cat != "All") ? "All" : cat
                        Task { await vm.search() }
                    }) {
                        Text(cat)
                            .font(vm.selectedCategory == cat ? AppTheme.F.smallB : AppTheme.F.small)
                            .foregroundColor(vm.selectedCategory == cat ? .white : AppTheme.textSub)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(vm.selectedCategory == cat
                                ? AppTheme.primary
                                : Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.06), radius: 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Tour list card (compact)
struct TourListCard: View {
    let tour: Tour

    var body: some View {
        HStack(spacing: 0) {
            HoppityImage(url: tour.coverImageUrl)
                .frame(width: 110, height: 110)
                .clipped()
                .cornerRadius(AppTheme.R.card, corners: [.topLeft, .bottomLeft])
                .overlay(alignment: .topLeading) {
                    if let cat = tour.tag ?? tour.category {
                        Text(cat)
                            .font(AppTheme.F.tiny)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(tour.categoryColor)
                            .clipShape(Capsule())
                            .padding(6)
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(tour.title)
                    .font(AppTheme.F.bodyB)
                    .foregroundColor(.black)
                    .lineLimit(2)

                if let loc = tour.location {
                    Label(loc, systemImage: "mappin.circle.fill")
                        .font(AppTheme.F.caption)
                        .foregroundColor(AppTheme.textSub)
                        .lineLimit(1)
                }

                if !tour.durationText.isEmpty {
                    Label(tour.durationText, systemImage: "clock")
                        .font(AppTheme.F.caption)
                        .foregroundColor(AppTheme.textSub)
                }

                HStack {
                    Text(tour.formattedPrice)
                        .font(AppTheme.F.smallB)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.black)
                        .clipShape(Capsule())
                    Spacer()
                    if let r = tour.rating, r > 0 {
                        Label(String(format: "%.1f", r), systemImage: "star.fill")
                            .font(AppTheme.F.small)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 110)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}

// MARK: - ViewModel
@MainActor final class ItineraryListingVM: ObservableObject {
    @Published var query = ""
    @Published var results: [Tour] = []
    @Published var allTours: [Tour] = []
    @Published var selectedCategory = "All"
    @Published var isLoading = false

    var displayTours: [Tour] {
        if !results.isEmpty { return results }
        if selectedCategory != "All" {
            return allTours.filter {
                $0.category?.lowercased() == selectedCategory.lowercased()
            }
        }
        return allTours
    }

    func loadAll() async {
        isLoading = true
        allTours = (try? await TourService.shared.fetchTours(limit: 40)) ?? []
        isLoading = false
    }

    func search() async {
        isLoading = true
        let cat = selectedCategory == "All" ? nil : selectedCategory
        let tours = (try? await TourService.shared.fetchTours(category: cat, limit: 40)) ?? []
        results = query.isEmpty ? [] : tours.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            ($0.location?.localizedCaseInsensitiveContains(query) ?? false)
        }
        isLoading = false
    }
}
