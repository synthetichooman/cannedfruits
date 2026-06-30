# Release Checklist

## 릴리즈 전 확인

- [ ] `swift build -c release`가 통과한다.
- [ ] `./scripts/package-app.sh`가 통과한다.
- [ ] `./scripts/release-app.sh`가 DMG, ZIP, SHA256 파일을 만든다.
- [ ] 앱을 실행했을 때 기본 프로젝트가 열린다.
- [ ] 로컬 미리보기 URL이 표시된다.
- [ ] 샵 만들기, 디자인, 내보내기, LLM 연결, 배포, 작업 권장사항, LLM 없이 한다면 메뉴가 보인다.
- [ ] 새 프로젝트를 만들 수 있다.
- [ ] 브라우저에서 미리보기가 열린다.
- [ ] 프로젝트 폴더 내보내기가 된다.

## 릴리즈 파일

업로드할 파일:

```text
dist/release/CannedFruits-v0.2n.dmg
dist/release/CannedFruits-v0.2n-macOS.zip
dist/release/SHA256SUMS.txt
```

## GitHub Release 설정

- Tag: `v0.2n`
- Title: `CannedFruits v0.2n`
- Target: `main`
- Set as latest release: yes
- Pre-release: yes, Developer ID와 notarization이 없으므로 초기에는 pre-release 권장

## 릴리즈 노트 템플릿

```md
## CannedFruits v0.2n

SwiftUI로 만든 CannedFruits macOS 앱의 첫 네이티브 릴리즈 후보입니다.

### 포함된 기능

- FruitsFamily 단일 셀러 웹샵 프로젝트 생성
- 로컬 브라우저 미리보기
- 색상, 로고, 디자인 메모 설정
- 완성된 프로젝트 폴더 내보내기
- LLM 연결 하네스
- GitHub/Cloudflare 배포 안내
- LLM 없이 직접 배포하는 수동 안내

### 설치 주의

이 빌드는 Apple Developer ID로 서명되거나 notarization 처리되지 않았습니다. 처음 실행할 때 macOS 경고가 나오면 앱을 우클릭한 뒤 `열기`를 선택하세요.

### 다운로드

- `CannedFruits-v0.2n.dmg` 권장
- `CannedFruits-v0.2n-macOS.zip` 대안
```

## GitHub CLI로 릴리즈 만들기

```bash
gh release create v0.2n \
  dist/release/CannedFruits-v0.2n.dmg \
  dist/release/CannedFruits-v0.2n-macOS.zip \
  dist/release/SHA256SUMS.txt \
  --title "CannedFruits v0.2n" \
  --notes-file docs/release-notes/v0.2n.md \
  --prerelease
```
