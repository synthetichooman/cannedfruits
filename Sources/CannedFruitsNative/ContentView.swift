import AppKit
import SwiftUI

enum StudioStep: String, CaseIterable, Identifiable {
    case overview
    case setup
    case design
    case export
    case llm
    case deploy
    case recommendations
    case manualDeploy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "준비"
        case .setup: "샵 만들기"
        case .design: "디자인"
        case .export: "내보내기"
        case .llm: "LLM 연결"
        case .deploy: "배포"
        case .recommendations: "작업 권장사항"
        case .manualDeploy: "LLM 없이 한다면"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: StudioStep = .overview

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach(StudioStep.allCases) { step in
                        Label(step.title, systemImage: icon(for: step))
                            .tag(step)
                    }
                }
            }
            .navigationSplitViewColumnWidth(220)
            .safeAreaInset(edge: .top) {
                AppIdentityView()
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
            }
        } detail: {
            VStack(spacing: 0) {
                ToolbarHeader(title: selection.title)
                Divider()
                ScrollView {
                    Group {
                        switch selection {
                        case .overview:
                            OverviewPane(selection: $selection)
                        case .setup:
                            SetupPane()
                        case .design:
                            DesignPane()
                        case .export:
                            ExportPane()
                        case .llm:
                            LLMPane()
                        case .deploy:
                            DeployPane()
                        case .recommendations:
                            RecommendationsPane()
                        case .manualDeploy:
                            ManualDeployPane()
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .alert("확인이 필요합니다", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("확인") {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private func icon(for step: StudioStep) -> String {
        switch step {
        case .overview: "square.grid.2x2"
        case .setup: "slider.horizontal.3"
        case .design: "paintpalette"
        case .export: "square.and.arrow.down"
        case .llm: "text.bubble"
        case .deploy: "icloud.and.arrow.up"
        case .recommendations: "checklist.checked"
        case .manualDeploy: "book.pages"
        }
    }
}

struct AppIdentityView: View {
    var body: some View {
        HStack(spacing: 10) {
            CannedFruitsIconView(size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("CANNEDFRUITS")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("v0.2n")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
        }
    }
}

struct CannedFruitsIconView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = AppIconProvider.image() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.47, blue: 0.43), Color(red: 0.12, green: 0.37, blue: 0.33)], startPoint: .top, endPoint: .bottom))
                    .overlay(Text("CF").foregroundStyle(.white).font(.system(size: 11, weight: .bold)))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }
}

struct ToolbarHeader: View {
    @EnvironmentObject private var model: AppModel
    let title: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(model.previewURL?.absoluteString ?? model.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("프로젝트 폴더") {
                model.openCurrentProjectInFinder()
            }
            Button("새 프로젝트") {
                model.requestNewProject()
            }
            Button("열기") {
                model.requestOpenProject()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }
}

struct OverviewPane: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selection: StudioStep

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudioFormSection("CannedFruits 시작하기") {
                VStack(alignment: .leading, spacing: 9) {
                    Text("FruitsFamily 상품을 작은 독립 웹샵처럼 보여주는 제작 도구입니다.")
                        .font(.title2.weight(.semibold))
                    Text("CannedFruits가 웹사이트 폴더를 만들고, 그 폴더를 GitHub와 Cloudflare에 연결해 무료 플랜 중심으로 공개합니다.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Button("새 프로젝트 만들기") { model.requestNewProject() }
                        Button("기존 프로젝트 열기") { model.requestOpenProject() }
                        Button("샵 만들기 시작") { selection = .setup }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }

            NoticeCard(
                title: "필수 고지",
                systemImage: "exclamationmark.triangle",
                tint: .red,
                bodyText: "CannedFruits는 FruitsFamily와 관련이 없는 비공식 독립 도구입니다. 사용 과정에서 발생하는 계정, 운영, 정책상 불이익은 사용자에게 귀속됩니다."
            )

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    StudioFormSection("웹 구조 한눈에 보기") {
                        Text("내 컴퓨터의 프로젝트 폴더가 원본입니다. GitHub는 그 원본을 보관하고, Cloudflare Pages는 그 원본을 웹 주소로 공개합니다.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        ArchitectureFlow()
                    }

                    StudioFormSection("계정 준비") {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            AccountSetupCard(
                                title: "GitHub 계정 만들기",
                                systemImage: "tray.and.arrow.up",
                                role: "웹사이트 파일 보관",
                                detail: "프로젝트 폴더를 GitHub 저장소에 올립니다.",
                                buttonTitle: "GitHub 가입 열기",
                                urlString: "https://github.com/signup"
                            )
                            AccountSetupCard(
                                title: "Cloudflare 계정 만들기",
                                systemImage: "cloud",
                                role: "웹 주소로 공개",
                                detail: "Pages에서 GitHub 저장소를 선택하면 사이트가 열립니다.",
                                buttonTitle: "Cloudflare 가입 열기",
                                urlString: "https://dash.cloudflare.com/sign-up"
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                StudioFormSection("작업 흐름") {
                    VStack(alignment: .leading, spacing: 0) {
                        VerticalFlowStep(number: 1, title: "셀러 연결", text: "셀러 링크로 상품 데이터를 확인합니다.")
                        VerticalFlowStep(number: 2, title: "디자인 정리", text: "샵 이름, 레퍼런스, 색상을 저장합니다.")
                        VerticalFlowStep(number: 3, title: "브라우저 확인", text: "실제 웹을 브라우저로 엽니다.")
                        VerticalFlowStep(number: 4, title: "프로젝트 내보내기", text: "완성된 웹사이트 폴더를 만듭니다.")
                        VerticalFlowStep(number: 5, title: "LLM 연결", text: "Codex나 Claude에 폴더를 넣습니다.")
                        VerticalFlowStep(number: 6, title: "배포", text: "GitHub와 Cloudflare Pages를 연결합니다.", isLast: true)
                    }
                }
                .frame(width: 340, height: 398)
            }
        }
        .frame(maxWidth: 980, alignment: .leading)
    }
}

struct ArchitectureFlow: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ArchitectureFlowNode(
                title: "프로젝트 폴더",
                caption: "내 컴퓨터 원본",
                systemImage: "folder"
            )
            ArchitectureArrow()
            ArchitectureFlowNode(
                title: "GitHub",
                caption: "파일 보관",
                systemImage: "tray.and.arrow.up"
            )
            ArchitectureArrow()
            ArchitectureFlowNode(
                title: "Cloudflare",
                caption: "웹으로 공개",
                systemImage: "cloud"
            )
            ArchitectureArrow()
            ArchitectureFlowNode(
                title: "방문자",
                caption: "상품 둘러보기",
                systemImage: "person.crop.circle"
            )
            ArchitectureArrow()
            ArchitectureFlowNode(
                title: "FruitsFamily",
                caption: "구매 버튼 이동",
                systemImage: "arrow.up.forward.app"
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct ArchitectureFlowNode: View {
    let title: String
    let caption: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 94)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        )
    }
}

struct ArchitectureArrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .frame(width: 18)
    }
}

