import Foundation
import Network

final class LocalPreviewServer {
    private var listener: NWListener?
    private let fruitsClient = FruitsClient()
    private(set) var port: UInt16 = 0
    var projectURL: URL

    init(projectURL: URL) {
        self.projectURL = projectURL
    }

    func start(preferredPort: UInt16 = 8788) async throws -> URL {
        if listener != nil {
            return URL(string: "http://localhost:\(port)")!
        }

        var selectedPort = preferredPort
        var lastError: Error?
        while selectedPort < preferredPort + 80 {
            do {
                let parameters = NWParameters.tcp
                parameters.allowLocalEndpointReuse = true
                let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: selectedPort)!)
                self.port = selectedPort
                self.listener = listener
                listener.newConnectionHandler = { [weak self] connection in
                    self?.handle(connection)
                }
                listener.start(queue: .global(qos: .userInitiated))
                return URL(string: "http://localhost:\(selectedPort)")!
            } catch {
                lastError = error
                selectedPort += 1
            }
        }

        throw lastError ?? AppError.message("사용 가능한 로컬 포트를 찾지 못했습니다.")
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, _, _ in
            guard let self else {
                connection.cancel()
                return
            }
            Task {
                let response = await self.response(for: data ?? Data())
                connection.send(content: response, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    private func response(for data: Data) async -> Data {
        guard
            let request = String(data: data, encoding: .utf8),
            let firstLine = request.components(separatedBy: "\r\n").first
        else {
            return http(status: 400, contentType: "text/plain; charset=utf-8", body: Data("Bad request".utf8))
        }

        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else {
            return http(status: 400, contentType: "text/plain; charset=utf-8", body: Data("Bad request".utf8))
        }

        let method = String(parts[0])
        let rawPath = String(parts[1])
        guard method == "GET" else {
            return http(status: 405, contentType: "text/plain; charset=utf-8", body: Data("Method not allowed".utf8))
        }

        let components = URLComponents(string: rawPath)
        let path = components?.path ?? "/"
        let queryItems = components?.queryItems ?? []

        do {
            if path == "/api/site" {
                return try await json(fruitsClient.sellerPayload(config: loadConfig()))
            }
            if path == "/api/products" {
                return try await json(fruitsClient.productsPayload(config: loadConfig()))
            }
            if path == "/api/product" {
                let id = Int(queryItems.first(where: { $0.name == "id" })?.value ?? "") ?? 0
                if id <= 0 {
                    return try json(["error": "Missing valid product id."], status: 400)
                }
                return try await json(fruitsClient.productPayload(config: loadConfig(), id: id))
            }
            if path == "/api/setup/config" {
                return try json(["config": loadConfig().jsonObject()])
            }
            if path == "/sitemap.xml" {
                return http(status: 200, contentType: "application/xml; charset=utf-8", body: Data("<urlset></urlset>".utf8))
            }

            return staticFile(path: path)
        } catch {
            return try! json(["error": error.localizedDescription], status: 502)
        }
    }

    private func loadConfig() throws -> SiteConfig {
        let url = projectURL.appendingPathComponent("site.config.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SiteConfig.self, from: data)
    }

    private func staticFile(path: String) -> Data {
        var relative = path == "/" ? "index.html" : String(path.dropFirst())
        if relative.isEmpty { relative = "index.html" }
        let publicURL = projectURL.appendingPathComponent("public", isDirectory: true).standardizedFileURL
        let fileURL = publicURL.appendingPathComponent(relative).standardizedFileURL

        guard
            fileURL.path.hasPrefix(publicURL.path),
            let body = try? Data(contentsOf: fileURL)
        else {
            return http(status: 404, contentType: "text/plain; charset=utf-8", body: Data("Not found".utf8))
        }

        return http(status: 200, contentType: contentType(for: fileURL.pathExtension), body: body)
    }

    private func json(_ object: [String: Any], status: Int = 200) throws -> Data {
        let body = try JSONSerialization.data(withJSONObject: object)
        return http(status: status, contentType: "application/json; charset=utf-8", body: body)
    }

    private func http(status: Int, contentType: String, body: Data) -> Data {
        let reason = [
            200: "OK",
            400: "Bad Request",
            404: "Not Found",
            405: "Method Not Allowed",
            502: "Bad Gateway"
        ][status] ?? "OK"
        var headers = "HTTP/1.1 \(status) \(reason)\r\n"
        headers += "content-type: \(contentType)\r\n"
        headers += "content-length: \(body.count)\r\n"
        headers += "cache-control: no-store\r\n"
        headers += "connection: close\r\n\r\n"
        return Data(headers.utf8) + body
    }

    private func contentType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": "text/html; charset=utf-8"
        case "css": "text/css; charset=utf-8"
        case "js": "text/javascript; charset=utf-8"
        case "json": "application/json; charset=utf-8"
        case "txt": "text/plain; charset=utf-8"
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        case "webp": "image/webp"
        default: "application/octet-stream"
        }
    }
}
