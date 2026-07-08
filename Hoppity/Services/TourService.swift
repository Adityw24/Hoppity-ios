import Foundation
import Supabase

class TourService {
    static let shared = TourService()
    private init() {}

    static let categories = [
        "All", "Cultural", "Adventure", "Wildlife",
        "Spiritual", "Heritage", "Beach", "Hill Station", "Offbeat"
    ]

    // MARK: - Fetch tours
    func fetchTours(category: String? = nil, limit: Int = 40) async throws -> [Tour] {
        let tours: [Tour] = try await supabase
            .from("Itineraries")
            .select()
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Number itinerary days by position (DB doesn't store day numbers)
        let numbered = tours.map { numberDays($0) }

        guard let cat = category, cat != "All" else { return numbered }
        return numbered.filter { $0.category?.lowercased() == cat.lowercased() }
    }

    // MARK: - Fetch single tour by ID
    func fetchTour(id: Int) async throws -> Tour {
        let tour: Tour = try await supabase
            .from("Itineraries")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return numberDays(tour)
    }

    // MARK: - Fetch single tour by slug
    func fetchTour(slug: String) async throws -> Tour {
        let tour: Tour = try await supabase
            .from("Itineraries")
            .select()
            .eq("slug", value: slug)
            .single()
            .execute()
            .value
        return numberDays(tour)
    }

    // MARK: - Number itinerary days by array position
    private func numberDays(_ tour: Tour) -> Tour {
        guard var days = tour.itineraryDays, !days.isEmpty else { return tour }
        for i in 0..<days.count { days[i].dayNumber = i + 1 }
        var t = tour; t.itineraryDays = days; return t
    }

    // MARK: - Is tour saved?
    func isTourSaved(tourId: Int, userId: String) async -> Bool {
        do {
            let result: [AnyJSON] = try await supabase
                .from("Property_Saves")
                .select("id")
                .eq("tour_id", value: tourId)
                .eq("user_id", value: userId)
                .execute()
                .value
            return !result.isEmpty
        } catch { return false }
    }

    // MARK: - Save a tour
    func saveTour(tourId: Int, userId: String) async {
        let payload: [String: AnyJSON] = [
            "tour_id": .integer(tourId),
            "user_id": .string(userId)
        ]
        _ = try? await supabase
            .from("Property_Saves")
            .upsert(payload)
            .execute()
    }

    // MARK: - Unsave a tour
    func unsaveTour(tourId: Int, userId: String) async {
        _ = try? await supabase
            .from("Property_Saves")
            .delete()
            .eq("tour_id", value: tourId)
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Fetch user bookings
    func fetchMyBookings(userId: String) async throws -> [Booking] {
        try await supabase
            .from("Bookings")
            .select("*, tour:Itineraries(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Fetch blog posts
    func fetchBlogPosts(category: String? = nil) async throws -> [BlogPost] {
        let posts: [BlogPost] = try await supabase
            .from("Blog_Posts")
            .select("*, author:Users!Blog_Posts_author_id_fkey(full_name,username,profile_pic)")
            .eq("status", value: "approved")
            .order("published_at", ascending: false)
            .execute()
            .value

        guard let cat = category else { return posts }
        return posts.filter { $0.category == cat }
    }
}