struct AccountSetupCard: View {
    let title: String
    let systemImage: String
    let role: String
    let detail: String
    let buttonTitle: String
    let urlString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                Text(title)
                    .font(.callout.weight(.semibold))
                Spacer()
            }
            Text(role)
                .font(.caption.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(buttonTitle) {
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.caption.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 132, maxHeight: 132, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        )
    }
}

struct NoticeCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(bodyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }
}

struct FlowRow: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct VerticalFlowStep: View {
    let number: Int
    let title: String
    let text: String
    let isLast: Bool

    init(number: Int, title: String, text: String, isLast: Bool = false) {
        self.number = number
        self.title = title
        self.text = text
        self.isLast = isLast
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                if !isLast {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.9))
                        .frame(width: 2, height: 28)
                        .padding(.vertical, 3)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct StudioFormSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 1)
        )
    }
}

struct StudioTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text, axis: isMultiline ? .vertical : .horizontal)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(isMultiline ? 3 : 1, reservesSpace: isMultiline)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isFocused ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isFocused ? 1.6 : 1)
                )
                .shadow(color: .black.opacity(isFocused ? 0.08 : 0.03), radius: isFocused ? 8 : 2, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HexColorPickerField: View {
    let title: String
    @Binding var hex: String
    var fallback: Color
    @State private var selectedColor: Color = .black
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 34, height: 28)

                TextField("#111111", text: $hex)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .textCase(.uppercase)
                    .focused($isFocused)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(colorFromHex(hex) ?? fallback)
                    .frame(width: 34, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isFocused ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isFocused ? 1.6 : 1)
            )
            .shadow(color: .black.opacity(isFocused ? 0.08 : 0.03), radius: isFocused ? 8 : 2, y: 1)
        }
        .onAppear {
            selectedColor = colorFromHex(hex) ?? fallback
            if colorFromHex(hex) == nil {
                hex = hexString(from: fallback)
            }
        }
        .onChange(of: selectedColor) { _, value in
            hex = hexString(from: value)
        }
        .onChange(of: hex) { _, value in
            if let next = colorFromHex(value) {
                selectedColor = next
            }
        }
    }
}

struct SetupPane: View {
    @EnvironmentObject private var model: AppModel
    @State private var siteName = ""
    @State private var sellerURL = ""
    @State private var description = ""
    @State private var domain = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioFormSection("기본 정보") {
                StudioTextInput(title: "샵 이름", placeholder: "예: hooman", text: $siteName)
                StudioTextInput(title: "FruitsFamily 셀러 링크", placeholder: "https://fruitsfamily.com/seller/93s/synthetichooman", text: $sellerURL)
                StudioTextInput(title: "사이트 설명", placeholder: "첫 화면에 표시할 짧은 소개", text: $description, isMultiline: true)
                StudioTextInput(title: "커스텀 도메인 메모", placeholder: "예: shop.example.com", text: $domain)
            }

