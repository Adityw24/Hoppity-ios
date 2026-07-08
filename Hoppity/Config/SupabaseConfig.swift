import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://wenhudcyvlhilpgazylg.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indlbmh1ZGN5dmxoaWxwZ2F6eWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTY0MTgsImV4cCI6MjA4NTA3MjQxOH0.Jdx993pFvb0JC87NaYhOQ6UR_7UIJBA1mkFQUeoK7bA"
)

// Google OAuth Client IDs
enum GoogleAuth {
    static let webClientID = "763877266995-of6luqsf28fa5vmo28un0jucbg28tf46.apps.googleusercontent.com"
    static let iOSClientID = "763877266995-6ke194as54ppgiphr2itrvri6rod4261.apps.googleusercontent.com"
    // Reversed iOS client ID — registered as URL scheme in Info.plist
    static let iOSURLScheme = "com.googleusercontent.apps.763877266995-6ke194as54ppgiphr2itrvri6rod4261"
}
