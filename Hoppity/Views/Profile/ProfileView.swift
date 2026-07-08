import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showEdit = false
    @State private var showAuth = false
    @State private var showDeleteConfirm = false
    @State private var deleteText = ""
    @State private var isDeleting = false

    private let tabs = ["Overview", "Saved", "Trips", "Reviews"]
    private let tabActiveColor = AppTheme.primary.opacity(0.37)

    var body: some View {
        NavigationStack {
            if !auth.isAuthenticated {
                // Prompt sign in - not a hard block, just a nudge
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "person.circle").font(.system(size: 72))
                        .foregroundColor(AppTheme.textMuted)
                    Text("Sign in to your profile").font(AppTheme.F.h3).foregroundColor(.black)
                    Text("Access your bookings, saved trips, reviews and travel history.")
                        .font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
                        .multilineTextAlignment(.center)
                    PrimaryBtn(label: "Sign In") { showAuth = true }
                        .padding(.horizontal, 48)
                    Button(action: { showAuth = true }) {
                        Text("Create an account").font(AppTheme.F.label)
                            .foregroundColor(AppTheme.primary).underline()
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
                .navigationTitle("Profile")
                .sheet(isPresented: $showAuth) {
                    SignInView().environmentObject(auth)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        profileHeader
                        tabBarRow
                        tabContent
                    }
                }
                .background(Color.white)
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape").font(.system(size: 22)).foregroundColor(.black)
                        }
                    }
                }
                .sheet(isPresented: $showEdit) {
                    EditProfileSheet(auth: auth).environmentObject(auth)
                }
                .confirmationDialog("Settings", isPresented: $showSettings) {
                    Button("Edit Profile") { showEdit = true }
                    Button("Sign Out", role: .destructive) { Task { await auth.signOut() } }
                    Button("Delete Account", role: .destructive) { showDeleteConfirm = true }
                    Button("Cancel", role: .cancel) {}
                }
                .sheet(isPresented: $showDeleteConfirm) { deleteAccountSheet }
            }
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView
                    Circle().fill(AppTheme.primary).frame(width: 22, height: 22)
                        .overlay(Image(systemName: "pencil").font(.system(size: 10)).foregroundColor(.white))
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                .onTapGesture { showEdit = true }

                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.currentUser?.displayName ?? "Traveller")
                        .font(.system(size: 24, weight: .semibold, design: .rounded)).foregroundColor(.black)

                    if let loc = auth.currentUser?.location {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin").font(.system(size: 10)).foregroundColor(.black.opacity(0.45))
                            Text(loc).font(AppTheme.F.small).foregroundColor(.black.opacity(0.35))
                        }
                    }

                    if let since = auth.currentUser?.memberSince ?? auth.currentUser?.createdAt {
                        Text("Member since \(since.prefix(7))")
                            .font(AppTheme.F.tiny).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color(hex: "#595959").opacity(0.24))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 20)

            if let bio = auth.currentUser?.bio, !bio.isEmpty {
                Text(bio).font(AppTheme.F.label).foregroundColor(.black).lineSpacing(3)
                    .padding(.horizontal, 16).padding(.top, 16)
            }

            HStack {
                ProfileStat(value: "\(auth.currentUser?.tripsCount ?? 0)",    label: "Trips")
                ProfileStat(value: "\(auth.currentUser?.reviewsCount ?? 0)",   label: "Reviews")
                ProfileStat(value: "\(auth.currentUser?.wishlistCount ?? 0)",  label: "Wishlist")
                ProfileStat(value: auth.currentUser?.avgRating.map { String(format: "%.1f", $0) } ?? "–",
                            label: "Ratings")
            }
            .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 16)
        }
    }

    private var tabBarRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                Button(action: { selectedTab = i }) {
                    Text(tab).font(AppTheme.F.label)
                        .foregroundColor(selectedTab == i ? AppTheme.primary : AppTheme.textSub)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(selectedTab == i ? tabActiveColor : Color.clear)
                }
            }
        }
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case 0: OverviewTab()
        case 1: SavedTab().environmentObject(auth)
        case 2: TripsTab().environmentObject(auth)
        default: ReviewsTab()
        }
    }

    private var avatarView: some View {
        Group {
            if let pic = auth.currentUser?.profilePic, let url = URL(string: pic) {
                AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                    placeholder: {
                        ZStack { Circle().fill(AppTheme.grey100)
                            Text(auth.currentUser?.initials ?? "T")
                                .font(.system(size: 28, weight: .bold)).foregroundColor(.gray) }
                    }
            } else {
                ZStack { Circle().fill(AppTheme.grey100)
                    Text(auth.currentUser?.initials ?? "T")
                        .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.gray) }
            }
        }
        .frame(width: 80, height: 80).clipShape(Circle())
    }

    private var deleteAccountSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.S.lg) {
                ZStack {
                    Circle().fill(AppTheme.error.opacity(0.1)).frame(width: 80, height: 80)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36)).foregroundColor(AppTheme.error)
                }
                Text("Delete Account").font(AppTheme.F.sectionH)
                VStack(alignment: .leading, spacing: 8) {
                    Text("This permanently deletes:").font(AppTheme.F.bodyB)
                    ForEach(["Your profile and personal data", "All bookings and trip history",
                             "Saved trips and wishlist", "Reviews and activity"], id: \.self) { item in
                        Label(item, systemImage: "xmark.circle.fill").font(AppTheme.F.body)
                            .foregroundColor(AppTheme.textSub).symbolRenderingMode(.multicolor)
                    }
                }
                .padding(AppTheme.S.md).background(AppTheme.error.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type DELETE to confirm").font(AppTheme.F.label).foregroundColor(AppTheme.textSub)
                    TextField("Type DELETE here", text: $deleteText)
                        .autocapitalization(.allCharacters).textFieldStyle(.roundedBorder)
                }

                Button(action: {
                    Task {
                        isDeleting = true
                        let ok = await auth.deleteAccount()
                        isDeleting = false
                        if ok { showDeleteConfirm = false }
                    }
                }) {
                    HStack {
                        if isDeleting { ProgressView().tint(.white).scaleEffect(0.8) }
                        Text("Permanently Delete Account").font(AppTheme.F.bodyB).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(deleteText == "DELETE" ? AppTheme.error : AppTheme.error.opacity(0.3))
                    .clipShape(Capsule())
                }
                .disabled(deleteText != "DELETE" || isDeleting)
                Spacer()
            }
            .padding(AppTheme.S.lg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDeleteConfirm = false; deleteText = "" }
                }
            }
        }
    }
}