            StudioFormSection("셀러 연결") {
                HStack {
                    Button("셀러 확인") {
                        Task { await model.resolveSeller(url: sellerURL) }
                    }
                    Button("설정 저장") {
                        model.saveBasic(siteName: siteName, sellerURL: sellerURL, description: description, domain: domain)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Text(model.sellerSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 780, alignment: .leading)
        .onAppear(perform: sync)
        .onChange(of: model.config?.site.name) { _, _ in sync() }
    }

    private func sync() {
        guard let config = model.config else { return }
        siteName = config.site.name
        sellerURL = config.seller.canonicalUrl
        description = config.site.description
        domain = config.site.domain
    }
}

struct DesignPane: View {
    @EnvironmentObject private var model: AppModel
    @State private var referenceURL = ""
    @State private var notes = ""
    @State private var accent = ""
    @State private var background = ""
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioFormSection("디자인 브리프") {
                Text("레퍼런스 링크와 원하는 분위기는 웹에 자동 적용되지 않습니다. 내보낸 프로젝트를 LLM에 연결했을 때 디자인 수정 방향으로 쓰는 메모입니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                StudioTextInput(title: "디자인 레퍼런스 링크", placeholder: "https://example.com", text: $referenceURL)
                StudioTextInput(title: "원하는 분위기", placeholder: "예: 미니멀, 조용한 편집숍, 여백 중심", text: $notes, isMultiline: true)
            }

            StudioFormSection("색상") {
                Text("강조 색상, 배경 색상, 글꼴 색상은 저장하면 브라우저에서 여는 실제 웹에 반영됩니다. 구분선과 보조선도 글꼴 색상 계열을 따라갑니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HexColorPickerField(title: "강조 색상", hex: $accent, fallback: .black)
                HexColorPickerField(title: "배경 색상", hex: $background, fallback: .white)
                HexColorPickerField(title: "글꼴 색상", hex: $text, fallback: .black)
                Button("디자인 메모 저장") {
                    model.saveDesign(referenceURL: referenceURL, notes: notes, accent: accent, background: background, text: text)
                }
                .buttonStyle(.borderedProminent)
            }

            StudioFormSection("로고") {
                Text("로고 파일을 선택하면 앱이 웹 상단 심볼과 브라우저 탭 아이콘용 PNG로 조절해 프로젝트 폴더에 저장합니다. 저장 후 브라우저에서 열거나 새로고침하면 반영됩니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: 14) {
                    LogoPreview(projectURL: model.projectURL, logo: model.config?.design.logo)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.logoStatus)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        HStack(spacing: 8) {
                            Button("로고 파일 선택") {
                                model.chooseLogoFile()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("브라우저에서 확인") {
                                if let url = model.previewURL {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .disabled(model.previewURL == nil)
                        }
                    }
                }
            }

            StudioFormSection("브라우저에서 실제 웹 확인") {
                Text("앱 안에 웹을 끼워 넣지 않고, 기본 브라우저에서 실제 로컬 웹사이트를 엽니다. 색상을 저장한 뒤 이미 열린 브라우저 탭이 있다면 새로고침하면 됩니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button("브라우저에서 열기") {
                        if let url = model.previewURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.previewURL == nil)

                    Button("저장 후 열기") {
                        model.saveDesign(referenceURL: referenceURL, notes: notes, accent: accent, background: background, text: text)
                        if let url = model.previewURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .disabled(model.previewURL == nil)
                }
            }
        }
        .frame(maxWidth: 780, alignment: .leading)
        .onAppear(perform: sync)
    }

    private func sync() {
        guard let config = model.config else { return }
        referenceURL = config.design.referenceUrl
        notes = config.design.notes
        accent = config.theme.accent
        background = config.theme.background
        text = config.theme.text
    }
}

struct LogoPreview: View {
    let projectURL: URL?
    let logo: SiteConfig.Logo?

    var body: some View {
        Group {
            if let image = logoImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .padding(10)
            } else {
                VStack(spacing: 7) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title2)
                    Text("로고 없음")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: 82, height: 82)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var logoImage: NSImage? {
        guard let projectURL, let symbol = logo?.symbol else { return nil }
        let relative = symbol.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let imageURL = projectURL.appendingPathComponent("public", isDirectory: true).appendingPathComponent(relative)
        return NSImage(contentsOf: imageURL)
    }
}

struct ExportPane: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox("완성된 프로젝트 폴더 내보내기") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("내보낸 폴더가 최종 웹사이트 프로젝트입니다. 이 폴더를 Codex나 Claude 프로젝트로 열고, GitHub/Cloudflare 연결도 그 안에서 진행합니다.")
                        .foregroundStyle(.secondary)
                    Button("폴더 내보내기") {
                        model.exportProject()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            GroupBox("최근 내보낸 위치") {
                Text(model.exportPath)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: 820, alignment: .leading)
    }
}

struct LLMPane: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingHarness = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioFormSection("LLM 하네스란?") {
                Text("하네스는 Codex나 Claude에게 이 프로젝트의 규칙을 먼저 알려주는 시작 프롬프트입니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                FlowRow(number: 1, title: "무엇을 읽을지 지정", text: "README, AGENTS, site.config.json, public, functions 파일을 먼저 보게 합니다.")
                FlowRow(number: 2, title: "위험한 수정 방지", text: "결제, 장바구니, 로그인 같은 기능을 만들지 말라고 제한합니다.")
                FlowRow(number: 3, title: "FruitsFamily 연결 규칙 유지", text: "구매 버튼은 FruitsFamily 상품 페이지로 보내고, Sold 표기와 필수 고지를 유지하게 합니다.")
                FlowRow(number: 4, title: "검증 습관 만들기", text: "수정 후 npm run check와 브라우저 확인을 점검하게 합니다.")
                FlowRow(number: 5, title: "한국어 응답 고정", text: "하네스 본문은 영어지만, 사용자에게 보이는 답변은 한국어로 하도록 지시합니다.")
            }

            StudioFormSection("사용 방법") {
                Text("내보낸 프로젝트 폴더를 Codex나 Claude에서 열고, 아래 버튼으로 하네스를 복사해 첫 메시지로 붙여넣으세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button("LLM 하네스 복사") {
                        model.copyLLMHarness()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("하네스 원문 보기") {
                        showingHarness = true
                    }
                }
            }

            NoticeCard(
                title: "추천",
                systemImage: "sparkles",
                tint: .blue,
                bodyText: "디자인 수정, 배포 연결, 오류 해결은 하네스를 붙인 LLM과 함께 진행하는 것을 권장합니다. 개발 지식이 적어도 LLM이 파일을 읽고 다음 행동을 안내할 수 있습니다."
            )
        }
        .frame(maxWidth: 860, alignment: .leading)
        .sheet(isPresented: $showingHarness) {
            HarnessPreviewSheet(text: model.llmHarnessText()) {
                model.copyLLMHarness()
            }
        }
    }
}

