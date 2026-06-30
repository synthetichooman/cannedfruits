# cannedfruits v0.1 LLM 참고서

이 문서는 사람이 처음 읽는 문서가 아닙니다. Codex나 LLM이 구조를 빠르게 이해하기 위한 참고서입니다.

## 목적

한 명의 FruitsFamily 셀러 상품을 독립 스토어프론트처럼 보여줍니다.

구매, 결제, 로그인, 고객 응대, 최종 재고 확인은 FruitsFamily에서 처리합니다.

cannedfruits는 FruitsFamily와 관련이 없는 비공식 독립 도구입니다. 사용 과정에서 발생하는 계정, 운영, 정책상 불이익은 사용자에게 귀속됩니다.

## 개발 방향

현재 우선순위는 LLM과 함께 수정 가능한 DIY 패키지를 완성하는 것입니다.

이 프로젝트는 완전 초보 사용자가 GitHub, Cloudflare, 도메인, DNS까지 모두 혼자 처리하는 것을 1차 목표로 삼지 않습니다. DIY 패키지를 안정화한 뒤, 같은 기반에서 아래 상품을 분리합니다.

```text
1. DIY 패키지: 사용자가 LLM과 함께 직접 수정
2. Guided Setup: 제작자가 초기 연결과 배포를 지원
3. Managed Launch: 제작자가 디자인, 배포, 도메인 연결까지 처리
```

DIY 패키지는 CannedFruits Mac 앱에서 설정하고, 내보낸 프로젝트 폴더는 배포 가능한 웹 코드 중심으로 유지합니다. 배포 후 운영 아이디어는 Mac 앱의 `작업 권장사항` 메뉴와 LLM 하네스로 안내합니다.

## 현재 샘플 셀러

```text
shop name: hooman
canonical seller URL: https://fruitsfamily.com/seller/93s/synthetichooman
numeric seller id: 11800
base36 seller id: 93s
username: synthetichooman
```

중요: FruitsFamily의 짧은 공유 링크 일부를 GraphQL seller id로 추측하면 안 됩니다. 셀러를 바꿀 때는 Mac 앱의 셀러 확인 기능이나 FruitsFamily GraphQL 응답으로 실제 numeric seller id를 확인하세요.

## 데이터 흐름

```text
browser
-> public/index.html 또는 public/product.html
-> /api/site, /api/products, /api/product
-> Cloudflare Pages Functions
-> FruitsFamily GraphQL
-> 정리된 JSON
-> 화면 렌더링
```

FruitsFamily GraphQL endpoint:

```text
https://web-server.production.fruitsfamily.com/graphql
```

GraphQL 관련 로직은 `functions/_fruits.js`에 모아둡니다.

## 주요 파일

자주 수정:

```text
site.config.json        사람이 읽기 쉬운 샵 설정
functions/_config.js    Cloudflare 런타임 설정
public/index.html       홈 화면 구조
public/app.js           홈 상품 렌더링
public/product.html     상세 화면 구조
public/product.js       상세 상품 렌더링
public/styles.css       디자인
```

로컬 미리보기:

```text
START_HERE.command
scripts/dev-server.mjs
```

`START_HERE.command`를 더블클릭하면 로컬 서버를 열고 공개 웹 미리보기를 자동으로 띄웁니다.

디자인 레퍼런스:

```text
site.config.json > design.referenceUrl
site.config.json > design.referenceImage
site.config.json > design.notes
content/design-reference.*
content/logo-source.*
public/assets/logo-symbol.png
public/favicon.png
```

디자인 레퍼런스 이미지는 공개 사이트 화면에 자동 노출되지 않습니다. LLM과 작업자가 디자인 방향을 참고하기 위한 입력입니다.

조심해서 수정:

```text
functions/_fruits.js
functions/api/site.js
functions/api/products.js
functions/api/product.js
functions/sitemap.xml.js
scripts/dev-server.mjs
scripts/smoke-test.mjs
```

## 유지해야 할 규칙

