import Foundation
import SwiftUI

// MARK: - Tour (maps to Itineraries table)
struct Tour: Codable, Identifiable {
    let id: Int
    var title: String
    var slug: String?
    var blurb: String?
    var coverImageUrl: String?
    var images: [String]?
    var price: String?
    var pricePerPerson: Double?
    var duration: String?
    var durationDisplay: String?
    var location: String?
    var state: String?
    var category: String?
    var tag: String?
    var highlights: [String]?
    var inclusions: [String]?
    var exclusions: [String]?
    var difficulty: String?
    var maxGroupSize: Int?
    var minGroupSize: Int?
    var languages: [String]?
    var meetingPoint: String?
    var itineraryDays: [ItineraryDay]?
    var rating: Double?
    var reviewCount: Int?
    var isActive: Bool?
    var moodTags: [String]?
    var searchTags: [String]?
    var tips: [String]?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, blurb, price, duration, location, state, category, tag
        case difficulty, languages, rating
        case coverImageUrl   = "cover_image_url"
        case images
        case pricePerPerson  = "price_per_person"
        case durationDisplay = "duration_display"
        case highlights, inclusions, exclusions
        case maxGroupSize    = "max_group_size"
        case minGroupSize    = "min_group_size"
        case meetingPoint    = "meeting_point"
        case itineraryDays   = "itinerary_days"
        case reviewCount     = "review_count"
        case isActive        = "is_active"
        case moodTags        = "mood_tags"
        case searchTags      = "search_tags"
        case tips
        case createdAt       = "created_at"
    }

    // Custom decoder — makes every field fault-tolerant
    // If any single field fails (wrong type, missing key), the Tour still decodes
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Required
        id    = try c.decode(Int.self, forKey: .id)
        title = (try? c.decode(String.self, forKey: .title)) ?? ""

        // Optional strings
        slug         = try? c.decode(String.self, forKey: .slug)
        blurb        = try? c.decode(String.self, forKey: .blurb)
        price        = try? c.decode(String.self, forKey: .price)
        duration     = try? c.decode(String.self, forKey: .duration)
        durationDisplay = try? c.decode(String.self, forKey: .durationDisplay)
        location     = try? c.decode(String.self, forKey: .location)
        state        = try? c.decode(String.self, forKey: .state)
        category     = try? c.decode(String.self, forKey: .category)
        tag          = try? c.decode(String.self, forKey: .tag)
        difficulty   = try? c.decode(String.self, forKey: .difficulty)
        meetingPoint = try? c.decode(String.self, forKey: .meetingPoint)
        coverImageUrl = try? c.decode(String.self, forKey: .coverImageUrl)
        createdAt    = try? c.decode(String.self, forKey: .createdAt)

        // Optional numbers
        maxGroupSize   = try? c.decode(Int.self, forKey: .maxGroupSize)
        minGroupSize   = try? c.decode(Int.self, forKey: .minGroupSize)
        reviewCount    = try? c.decode(Int.self, forKey: .reviewCount)
        isActive       = try? c.decode(Bool.self, forKey: .isActive)

        // pricePerPerson — stored as numeric in Postgres, comes back as Double or String
        if let p = try? c.decode(Double.self, forKey: .pricePerPerson) {
            pricePerPerson = p
        } else if let s = try? c.decode(String.self, forKey: .pricePerPerson),
                  let p = Double(s) {
            pricePerPerson = p
        } else {
            pricePerPerson = nil
        }

        // rating — same issue
        if let r = try? c.decode(Double.self, forKey: .rating) {
            rating = r
        } else if let s = try? c.decode(String.self, forKey: .rating),
                  let r = Double(s) {
            rating = r
        } else {
            rating = nil
        }

        // Arrays of strings — text[] in Postgres
        images      = try? c.decode([String].self, forKey: .images)
        highlights  = try? c.decode([String].self, forKey: .highlights)
        inclusions  = try? c.decode([String].self, forKey: .inclusions)
        exclusions  = try? c.decode([String].self, forKey: .exclusions)
        languages   = try? c.decode([String].self, forKey: .languages)
        moodTags    = try? c.decode([String].self, forKey: .moodTags)
        searchTags  = try? c.decode([String].self, forKey: .searchTags)
        tips        = try? c.decode([String].self, forKey: .tips)

        // itinerary_days — jsonb, structure: [{title, description, activities}]
        // Uses try? so a structure mismatch never crashes Tour decode
        itineraryDays = try? c.decode([ItineraryDay].self, forKey: .itineraryDays)
    }

    // Standard encode
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try? c.encodeIfPresent(slug, forKey: .slug)
        try? c.encodeIfPresent(blurb, forKey: .blurb)
        try? c.encodeIfPresent(coverImageUrl, forKey: .coverImageUrl)
        try? c.encodeIfPresent(pricePerPerson, forKey: .pricePerPerson)
        try? c.encodeIfPresent(inclusions, forKey: .inclusions)
        try? c.encodeIfPresent(exclusions, forKey: .exclusions)
        try? c.encodeIfPresent(highlights, forKey: .highlights)
    }

    // MARK: - Computed helpers
    var formattedPrice: String {
        if let p = pricePerPerson, p > 0 {
            if p >= 100000 { return "₹\(String(format: "%.1f", p/100000))L" }
            if p >= 1000   { return "₹\(String(format: "%.0f", p/1000))K" }
            return "₹\(Int(p))"
        }
        if let s = price, !s.isEmpty { return s }
        return "On Request"
    }

    var durationText: String { durationDisplay ?? duration ?? "" }
    var primaryImage: String? { coverImageUrl ?? images?.first }
    var hasPrice: Bool { (pricePerPerson ?? 0) > 0 }

    var categoryColor: Color {
        switch category?.lowercased() {
        case "cultural", "culture": return Color(hex: "#007A63")
        case "adventure":           return Color(hex: "#E53E3E")
        case "wildlife":            return Color(hex: "#38A169")
        case "heritage":            return Color(hex: "#D69E2E")
        case "beach":               return Color(hex: "#3182CE")
        case "spiritual":           return Color(hex: "#805AD5")
        default:                    return AppTheme.primary
        }
    }

    var difficultyColor: Color {
        switch difficulty?.lowercased() {
        case "easy":               return Color(hex: "#38A169")
        case "medium", "moderate": return Color(hex: "#D69E2E")
        case "hard":               return Color(hex: "#E53E3E")
        default:                   return AppTheme.textSub
        }
    }
}