struct DeployPane: View {
    @EnvironmentObject private var model: AppModel

    private var deploymentPrompt: String {
        """
        이 폴더는 CannedFruits로 만든 FruitsFamily 미러 웹사이트 프로젝트입니다.

        나는 개발 지식이 많지 않습니다. 이 프로젝트 폴더를 GitHub에 올리고 Cloudflare Pages로 배포하는 과정을 아주 쉽게, 한 단계씩 도와주세요.

        먼저 README.md, AGENTS.md, harness/LLM_PROMPT.md, harness/REFERENCE.md를 읽고 구조를 파악해주세요.

        도와줄 때는:
        - 모든 설명을 한국어로 해주세요.
        - GitHub 저장소 만들기부터 안내해주세요.
        - 내가 GitHub Desktop을 쓰는 방식과 웹에서 업로드하는 방식 중 쉬운 방법을 추천해주세요.
        - Cloudflare Pages에서 어떤 저장소를 선택하고 어떤 설정을 넣어야 하는지 알려주세요.
        - Build command, output directory, functions directory 설정을 확인해주세요.
        - 커스텀 도메인은 Cloudflare Pages 배포 후 Custom domains에서 연결해야 한다고 안내해주세요.
        - CannedFruits가 FruitsFamily와 무관한 비공식 도구라는 고지는 유지해주세요.
        - 배포 전후에 npm run check로 확인해주세요.

        내가 화면에서 무엇을 눌러야 하는지 하나씩 물어보면서 진행해주세요.
        """
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NoticeCard(
                title: "배포는 LLM과 함께 진행하세요",
                systemImage: "person.crop.circle.badge.questionmark",
                tint: .blue,
                bodyText: "이 앱은 GitHub나 Cloudflare에 대신 로그인하지 않습니다. 완성된 프로젝트 폴더를 내보낸 뒤, Codex나 Claude에 폴더를 연결하고 아래 요청문을 붙여넣는 흐름이 가장 쉽습니다."
            )

            StudioFormSection("전체 흐름") {
                DeployRow(number: 1, text: "GitHub에서 새 저장소를 만듭니다.")
                DeployRow(number: 2, text: "내보낸 프로젝트 폴더의 파일을 저장소 루트에 올립니다.")
                DeployRow(number: 3, text: "Cloudflare Pages에서 GitHub 저장소를 선택합니다.")
                DeployRow(number: 4, text: "Build command는 비우고 output은 public으로 둡니다.")
                DeployRow(number: 5, text: "Functions directory는 functions로 둡니다.")
                DeployRow(number: 6, text: "도메인은 배포 후 Custom domains에서 연결합니다.")
            }

            StudioFormSection("LLM에게 붙여넣을 요청문") {
                Text("아래 문장을 복사해서, 내보낸 프로젝트 폴더를 열어둔 Codex나 Claude에 붙여넣으세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                PromptSampleBox(text: deploymentPrompt) {
                    model.copyToClipboard(deploymentPrompt)
                }
            }
        }
        .frame(maxWidth: 900, alignment: .leading)
    }
}

struct RecommendationsPane: View {
    @EnvironmentObject private var model: AppModel

    private var domainPrompt: String {
        """
        이 프로젝트는 CannedFruits로 만든 FruitsFamily 미러 웹사이트입니다.
        배포가 끝난 뒤 커스텀 도메인을 연결하고 싶습니다.

        현재 프로젝트 구조와 README, AGENTS, harness 파일을 읽고 다음을 한국어로 아주 쉽게 도와주세요.
        1. Cloudflare Pages의 Custom domains 메뉴에서 무엇을 눌러야 하는지
        2. 내가 Gabia 같은 도메인 등록기관에서 무엇을 설정해야 하는지
        3. 루트 도메인과 서브도메인 중 무엇이 쉬운지
        4. DNS 전파 대기 중 무엇을 확인해야 하는지
        5. 연결 후 사이트에서 도메인과 sitemap 설정을 점검하는 방법
        """
    }