- CTA는 FruitsFamily 상품 페이지로 이동
- FruitsFamily와 관련 없는 비공식 독립 도구라는 고지를 유지
- 사용상 계정, 운영, 정책상 불이익은 사용자에게 귀속된다는 고지를 유지
- checkout, cart, PG, 자체 로그인 추가 금지
- 팔로워 수, 평점, 리뷰 수, 좋아요 수는 기본 숨김
- 판매 완료 상품은 `Sold`로 표시
- `Archive` 표현은 명시 요청 없이는 사용하지 않음
- 상세 페이지에서 category, size, condition, source는 기본 숨김
- 셀러 변경 시 `site.config.json`과 `functions/_config.js`를 함께 수정
- 변경 후 `npm run check` 실행

## 기본 디자인 규칙

- 홈 화면은 과한 랜딩 페이지가 아니라 바로 상품 목록을 보여줍니다.
- 데스크톱 상품 목록은 기본 4열 그리드입니다.
- 모바일에서는 2열 또는 1열로 자연스럽게 줄입니다.
- 상품 카드에는 이미지, 제목, 브랜드, 가격, Sold 상태만 간결하게 보여줍니다.
- 상세 페이지는 메인 이미지 1장, 썸네일, 우측 상품 정보와 CTA 구조를 유지합니다.
- 디자인 레퍼런스는 `site.config.json > design` 또는 `content/design-reference.*`를 봅니다.

## DIY v0.1 완료 기준

아래가 충족되면 DIY 패키지 v0.1을 닫을 수 있습니다.

```text
1. CannedFruits Mac 앱에서 설정과 로고 저장이 가능하다.
2. 셀러 링크 검증과 설정 저장이 가능하다.
3. 홈/상세 미리보기가 안정적으로 보인다.
4. LLM 연결 방법과 하네스가 충분히 자세하다.
5. npm run check가 통과한다.
6. 배포가 어려운 사용자를 Guided Setup 또는 Managed Launch로 자연스럽게 안내한다.
```

## 배포

Cloudflare Pages Functions를 사용하므로 GitHub Pages 단독 배포는 기본 방식이 아닙니다.

Mac 앱 소스인 `v0.1m` 전체를 GitHub에 올리지 않습니다. 공개 웹사이트 저장소에는 앱에서 내보낸 프로젝트 폴더의 파일을 저장소 루트로 올립니다.

GitHub 저장소 루트 예시:

```text
README.md
site.config.json
public/
functions/
scripts/
harness/
package.json
```

Cloudflare Pages 설정:

```text
Framework preset: None
Build command: 비워둠
Build output directory: public
Functions directory: functions
Production branch: main
```

선택 KV binding:

```text
CANNED_FRUITS_KV
```

커스텀 도메인은 설정 GUI에서 자동 연결되지 않습니다. Cloudflare Pages 배포 후 `Custom domains`에서 따로 연결합니다.

도메인은 사용자가 가비아, 카페24, Namecheap 같은 도메인 판매처에서 구매해야 합니다.

일반 흐름:

```text
도메인 구매
-> Cloudflare에 도메인 추가
-> 네임서버 또는 DNS 레코드 설정
-> Cloudflare Pages Custom domains 연결
-> 연결 확인
```

GitHub, Cloudflare, 도메인, DNS는 초보자에게 어렵기 때문에 DIY에서는 쉽게 안내만 하고, 실제 지원은 Guided Setup 또는 Managed Launch 범위로 분리합니다.

## 셀러에게 받을 질문

```text
1. FruitsFamily 셀러 링크
2. 샵 이름
3. 사이트에 사용할 도메인 후보
4. 디자인 레퍼런스 링크 또는 이미지
5. 원하는 분위기나 피하고 싶은 디자인
6. Sold 상품을 보여줄지 여부
7. 추가로 원하는 기능
```

## 유지보수 도구 계획

배포 이후에는 별도 웹 admin 페이지를 추가하기보다, LLM과 함께 작은 모니터링 도구를 붙이는 방향을 권장합니다.

목표:

```text
지금 내 사이트가 정상인가?
뭘 수정할 수 있나?
LLM에게 뭐라고 말하면 되나?
수정 후 다시 공개하려면 뭘 누르면 되나?
```

예상 범위:

- 사이트 상태 확인
- 상품 데이터 연결 점검
- 간단한 설정 수정
- LLM 유지보수 요청 템플릿 복사
- GitHub Desktop 중심 재배포 안내

하지 않을 것:

- GitHub 로그인 자동화
- Cloudflare 로그인 자동화
- 도메인 구매 자동화
- DNS 자동 변경
- 결제, 장바구니, 주문 관리
