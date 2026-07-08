import SwiftUI
import Combine

// Mirrors Flutter ForYouScreen — ML personalised feed
struct ForYouView: View {
    @StateObject private var vm = ForYouVM()
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if vm.isLoading {
                    LoadingView()
                } else if vm.tours.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles").font(.system(size: 52)).foregroundColor(AppTheme.textMuted)
                        Text("Personalised for you").font(AppTheme.F.h3).foregroundColor(.black)
                        Text("Browse some tours so we can learn your preferences")
                            .font(AppTheme.F.body).foregroundColor(AppTheme.textSub).multilineTextAlignment(.center)
                    }.padding(.horizontal, 32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Header card
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles").foregroundColor(AppTheme.primary)
                                    Text("Picked for you").font(AppTheme.F.bodyB).foregroundColor(AppTheme.primary)
                                }
                                Text("Based on your interests").font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                            }
                            .frame(maxWidth:.infinity, alignment:.leading)
                            .padding(16)
                            .background(AppTheme.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)

                            ForEach(vm.tours) { tour in
                                NavigationLink(destination: TourDetailView(tour: tour).environmentObject(auth)) {
                                    ForYouCard(tour: tour)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
    }
}

struct ForYouCard: View {
    let tour: Tour
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HoppityImage(url: tour.coverImageUrl)
                .frame(maxWidth:.infinity).frame(height: 200).clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card,
                                           style: .continuous), style: FillStyle())
                .cornerRadius(AppTheme.R.card, corners: [.topLeft, .topRight])
                .overlay(alignment: .topLeading) {
                    if let cat = tour.tag ?? tour.category {
                        Text(cat).font(AppTheme.F.smallB).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(tour.categoryColor).clipShape(Capsule())
                            .padding(10)
                    }
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(tour.title).font(AppTheme.F.bodyB).foregroundColor(.black)
                if let loc = tour.location {
                    Label(loc, systemImage: "mappin.circle.fill")
                        .font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                }
                HStack {
                    Text(tour.formattedPrice).font(AppTheme.F.smallB).foregroundColor(AppTheme.primary)
                    Spacer()
                    if !tour.durationText.isEmpty {
                        Text(tour.durationText).font(AppTheme.F.small).foregroundColor(AppTheme.textSub)
                    }
                }
            }
            .padding(14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card))
        .shadow(color:.black.opacity(0.08), radius:8, y:2)
    }
}

@MainActor final class ForYouVM: ObservableObject {
    @Published var tours: [Tour] = []; @Published var isLoading = false
    func load() async {
        isLoading = true
        // Fetch a curated mix — top rated tours
        let all = (try? await TourService.shared.fetchTours(limit: 20)) ?? []
        tours = all.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        isLoading = false
    }
}