    private var maintenancePrompt: String {
        """
        이 프로젝트는 CannedFruits로 만든 FruitsFamily 미러 웹사이트입니다.
        운영 중 API 연결 실패나 상품 로드 실패를 감지하고 알림을 받고 싶습니다.

        다음 유지보수 도구를 설계하고, 가능한 가장 단순한 MVP부터 제안해주세요.
        1. 일정 간격으로 /api/site, /api/products를 확인하는 모니터
        2. 실패 시 Telegram bot으로 알림 보내기
        3. 실패 로그와 마지막 성공 시각 저장
        4. 필요하면 새로고침 또는 재배포를 유도하는 방법
        5. Cloudflare Workers, GitHub Actions, 로컬 스크립트 중 비전공자에게 가장 쉬운 운영 방식 비교

        모든 설명과 파일 수정 안내는 한국어로 해주세요.
        """
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NoticeCard(
                title: "배포 후에는 작게 운영을 시작하세요",
                systemImage: "checkmark.seal",
                tint: .blue,
                bodyText: "처음에는 사이트가 정상으로 열리는지 확인하고, 그 다음 커스텀 도메인과 간단한 장애 알림을 붙이면 충분합니다."
            )

            StudioFormSection("1. 커스텀 도메인 연결") {
                RecommendationCard(
                    systemImage: "globe",
                    title: "Cloudflare Pages에서 연결",
                    bodyText: "배포가 끝난 뒤 Pages 프로젝트의 Custom domains 메뉴에서 도메인을 추가합니다. Gabia 같은 외부 등록기관에서 산 도메인은 DNS 설정을 Cloudflare 안내에 맞춰 바꿔야 합니다."
                )
                RecommendationStep(number: 1, text: "도메인을 먼저 구매하거나 보유 도메인을 정합니다.")
                RecommendationStep(number: 2, text: "Cloudflare Pages의 Custom domains에서 도메인을 추가합니다.")
                RecommendationStep(number: 3, text: "도메인 등록기관 또는 Cloudflare DNS에서 안내된 레코드를 설정합니다.")
                RecommendationStep(number: 4, text: "연결 완료 후 실제 도메인으로 상품 상세 페이지까지 열어봅니다.")
                Button("도메인 연결 요청문 복사") {
                    model.copyToClipboard(domainPrompt)
                }
                .buttonStyle(.borderedProminent)
            }

            StudioFormSection("2. 유지보수 도구") {
                RecommendationCard(
                    systemImage: "bell.badge",
                    title: "API 실패 알림부터 작게 시작",
                    bodyText: "운영 자동화는 처음부터 크게 만들 필요가 없습니다. 일정 간격으로 API가 응답하는지 확인하고, 실패하면 Telegram으로 알려주는 작은 모니터가 가장 현실적입니다."
                )
                RecommendationStep(number: 1, text: "/api/site와 /api/products가 정상 응답하는지 주기적으로 확인합니다.")
                RecommendationStep(number: 2, text: "실패가 반복되면 Telegram bot으로 알림을 보냅니다.")
                RecommendationStep(number: 3, text: "마지막 성공 시각과 오류 메시지를 기록합니다.")
                RecommendationStep(number: 4, text: "나중에 필요하면 수동 새로고침, 캐시 무효화, 재배포 안내까지 확장합니다.")
                Button("유지보수 도구 요청문 복사") {
                    model.copyToClipboard(maintenancePrompt)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: 900, alignment: .leading)
    }
}

struct ManualDeployPane: View {
    @EnvironmentObject private var model: AppModel

