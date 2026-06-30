import Foundation

struct SiteConfig: Codable {
    var site: Site
    var seller: SellerConfig
    var products: ProductsConfig
    var cta: CTA
    var legal: Legal
    var design: Design
    var theme: Theme

    struct Site: Codable {
        var name: String
        var domain: String
        var description: String
        var locale: String
        var currency: String
    }

    struct SellerConfig: Codable {
        var id: Int
        var base36Id: String
        var username: String
        var canonicalUrl: String
        var sourceUrl: String
    }

    struct ProductsConfig: Codable {
        var sort: String
        var pageSize: Int
        var maxPages: Int
        var showSold: Bool
    }

    struct CTA: Codable {
        var label: String
        var soldLabel: String
        var disclaimer: String
    }

    struct Legal: Codable {
        var disclaimer: String
    }

    struct Design: Codable {
        var referenceUrl: String
        var referenceImage: String
        var notes: String
        var logo: Logo?
    }

    struct Logo: Codable {
        var source: String
        var symbol: String
        var favicon: String
    }

    struct Theme: Codable {
        var accent: String
        var background: String
        var text: String
    }
}

struct SellerProfile: Codable {
    var id: Int
    var base36Id: String
    var username: String
    var nickname: String
    var bio: String
    var productCount: Int
    var canonicalUrl: String
    var sourceUrl: String
}

struct ProductSummary: Codable, Identifiable {
    var id: Int
    var base36Id: String
    var title: String
    var brand: String
    var status: String
    var price: Int
    var image: String
    var images: [String]
    var bigImages: [String]
    var createdAt: String
    var fruitsUrl: String
}

struct ProductDetail: Codable {
    var item: ProductSummary
}
