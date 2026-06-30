# cannedfruits v0.1

FruitsFamily 셀러가 자기 상품을 독립 자사몰처럼 보여줄 수 있게 만든 커스텀 스토어프론트 키트입니다.

상품 데이터는 FruitsFamily에서 가져오고, 구매 버튼은 FruitsFamily 상품 페이지로 이동합니다. 이 사이트에서는 결제, 주문, 로그인, 고객 응대를 처리하지 않습니다.

cannedfruits는 FruitsFamily와 관련이 없는 비공식 독립 도구입니다. 사용 과정에서 발생하는 계정, 운영, 정책상 불이익은 사용자에게 귀속됩니다.

## 개발 방향

현재 목표는 완전 초보 사용자가 처음부터 끝까지 혼자 배포하는 도구가 아니라, **LLM과 함께 수정 가능한 DIY 패키지**를 먼저 완성하는 것입니다.

이후 같은 기반에서 아래 상품을 분리합니다.

- DIY 패키지: 사용자가 LLM과 함께 직접 수정
- Guided Setup: 제작자가 초기 연결과 배포를 도와주고, 이후 사용자가 관리
- Managed Launch: 제작자가 디자인, 배포, 도메인 연결까지 처리

상세한 개발 기준, 디자인 규칙, 배포 기준, 유지보수 계획은 [harness/REFERENCE.md](harness/REFERENCE.md)에 통합되어 있습니다.

## 처음 할 일

이 폴더는 CannedFruits Mac 앱에서 내보낸 웹사이트 프로젝트입니다.

처음 설정, 디자인 입력, 로고 선택, 내보내기, 배포 안내는 Mac 앱에서 진행합니다.

웹 결과물을 로컬에서만 확인하고 싶다면 `START_HERE.command` 파일을 더블클릭하세요.

수정과 개선은 Codex나 Claude 같은 LLM을 연결하고, `LLM 연결 방법`과 `LLM 하네스 복사`를 활용해 진행하는 것을 권장합니다.

## 아주 간단한 순서

처음에는 아래 세 가지만 있으면 됩니다.

- FruitsFamily 셀러 링크
- 샵 이름
- 원하는 디자인 느낌

공개 배포는 나중에 해도 됩니다. GitHub, Cloudflare, 도메인은 사이트가 마음에 든 뒤 준비하면 됩니다.

1. 셀러 링크, 샵 이름, 소개 문장, 표시 옵션을 입력하고 저장합니다.
2. 디자인 레퍼런스 링크나 이미지를 넣고 저장합니다.
3. 미리보기를 확인합니다.
4. 세부 디자인은 Codex나 LLM에 [harness/LLM_PROMPT.md](harness/LLM_PROMPT.md)를 붙여넣고 요청합니다.
5. 완성되면 Mac 앱의 `배포` 메뉴를 보며 GitHub/Cloudflare 안내를 따라갑니다.
6. 배포 후에는 Mac 앱의 `작업 권장사항` 메뉴에서 커스텀 도메인과 유지보수 도구 아이디어를 확인합니다.

작업하는 동안 `START_HERE.command`가 연 터미널 창은 닫지 마세요.

사용자가 처음 읽어야 하는 문서는 이 `README.md` 하나면 충분합니다.

## 처음 쓰는 기기에서 필요한 것

설정과 미리보기에는 아래 하나만 필요합니다.

- Node.js 18 이상

공개 배포까지 하려면 아래도 필요합니다.

- GitHub 계정
- Cloudflare 계정
- Git 또는 GitHub Desktop
- 연결할 도메인

Git이 없어도 Mac 앱의 설정, 셀러 검증, 미리보기는 사용할 수 있습니다. 다만 완성된 폴더를 GitHub에 올리는 단계에서 Git 또는 GitHub Desktop이 필요합니다.

## 미리보기

더블클릭 실행이 안 되면 터미널에서 아래 명령을 실행하세요.

```sh
npm run dev
```

브라우저에서 아래 주소를 엽니다.

```text
http://localhost:8788
```

데이터 연결 점검:

```sh
npm run check
```

## 수정할 때 알아야 할 것

- 샵 이름, 셀러 링크, 기본 문구는 `site.config.json`과 `functions/_config.js`에서 관리합니다.
- Mac 앱은 위 두 파일을 자동으로 함께 수정합니다.
- 디자인 레퍼런스 이미지는 `content/design-reference.*`에 저장됩니다.
- 로고 원본은 `content/logo-source.*`, 웹 심볼은 `public/assets/logo-symbol.png`, 브라우저 아이콘은 `public/favicon.png`에 저장됩니다.
- 화면과 디자인은 `public/` 폴더에서 관리합니다.
- FruitsFamily 데이터 연결은 `functions/` 폴더에서 처리합니다.
- Codex나 Claude에 연결하는 방법은 [harness/LLM_CONNECTION.md](harness/LLM_CONNECTION.md)에 있습니다.
- LLM용 상세 구조와 운영 기준은 [harness/REFERENCE.md](harness/REFERENCE.md)에 있습니다.

## 현재 설정된 샘플

현재 샘플 셀러는 hooman입니다.

```text
https://fruitsfamily.com/seller/93s/synthetichooman
seller id: 11800
```

새 셀러로 바꿀 때는 짧은 링크 일부를 seller id로 추측하면 안 됩니다. LLM에게 먼저 FruitsFamily 셀러 정보를 검증하게 하세요.

## 배포 방식

이 프로젝트는 Cloudflare Pages Functions를 사용합니다. GitHub Pages 단독 배포용이 아닙니다.

Mac 앱을 통해 작업하는 경우, `v0.1m` 전체를 GitHub에 올리는 것이 아니라 앱에서 내보낸 최종 프로젝트 폴더의 파일을 GitHub 저장소 루트로 올립니다.

GitHub 저장소 루트에는 아래 파일과 폴더가 바로 보여야 합니다.

```text
README.md
site.config.json
public/
functions/
scripts/
harness/
package.json
```

커스텀 도메인은 Mac 앱에서 직접 연결되는 것이 아니라, Cloudflare Pages 배포 후 `Custom domains`에서 따로 연결해야 합니다. Mac 앱의 도메인 입력은 sitemap과 사이트 설정에 사용할 주소를 미리 적어두는 역할입니다.

Cloudflare Pages 권장 설정:

```text
Framework preset: None
Build command: 비워둠
Build output directory: public
Functions directory: functions
Production branch: main
```