    private var manualChecklist: String {
        """
        CannedFruits 수동 배포 체크리스트

        1. 내보낸 프로젝트 폴더만 사용한다.
           - 폴더 루트에 public, functions, site.config.json, package.json이 보여야 한다.
           - CannedFruits.app, dist, .build, node_modules, 상위 개발 폴더는 GitHub에 올리지 않는다.

        2. GitHub 저장소에 프로젝트 파일을 올린다.
           - GitHub Desktop에서 내보낸 폴더를 Add Local Repository로 연다.
           - 저장소가 아니라고 나오면 Create Repository를 누른다.
           - Summary에 Initial CannedFruits storefront라고 적고 Commit to main을 누른다.
           - Publish repository를 눌러 GitHub에 올린다.

        3. Cloudflare Pages에서 GitHub 저장소를 연결한다.
           - Workers & Pages > Create application > Pages > Connect to Git
           - 방금 만든 GitHub 저장소를 선택한다.
           - Framework preset: None 또는 No preset
           - Build command: 비움
           - Build output directory: public
           - Root directory: 비움 또는 repository root
           - Functions directory를 묻는다면: functions
           - Environment variables: 기본 MVP에서는 없음

        4. 배포 후 확인한다.
           - / 페이지가 열린다.
           - /api/site가 JSON으로 열린다.
           - /api/products가 JSON으로 열린다.
           - 상품 상세 페이지가 열린다.
           - 구매 버튼이 FruitsFamily 상품 페이지로 이동한다.
           - sold 상품은 sold로 표시된다.
           - CannedFruits가 FruitsFamily와 무관하다는 고지가 남아 있다.

        5. 커스텀 도메인은 배포 후 Cloudflare Pages의 Custom domains에서 따로 연결한다.
           - 쉬운 방법: shop.example.com 같은 서브도메인 사용
           - Gabia 같은 외부 등록기관을 계속 쓰면 CNAME을 설정한다.
           - 루트 도메인 example.com을 쓰려면 Cloudflare에 도메인을 추가하고 네임서버를 Cloudflare로 바꾸는 흐름이 보통 필요하다.
           - DNS만 먼저 만들지 말고, Pages 프로젝트의 Custom domains에서 도메인을 먼저 추가한다.
        """
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NoticeCard(
                title: "AI 없이도 가능하지만, 확인할 것이 많습니다",
                systemImage: "hand.raised",
                tint: .orange,
                bodyText: "LLM을 쓰지 않는다면 사람이 직접 GitHub 저장소 구조, Cloudflare Pages 설정, Functions 연결, 도메인 DNS, 배포 후 점검을 확인해야 합니다. 이 페이지는 그 과정을 최대한 풀어쓴 수동 설명서입니다."
            )

            StudioFormSection("이 웹이 돌아가는 방식") {
                Text("프로젝트 폴더가 원본이고, GitHub는 그 원본을 보관합니다. Cloudflare Pages는 GitHub에 올라간 파일을 읽어서 `public` 폴더를 웹사이트로 공개하고, `functions` 폴더를 API처럼 실행합니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ManualChecklistRow(text: "방문자가 첫 화면을 열면 Cloudflare가 `public/index.html`을 보여줍니다.")
                ManualChecklistRow(text: "화면의 JavaScript가 `/api/products`를 호출하면 `functions/api/products.js`가 FruitsFamily 셀러 상품을 가져옵니다.")
                ManualChecklistRow(text: "상품 상세는 `/product.html?id=상품ID`로 열리고, 구매 버튼은 FruitsFamily 원본 상품 링크로 이동합니다.")
                ManualChecklistRow(text: "결제, 장바구니, 회원가입은 이 사이트가 처리하지 않습니다. 최종 구매와 재고 확인은 FruitsFamily에서 처리됩니다.")
            }

            StudioFormSection("GitHub에 올리기 전 확인") {
                ManualChecklistRow(text: "Mac 앱에서 `완성된 프로젝트 폴더 내보내기`로 만든 폴더만 사용합니다.")
                ManualChecklistRow(text: "폴더를 열었을 때 `public`, `functions`, `site.config.json`, `package.json`, `README.md`가 바로 보여야 합니다.")
                ManualChecklistRow(text: "`v0.2n`, `dist`, `.app`, `.build`, `node_modules`, `.DS_Store` 같은 앱 개발 파일은 올리지 않습니다.")
                ManualChecklistRow(text: "`site.config.json`에서 셀러 정보, 샵 이름, 도메인 메모, 색상 설정이 의도와 맞는지 확인합니다.")
                ManualChecklistRow(text: "가능하면 배포 전에 로컬에서 `npm run check`를 실행해 셀러와 상품 데이터를 확인합니다.")
            }

            StudioFormSection("1. GitHub Desktop으로 저장소 올리기") {
                FlowRow(number: 1, title: "GitHub Desktop 설치 및 로그인", text: "Git 명령어가 익숙하지 않다면 GitHub Desktop이 가장 쉽습니다. 앱을 열고 GitHub 계정으로 로그인합니다.")
                FlowRow(number: 2, title: "내보낸 폴더 열기", text: "File > Add Local Repository를 누르고 CannedFruits에서 내보낸 프로젝트 폴더를 선택합니다. 저장소가 아니라고 나오면 Create Repository를 선택합니다.")
                FlowRow(number: 3, title: "첫 커밋 만들기", text: "변경 파일 목록에 프로젝트 파일이 보이면 Summary에 `Initial CannedFruits storefront`라고 적고 Commit to main을 누릅니다.")
                FlowRow(number: 4, title: "GitHub에 공개", text: "Publish repository를 누릅니다. Private 저장소도 가능하지만, Cloudflare 연결 화면에서 저장소 접근 권한을 허용해야 합니다.")
                FlowRow(number: 5, title: "루트 구조 확인", text: "GitHub 웹사이트에서 저장소를 열었을 때 `public`과 `functions`가 저장소 첫 화면에 바로 보여야 합니다. 바깥 폴더를 한 겹 더 올리면 Cloudflare 설정이 꼬입니다.")
                HStack(spacing: 8) {
                    ManualExternalLinkButton(title: "GitHub Desktop 문서", urlString: "https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop")
                    ManualExternalLinkButton(title: "로컬 저장소 추가 문서", urlString: "https://docs.github.com/en/desktop/adding-and-cloning-repositories/adding-a-repository-from-your-local-computer-to-github-desktop")
                }
            }

            StudioFormSection("2. Cloudflare Pages 연결") {
                Text("CannedFruits는 정적인 HTML만 올리는 사이트가 아닙니다. FruitsFamily 상품을 새로 불러오기 위해 Pages Functions를 쓰므로, Cloudflare Pages가 `functions` 폴더를 함께 인식해야 합니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                FlowRow(number: 1, title: "Pages 프로젝트 만들기", text: "Cloudflare Dashboard > Workers & Pages > Create application > Pages > Connect to Git 순서로 들어갑니다.")
                FlowRow(number: 2, title: "GitHub 저장소 선택", text: "Cloudflare가 GitHub 접근 권한을 묻는다면 방금 만든 저장소를 허용하고 선택합니다.")
                FlowRow(number: 3, title: "빌드 설정 입력", text: "아래 설정값을 그대로 넣습니다. 이 부분이 틀리면 첫 화면은 떠도 상품 API가 작동하지 않을 수 있습니다.")
                ManualSettingRow(label: "Framework preset", value: "None 또는 No preset", note: "별도 프레임워크 빌드가 없는 순수 Pages 프로젝트입니다.")
                ManualSettingRow(label: "Build command", value: "비움", note: "빌드 과정 없이 `public` 폴더를 그대로 배포합니다.")
                ManualSettingRow(label: "Build output directory", value: "public", note: "방문자에게 공개될 HTML, CSS, JS가 들어 있는 폴더입니다.")
                ManualSettingRow(label: "Root directory", value: "비움 또는 repository root", note: "`public`과 `functions`가 저장소 루트에 있는 구조여야 합니다.")
                ManualSettingRow(label: "Functions directory", value: "functions", note: "화면에서 묻는 경우에만 입력합니다. 묻지 않아도 루트의 `functions` 폴더는 유지해야 합니다.")
                ManualSettingRow(label: "Environment variables", value: "없음", note: "현재 MVP는 별도 API 키나 비밀값이 필요하지 않습니다.")
                FlowRow(number: 4, title: "Save and Deploy", text: "설정을 저장하고 첫 배포가 성공할 때까지 기다립니다. 이후 GitHub에 새 커밋을 올리면 Cloudflare가 다시 배포합니다.")
                HStack(spacing: 8) {
                    ManualExternalLinkButton(title: "Cloudflare Git 연결", urlString: "https://developers.cloudflare.com/pages/get-started/git-integration/")
                    ManualExternalLinkButton(title: "Build 설정 문서", urlString: "https://developers.cloudflare.com/pages/configuration/build-configuration/")
                    ManualExternalLinkButton(title: "Functions 문서", urlString: "https://developers.cloudflare.com/pages/functions/get-started/")
                }
            }

            StudioFormSection("3. 배포 후 반드시 열어볼 주소") {
                Text("Cloudflare가 만들어준 `프로젝트이름.pages.dev` 주소에서 아래를 차례로 확인합니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ManualChecklistRow(text: "`/` : 상품 목록이 보이는지 확인합니다.")
                ManualChecklistRow(text: "`/api/site` : JSON 텍스트가 보이면 Functions가 작동하는 것입니다.")
                ManualChecklistRow(text: "`/api/products` : 상품 목록 JSON이 보이면 FruitsFamily 데이터 연결이 살아 있습니다.")
                ManualChecklistRow(text: "상품 하나를 눌러 상세 페이지가 깨지지 않는지 봅니다.")
                ManualChecklistRow(text: "Buy on FruitsFamily 버튼을 눌렀을 때 FruitsFamily 원본 상품 페이지가 새 탭으로 열리는지 봅니다.")
                ManualChecklistRow(text: "판매 완료 상품은 archive가 아니라 sold로 표시되는지 봅니다.")
                ManualChecklistRow(text: "하단 또는 고지 영역에 CannedFruits가 FruitsFamily와 무관한 비공식 도구라는 문구가 유지되는지 확인합니다.")
            }

            StudioFormSection("4. 커스텀 도메인 연결") {
                Text("도메인은 CannedFruits 앱에서 자동 연결되지 않습니다. 앱의 도메인 입력은 사이트 설정과 sitemap에 쓸 주소를 적어두는 역할이고, 실제 연결은 Cloudflare Pages의 Custom domains에서 합니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                FlowRow(number: 1, title: "쉬운 방식 선택", text: "처음에는 `shop.example.com` 같은 서브도메인이 가장 쉽습니다. 루트 도메인 `example.com`은 네임서버 변경까지 필요할 수 있어 난도가 올라갑니다.")
                FlowRow(number: 2, title: "Cloudflare에서 도메인 추가", text: "Pages 프로젝트 > Custom domains > Set up a domain을 누르고 연결할 도메인을 입력합니다.")
                FlowRow(number: 3, title: "DNS 설정", text: "Gabia 같은 외부 등록기관을 쓰는 서브도메인이라면 CNAME을 만들고, 대상값은 보통 `<프로젝트이름>.pages.dev`가 됩니다. Cloudflare가 화면에 보여주는 값을 우선합니다.")
                FlowRow(number: 4, title: "루트 도메인 주의", text: "`example.com` 자체를 쓰려면 도메인을 Cloudflare zone으로 추가하고, Gabia의 네임서버를 Cloudflare가 제시한 네임서버로 바꾸는 흐름이 보통 필요합니다.")
                FlowRow(number: 5, title: "반드시 Pages에도 등록", text: "DNS 레코드만 손으로 만들면 충분하지 않습니다. Cloudflare Pages의 Custom domains 절차를 먼저 거쳐야 정상 연결됩니다.")
                ManualExternalLinkButton(title: "Cloudflare Custom domains 문서", urlString: "https://developers.cloudflare.com/pages/configuration/custom-domains/")
            }

            StudioFormSection("5. 문제가 생기면 확인할 것") {
                ManualChecklistRow(text: "첫 화면이 404라면 `Build output directory`가 `public`인지 확인합니다.")
                ManualChecklistRow(text: "`/api/products`가 404라면 `functions` 폴더가 저장소 루트에 있는지 확인합니다.")
                ManualChecklistRow(text: "상품이 비어 있으면 FruitsFamily 셀러 링크가 공개 페이지인지, `site.config.json`의 seller 정보가 맞는지 확인합니다.")
                ManualChecklistRow(text: "수정했는데 사이트가 그대로라면 GitHub Desktop에서 새 커밋을 만들고 Publish 또는 Push를 했는지 확인합니다.")
                ManualChecklistRow(text: "도메인이 안 열리면 DNS 전파를 기다리고, Pages 프로젝트의 Custom domains 상태가 Active인지 확인합니다.")
                ManualChecklistRow(text: "Cloudflare 배포 로그에서 실패한 파일명이나 설정명을 확인합니다. 대부분 폴더 위치, output directory, functions 위치 문제입니다.")
            }

            StudioFormSection("AI가 원래 대신 확인해주는 일") {
                Text("LLM을 쓰면 아래 항목을 같이 읽고 점검해 줍니다. AI를 쓰는 사람도 이 목록을 한 번 보면 전체 구조를 이해하기 쉽습니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ManualChecklistRow(text: "저장소 루트가 맞는지 확인합니다.")
                ManualChecklistRow(text: "Cloudflare Pages 설정값이 `public`과 `functions` 구조에 맞는지 확인합니다.")
                ManualChecklistRow(text: "필수 고지, sold 표기, FruitsFamily CTA 링크가 유지되는지 확인합니다.")
                ManualChecklistRow(text: "`npm run check` 또는 `/api/products`로 실제 상품 데이터가 오는지 확인합니다.")
                ManualChecklistRow(text: "도메인 연결 후 `site.config.json`의 도메인 메모와 실제 접속 주소가 맞는지 확인합니다.")
                PromptSampleBox(text: manualChecklist) {
                    model.copyToClipboard(manualChecklist)
                }
            }
        }
        .frame(maxWidth: 980, alignment: .leading)
    }
}

struct RecommendationCard: View {
    let systemImage: String
    let title: String
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(bodyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        )
    }
}

struct RecommendationStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

struct DeployRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            Text(text)
            Spacer()
        }
    }
}

struct ManualChecklistRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

struct ManualSettingRow: View {
    let label: String
    let value: String
    let note: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.callout.weight(.semibold))
                .frame(width: 170, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(.callout, design: .monospaced).weight(.semibold))
                    .textSelection(.enabled)
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        )
    }
}

