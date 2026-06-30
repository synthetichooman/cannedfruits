import Foundation

final class FruitsClient {
    private let endpoint = URL(string: "https://web-server.production.fruitsfamily.com/graphql")!
    private let session = URLSession.shared

    func resolveSeller(from rawURL: String) async throws -> SellerProfile {
        let parsed = try parseSellerURL(rawURL)
        let query = """
        query SeeUser($id: Int!) {
          seeUser(id: $id) {
            id
            username
            nickname
            bio
            seller { productCount }
          }
        }
        """
        let payload = try await graphql(query: query, variables: ["id": parsed.id])
        guard
            let data = payload["data"] as? [String: Any],
            let user = data["seeUser"] as? [String: Any]
        else {
            throw AppError.message("FruitsFamily 셀러 정보를 확인하지 못했습니다.")
        }

        let id = Int("\(user["id"] ?? parsed.id)") ?? parsed.id
        let username = (user["username"] as? String) ?? parsed.username
        let nickname = (user["nickname"] as? String) ?? username
        let seller = user["seller"] as? [String: Any]
        let productCount = seller?["productCount"] as? Int ?? 0
        let base36 = String(id, radix: 36)
        let canonical = "https://fruitsfamily.com/seller/\(base36)/\(username)"

        return SellerProfile(
            id: id,
            base36Id: base36,
            username: username,
            nickname: nickname,
            bio: (user["bio"] as? String) ?? "",
            productCount: productCount,
            canonicalUrl: canonical,
            sourceUrl: rawURL
        )
    }

    func sellerPayload(config: SiteConfig) async throws -> [String: Any] {
        let seller = try await resolveSeller(from: config.seller.canonicalUrl)
        return [
            "config": try config.jsonObject(),
            "seller": [
                "id": seller.id,
                "base36Id": seller.base36Id,
                "username": seller.username,
                "nickname": seller.nickname,
                "bio": seller.bio,
                "productCount": seller.productCount,
                "canonicalUrl": seller.canonicalUrl
            ],
            "fetchedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    func productsPayload(config: SiteConfig) async throws -> [String: Any] {
        let pageSize = max(1, config.products.pageSize)
        let maxPages = max(1, config.products.maxPages)
        var items: [[String: Any]] = []
        var seen = Set<Int>()

        let query = """
        query SeeSellerProducts($filter: ProductFilter!, $offset: Int, $limit: Int, $sort: String) {
          searchProducts(filter: $filter, offset: $offset, limit: $limit, sort: $sort, origin: "SELLER") {
            id
            title
            brand
            status
            external_url
            resizedSmallImages
            resizedBigImages
            createdAt
            price
          }
        }
        """

        for page in 0..<maxPages {
            let variables: [String: Any] = [
                "filter": [
                    "query": "",
                    "sellerId": config.seller.id
                ],
                "offset": page * pageSize,
                "limit": pageSize,
                "sort": config.products.sort
            ]
            let payload = try await graphql(query: query, variables: variables)
            let data = payload["data"] as? [String: Any]
            let products = data?["searchProducts"] as? [[String: Any]] ?? []
            if products.isEmpty { break }
            for product in products {
                let compact = compactProduct(product)
                let id = compact["id"] as? Int ?? 0
                if id > 0 && !seen.contains(id) {
                    seen.insert(id)
                    items.append(compact)
                }
            }
        }

        return [
            "items": items,
            "count": items.count,
            "fetchedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    func productPayload(config: SiteConfig, id: Int) async throws -> [String: Any] {
        let query = """
        query SeeProductResponse($productId: Int!) {
          seeProductResponse(id: $productId) {
            seeProduct {
              id
              title
              brand
              status
              external_url
              resizedSmallImages
              resizedBigImages
              createdAt
              price
              original_price
              category
              sub_category
              size
              condition
              discount_rate
              like_count
              view_count
              is_visible
              description
            }
          }
        }
        """
        let payload = try await graphql(query: query, variables: ["productId": id])
        let data = payload["data"] as? [String: Any]
        let response = data?["seeProductResponse"] as? [String: Any]
        guard let product = response?["seeProduct"] as? [String: Any] else {
            throw AppError.message("상품 정보를 찾지 못했습니다.")
        }

        return [
            "product": compactProduct(product),
            "fetchedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    private func graphql(query: String, variables: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query,
            "variables": variables
        ])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.message("FruitsFamily API 요청에 실패했습니다.")
        }
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        if let errors = object["errors"] as? [[String: Any]], let first = errors.first {
            throw AppError.message((first["message"] as? String) ?? "FruitsFamily API 오류")
        }
        return object
    }

    private func parseSellerURL(_ value: String) throws -> (id: Int, username: String) {
        let source = value.hasPrefix("http") ? value : "https://\(value)"
        guard
            let url = URL(string: source),
            let regex = try? NSRegularExpression(pattern: #"^/seller/([0-9a-z]+)/([^/?#]+)"#, options: [.caseInsensitive])
        else {
            throw AppError.message("셀러 링크 형식이 올바르지 않습니다.")
        }
        let path = url.path
        let range = NSRange(path.startIndex..<path.endIndex, in: path)
        guard
            let match = regex.firstMatch(in: path, range: range),
            let idRange = Range(match.range(at: 1), in: path),
            let userRange = Range(match.range(at: 2), in: path),
            let id = Int(String(path[idRange]), radix: 36)
        else {
            throw AppError.message("셀러 링크에서 seller id를 찾지 못했습니다.")
        }
        return (id, String(path[userRange]))
    }

    private func compactProduct(_ product: [String: Any]) -> [String: Any] {
        let id = Int("\(product["id"] ?? 0)") ?? 0
        let images = product["resizedSmallImages"] as? [String] ?? []
        let bigImages = product["resizedBigImages"] as? [String] ?? []
        let title = (product["title"] as? String) ?? "Untitled product"
        let external = (product["external_url"] as? String) ?? ""
        let fallbackURL = "https://fruitsfamily.com/product/\(String(id, radix: 36))/\(slug(title))"
        return [
            "id": id,
            "base36Id": String(id, radix: 36),
            "title": title,
            "brand": (product["brand"] as? String) ?? "No Brand",
            "status": (product["status"] as? String) ?? "unknown",
            "price": Int("\(product["price"] ?? 0)") ?? 0,
            "originalPrice": numberOrNull(product["original_price"]),
            "discountRate": numberOrNull(product["discount_rate"]),
            "category": (product["category"] as? String) ?? "",
            "subCategory": (product["sub_category"] as? String) ?? "",
            "size": (product["size"] as? String) ?? "",
            "condition": (product["condition"] as? String) ?? "",
            "image": images.first ?? bigImages.first ?? "",
            "images": images,
            "bigImages": bigImages,
            "likeCount": Int("\(product["like_count"] ?? 0)") ?? 0,
            "viewCount": Int("\(product["view_count"] ?? 0)") ?? 0,
            "isVisible": (product["is_visible"] as? Bool) ?? true,
            "createdAt": (product["createdAt"] as? String) ?? "",
            "description": (product["description"] as? String) ?? "",
            "fruitsUrl": external.isEmpty ? fallbackURL : external,
            "externalUrl": external
        ]
    }

    private func numberOrNull(_ value: Any?) -> Any {
        guard let value else { return NSNull() }
        if value is NSNull { return NSNull() }
        if let number = value as? NSNumber { return number }
        if let int = Int("\(value)") { return int }
        return NSNull()
    }

    private func slug(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    }
}

extension SiteConfig {
    func jsonObject() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

enum AppError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let value): value
        }
    }
}
