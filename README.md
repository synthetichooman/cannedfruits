# CannedFruits

CannedFruits는 FruitsFamily 셀러가 자신의 상품을 독립 웹샵처럼 보여줄 수 있도록 돕는 macOS 제작 앱입니다.

앱은 셀러 링크, 샵 이름, 색상, 로고, 디자인 메모를 받아 Cloudflare Pages에 배포 가능한 웹사이트 프로젝트 폴더를 만듭니다. 구매 버튼은 FruitsFamily 원본 상품 페이지로 이동하며, 결제와 최종 재고 확인은 FruitsFamily에서 처리됩니다.

> CannedFruits는 FruitsFamily와 관련이 없는 비공식 독립 도구입니다. 사용 과정에서 발생하는 계정, 운영, 정책상 불이익은 사용자에게 귀속됩니다.

## 현재 배포 상태

- 현재 릴리즈: `v0.2n`
- 배포 방식: GitHub Releases
- macOS 요구사항: macOS 14 이상
- Apple Developer ID: 없음
- Notarization: 없음

Developer ID가 없기 때문에 처음 실행할 때 macOS Gatekeeper 경고가 나올 수 있습니다. 사용자는 앱을 우클릭한 뒤 `열기`를 선택해 실행해야 할 수 있습니다.

## 사용자가 받는 파일

GitHub Releases에서 아래 파일을 제공합니다.

```text
CannedFruits-v0.2n.dmg
CannedFruits-v0.2n-macOS.zip
SHA256SUMS.txt
```

일반 사용자는 DMG를 받는 것을 권장합니다. ZIP은 DMG가 열리지 않을 때의 대안입니다.

## 앱이 만드는 웹 프로젝트 구조

앱에서 `완성된 프로젝트 폴더 내보내기`를 누르면 고객이 실제로 배포할 폴더가 만들어집니다.

```text
customer-shop/
  public/
  functions/
  harness/
  scripts/
  site.config.json
  package.json
  README.md
  AGENTS.md
```

고객 웹사이트는 이 폴더만 GitHub 저장소 루트에 올리고, Cloudflare Pages에 연결합니다. 이 앱 소스 저장소 전체를 고객 웹사이트 repo로 쓰지 않습니다.

## 빌드

```bash
swift build -c release
```

## 앱 패키징

```bash
./scripts/package-app.sh
```

결과물은 아래에 생성됩니다.

```text
dist/CannedFruits.app
```

## 릴리즈 파일 생성

```bash
./scripts/release-app.sh
```

결과물은 아래에 생성됩니다.

```text
dist/release/CannedFruits-v0.2n.dmg
dist/release/CannedFruits-v0.2n-macOS.zip
dist/release/SHA256SUMS.txt
```

다른 버전명으로 만들고 싶다면:

```bash
VERSION=v1.0.0 ./scripts/release-app.sh
```

## GitHub Release 절차

1. `./scripts/release-app.sh` 실행
2. `dist/release/` 안의 DMG, ZIP, SHA256 파일 확인
3. GitHub Releases에서 새 릴리즈 생성
4. 태그는 현재 버전 기준 `v0.2n`
5. 릴리즈 제목은 `CannedFruits v0.2n`
6. 릴리즈 노트는 [CHANGELOG.md](CHANGELOG.md)를 기준으로 작성
7. DMG, ZIP, SHA256 파일 업로드

자세한 체크리스트는 [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)를 보세요.

## 소스 구조

```text
Sources/CannedFruitsNative/
  AppModel.swift
  ContentView.swift
  FruitsClient.swift
  LocalPreviewServer.swift
  Models.swift

Resources/
  icon.icns
  app-engine-template/

scripts/
  package-app.sh
  release-app.sh
```

## CannedFruits의 운영 원칙

- 앱 소스와 앱 릴리즈만 이 저장소에서 관리합니다.
- 고객별 웹사이트 repo는 고객이 소유합니다.
- 고객의 Cloudflare Pages, GitHub, 커스텀 도메인은 고객 계정에 둡니다.
- CannedFruits 앱은 고객 계정에 대신 로그인하거나 배포를 자동 실행하지 않습니다.
- 사용자가 원하면 Codex나 Claude 같은 LLM으로 내보낸 프로젝트 폴더를 수정할 수 있게 하네스를 제공합니다.

## License

All rights reserved.
