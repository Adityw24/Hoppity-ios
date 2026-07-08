import SwiftUI
import Combine

struct CommunityView: View {
    @StateObject private var vm = CommunityVM()
    @EnvironmentObject var auth: AuthManager
    @State private var showAuth = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if !auth.isAuthenticated {
                    // Auth gate - only for community
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 52)).foregroundColor(AppTheme.textMuted)
                        Text("Join the Community").font(AppTheme.F.h3).foregroundColor(.black)
                        Text("Sign in to read travel stories, share experiences and connect with fellow travellers.")
                            .font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
                            .multilineTextAlignment(.center)
                        PrimaryBtn(label: "Sign In to Continue") { showAuth = true }
                            .padding(.horizontal, 48)
                    }
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 0) {
                        // Category chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.categories, id: \.self) { cat in
                                    Button(action: {
                                        vm.selectedCategory = vm.selectedCategory == cat ? nil : cat
                                        Task { await vm.load() }
                                    }) {
                                        Text(cat).font(AppTheme.F.small)
                                            .foregroundColor(vm.selectedCategory == cat ? .white : AppTheme.textSub)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(vm.selectedCategory == cat ? AppTheme.primary : AppTheme.grey100)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                        }

                        Divider()

                        if vm.isLoading { LoadingView() }
                        else if vm.posts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "book.fill").font(.system(size: 52)).foregroundColor(AppTheme.textMuted)
                                Text("No stories yet").font(AppTheme.F.h3).foregroundColor(.black)
                                Text("Check back soon for travel stories").font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
                            }.padding(.top, 60)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    if let f = vm.posts.first {
                                        NavigationLink(destination: BlogDetailView(post: f)) {
                                            FeaturedBlogCard2(post: f)
                                        }
                                        .buttonStyle(.plain).padding(.horizontal, 16)
                                    }
                                    ForEach(vm.posts.dropFirst()) { post in
                                        NavigationLink(destination: BlogDetailView(post: post)) {
                                            BlogListCard(post: post)
                                        }
                                        .buttonStyle(.plain).padding(.horizontal, 16)
                                    }
                                }
                                .padding(.vertical, 16)
                            }
                            .refreshable { await vm.load() }
                        }
                    }
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if auth.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "square.and.pencil").font(.system(size: 20)).foregroundColor(.black)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAuth) {
                SignInView().environmentObject(auth)
            }
        }
        .task {
            if auth.isAuthenticated { await vm.load() }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuth in
            if isAuth { Task { await vm.load() } }
        }
    }
}

struct FeaturedBlogCard2: View {
    let post: BlogPost
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HoppityImage(url: post.coverImageUrl)
                .frame(maxWidth: .infinity).frame(height: 200).clipped()
                .cornerRadius(AppTheme.R.card, corners: [.topLeft, .topRight])
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top)
                        .cornerRadius(AppTheme.R.card, corners: [.topLeft, .topRight])
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let cat = post.category {
                            Text(cat.uppercased()).font(AppTheme.F.tiny).foregroundColor(AppTheme.teal)
                        }
                        Text(post.title).font(AppTheme.F.h2).foregroundColor(.white).lineLimit(2)
                    }.padding(14)
                }

            HStack {
                Text(post.author?.displayName ?? "Hoppity").font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                if let m = post.readTimeMinutes {
                    Text("· \(m) min").font(AppTheme.F.caption).foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                if let l = post.likesCount {
                    Label("\(l)", systemImage: "heart.fill").font(AppTheme.F.caption).foregroundColor(AppTheme.textMuted)
                }
            }.padding(14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

struct BlogListCard: View {
    let post: BlogPost
    var body: some View {
        HStack(spacing: 12) {
            HoppityImage(url: post.coverImageUrl)
                .frame(width: 90, height: 90).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                if let cat = post.category {
                    Text(cat.uppercased()).font(AppTheme.F.tiny).foregroundColor(AppTheme.teal)
                }
                Text(post.title).font(AppTheme.F.bodyB).foregroundColor(.black).lineLimit(2)
                HStack {
                    Text(post.author?.displayName ?? "Hoppity").font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                    if let m = post.readTimeMinutes {
                        Text("· \(m) min").font(AppTheme.F.caption).foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            Spacer()
        }
        .padding(12).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 1)
    }
}

struct BlogDetailView: View {
    let post: BlogPost
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.S.md) {
                HoppityImage(url: post.coverImageUrl).frame(maxWidth: .infinity).frame(height: 260).clipped()
                VStack(alignment: .leading, spacing: AppTheme.S.md) {
                    if let cat = post.category {
                        Text(cat.uppercased()).font(AppTheme.F.smallB).foregroundColor(AppTheme.teal)
                    }
                    Text(post.title).font(AppTheme.F.h2).foregroundColor(.black)
                    HStack {
                        Text(post.author?.displayName ?? "Hoppity").font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                        if let m = post.readTimeMinutes {
                            Text("· \(m) min read").font(AppTheme.F.caption).foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                        if let l = post.likesCount {
                            Label("\(l)", systemImage: "heart.fill").font(AppTheme.F.caption).foregroundColor(AppTheme.textMuted)
                        }
                    }
                    Divider()
                    if let excerpt = post.excerpt {
                        Text(excerpt).font(AppTheme.F.body).foregroundColor(.black.opacity(0.87)).lineSpacing(4)
                    }
                }.padding(.horizontal, 16)
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor final class CommunityVM: ObservableObject {
    @Published var posts: [BlogPost] = []
    @Published var isLoading = false
    @Published var selectedCategory: String? = nil
    let categories = ["Culture", "Adventure", "Food", "Heritage", "Wildlife", "Offbeat"]

    func load() async {
        isLoading = true
        posts = (try? await TourService.shared.fetchBlogPosts(category: selectedCategory)) ?? []
        isLoading = false
    }
}