struct ProfileStat: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.black)
            Text(label).font(AppTheme.F.small).foregroundColor(AppTheme.textSub)
        }.frame(maxWidth: .infinity)
    }
}

struct OverviewTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill").font(.system(size: 48)).foregroundColor(AppTheme.textMuted)
            Text("Your travel overview").font(AppTheme.F.h3).foregroundColor(.black)
            Text("Book trips to see your overview").font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
        }.padding(.top, 60)
    }
}

struct SavedTab: View {
    @EnvironmentObject var auth: AuthManager
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill").font(.system(size: 48)).foregroundColor(AppTheme.textMuted)
            Text("Saved Trips").font(AppTheme.F.h3).foregroundColor(.black)
            Text("Tours you've bookmarked will appear here").font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
        }.padding(.top, 60)
    }
}

struct TripsTab: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var vm = TripsTabVM()
    var body: some View {
        Group {
            if vm.isLoading { LoadingView().frame(height: 200) }
            else if vm.bookings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "airplane").font(.system(size: 48)).foregroundColor(AppTheme.textMuted)
                    Text("No trips yet").font(AppTheme.F.h3).foregroundColor(.black)
                }.padding(.top, 60)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(vm.bookings) { b in BookingCard(booking: b) }
                }.padding(16)
            }
        }
        .task { if let uid = auth.currentUser?.userId { await vm.load(userId: uid) } }
    }
}

struct ReviewsTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill").font(.system(size: 48)).foregroundColor(AppTheme.textMuted)
            Text("No reviews yet").font(AppTheme.F.h3).foregroundColor(.black)
        }.padding(.top, 60)
    }
}

struct BookingCard: View {
    let booking: Booking
    var body: some View {
        HStack(spacing: 0) {
            HoppityImage(url: booking.tour?.coverImageUrl)
                .frame(width: 100, height: 100).clipped()
                .cornerRadius(AppTheme.R.card, corners: [.topLeft, .bottomLeft])
            VStack(alignment: .leading, spacing: 6) {
                Text(booking.tour?.title ?? "Trip").font(AppTheme.F.bodyB).foregroundColor(.black).lineLimit(2)
                if let date = booking.bookingDate {
                    Label(date, systemImage: "calendar").font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                }
                HStack {
                    if let p = booking.numPersons {
                        Label("\(p) pax", systemImage: "person.2").font(AppTheme.F.caption).foregroundColor(AppTheme.textSub)
                    }
                    Spacer()
                    if let s = booking.status {
                        Text(s.capitalized).font(AppTheme.F.tiny).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(booking.statusColor).clipShape(Capsule())
                    }
                }
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 100).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.R.card))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
    }
}

@MainActor final class TripsTabVM: ObservableObject {
    @Published var bookings: [Booking] = []; @Published var isLoading = false
    func load(userId: String) async {
        isLoading = true
        bookings = (try? await TourService.shared.fetchMyBookings(userId: userId)) ?? []
        isLoading = false
    }
}

struct EditProfileSheet: View {
    let auth: AuthManager
    @EnvironmentObject var authEnv: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""; @State private var username = ""
    @State private var bio = ""; @State private var location = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Full Name", text: $fullName)
                    TextField("Username", text: $username).autocapitalization(.none)
                    TextField("Location", text: $location)
                    TextField("Bio", text: $bio, axis: .vertical).lineLimit(3...5)
                }
            }
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await authEnv.updateProfile(
                                fullName: fullName.isEmpty ? nil : fullName,
                                bio: bio.isEmpty ? nil : bio,
                                username: username.isEmpty ? nil : username,
                                location: location.isEmpty ? nil : location)
                            dismiss()
                        }
                    }.fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            fullName = authEnv.currentUser?.fullName ?? ""
            username = authEnv.currentUser?.username ?? ""
            bio = authEnv.currentUser?.bio ?? ""
            location = authEnv.currentUser?.location ?? ""
        }
    }
}