struct ManualExternalLinkButton: View {
    let title: String
    let urlString: String

    var body: some View {
        Button {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Label(title, systemImage: "arrow.up.forward")
        }
        .buttonStyle(.bordered)
    }
}

struct PromptSampleBox: View {
    let text: String
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                Text(text)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 190, maxHeight: 240)
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            Button("요청문 복사") {
                onCopy()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct HarnessPreviewSheet: View {
    let text: String
    let onCopy: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LLM 하네스 원문")
                        .font(.title2.weight(.semibold))
                    Text("이 내용을 LLM 첫 메시지로 붙여넣으면 프로젝트 규칙을 먼저 읽게 됩니다.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("닫기") {
                    dismiss()
                }
            }

            ScrollView {
                Text(text)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            HStack {
                Spacer()
                Button("하네스 복사") {
                    onCopy()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 760, height: 620)
    }
}

enum AppIconProvider {
    static func image() -> NSImage? {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let candidates: [URL?] = [
            Bundle.main.url(forResource: "icon", withExtension: "icns"),
            Bundle.main.resourceURL?.appendingPathComponent("icon.icns"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/icon.icns"),
            sourceRoot.appendingPathComponent("Resources/icon.icns"),
        ]

        for url in candidates.compactMap({ $0 }) {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }

        return nil
    }
}

private func colorFromHex(_ value: String) -> Color? {
    guard let color = nsColorFromHex(value) else { return nil }
    return Color(nsColor: color)
}

private func nsColorFromHex(_ value: String) -> NSColor? {
    let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let expanded: String

    if raw.count == 3 {
        expanded = raw.map { "\($0)\($0)" }.joined()
    } else {
        expanded = raw
    }

    guard expanded.count == 6, let number = UInt64(expanded, radix: 16) else {
        return nil
    }

    let red = CGFloat((number & 0xFF0000) >> 16) / 255
    let green = CGFloat((number & 0x00FF00) >> 8) / 255
    let blue = CGFloat(number & 0x0000FF) / 255
    return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
}

private func hexString(from color: Color) -> String {
    let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? .black
    return String(
        format: "#%02X%02X%02X",
        Int(round(nsColor.redComponent * 255)),
        Int(round(nsColor.greenComponent * 255)),
        Int(round(nsColor.blueComponent * 255))
    )
}