// MARK: - ItineraryDay
// Matches actual DB jsonb structure: {title, description, activities}
// `day` is inferred from array position — not stored in DB
struct ItineraryDay: Codable, Identifiable {
    var dayNumber: Int         // set manually after decoding
    var title: String
    var description: String
    var activities: [String]?

    var id: Int { dayNumber }

    enum CodingKeys: String, CodingKey {
        case title, description, activities
        // NOTE: no "day" key — it doesn't exist in the DB jsonb
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title       = (try? c.decode(String.self, forKey: .title)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        activities  = try? c.decode([String].self, forKey: .activities)
        dayNumber   = 0 // set by caller after decoding array
    }

    init(dayNumber: Int, title: String, description: String, activities: [String]? = nil) {
        self.dayNumber = dayNumber
        self.title = title
        self.description = description
        self.activities = activities
    }
}

// MARK: - Booking
struct Booking: Codable, Identifiable {
    let id: String
    var userId: String?
    var tourId: Int?
    var tour: Tour?
    var bookingDate: String?
    var numPersons: Int?
    var status: String?
    var totalAmount: Double?
    var paymentStatus: String?
    var specialRequest: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId        = "user_id"
        case tourId        = "tour_id"
        case tour
        case bookingDate   = "booking_date"
        case numPersons    = "num_persons"
        case status
        case totalAmount   = "total_amount"
        case paymentStatus = "payment_status"
        case specialRequest = "special_request"
        case createdAt     = "created_at"
    }

    var statusColor: Color {
        switch status {
        case "confirmed": return Color(hex: "#10B981")
        case "pending":   return Color(hex: "#F59E0B")
        case "cancelled": return Color(hex: "#EF4444")
        default:          return Color(hex: "#94A3B8")
        }
    }
}

// MARK: - HoppityUser
struct HoppityUser: Codable, Identifiable {
    let userId: String
    var fullName: String?
    var username: String?
    var email: String?
    var profilePic: String?
    var phone: String?
    var bio: String?
    var location: String?
    var isCreator: Bool?
    var isGuide: Bool?
    var role: String?
    var tripsCount: Int?
    var reviewsCount: Int?
    var wishlistCount: Int?
    var avgRating: Double?
    var memberSince: String?
    var createdAt: String?

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId        = "user_id"
        case fullName      = "full_name"
        case username, email
        case profilePic    = "profile_pic"
        case phone, bio, location
        case isCreator     = "is_creator"
        case isGuide       = "is_guide"
        case role
        case tripsCount    = "trips_count"
        case reviewsCount  = "reviews_count"
        case wishlistCount = "wishlist_count"
        case avgRating     = "avg_rating"
        case memberSince   = "member_since"
        case createdAt     = "created_at"
    }

    var displayName: String { fullName ?? username ?? "Traveller" }
    var initials: String { String((displayName.first ?? "T").uppercased()) }
}

// MARK: - BlogPost
struct BlogPost: Codable, Identifiable {
    let id: String
    var title: String
    var slug: String?
    var excerpt: String?
    var contentHtml: String?
    var coverImageUrl: String?
    var category: String?
    var tags: [String]?
    var authorId: String?
    var author: BlogAuthor?
    var status: String?
    var isFeatured: Bool?
    var likesCount: Int?
    var viewsCount: Int?
    var readTimeMinutes: Int?
    var createdAt: String?
    var publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, excerpt, category, tags, status, author
        case contentHtml     = "content_html"
        case coverImageUrl   = "cover_image_url"
        case authorId        = "author_id"
        case isFeatured      = "is_featured"
        case likesCount      = "likes_count"
        case viewsCount      = "views_count"
        case readTimeMinutes = "read_time_minutes"
        case createdAt       = "created_at"
        case publishedAt     = "published_at"
    }
}

struct BlogAuthor: Codable {
    var fullName: String?
    var username: String?
    var profilePic: String?

    enum CodingKeys: String, CodingKey {
        case fullName   = "full_name"
        case username
        case profilePic = "profile_pic"
    }
    var displayName: String { fullName ?? username ?? "Hoppity" }
}

// MARK: - App Tab
enum AppTab: Int, CaseIterable {
    case home, forYou, tours, community, profile

    var title: String {
        switch self {
        case .home:      return "Home"
        case .forYou:    return "For You"
        case .tours:     return "Tours"
        case .community: return "Community"
        case .profile:   return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .forYou:    return "sparkles"
        case .tours:     return "map"
        case .community: return "person.3"
        case .profile:   return "person.circle"
        }
    }
}
