# LLM에 이 프로젝트 연결하기

이 문서는 cannedfruits 폴더를 Codex나 Claude에 연결해서 수정 작업을 맡기는 방법입니다.

핵심은 간단합니다.

```text
1. LLM에게 이 프로젝트 폴더를 열게 합니다.
2. LLM에게 README.md와 harness/LLM_PROMPT.md를 먼저 읽게 합니다.
3. 원하는 수정 내용을 한국어로 말합니다.
4. LLM이 수정한 뒤 미리보기와 점검을 실행하게 합니다.
```

## 먼저 준비할 것

- 이 cannedfruits 프로젝트 폴더
- Node.js 18 이상
- Codex 또는 Claude Code
- 배포까지 할 경우 GitHub 계정, Cloudflare 계정, Git 또는 GitHub Desktop

## Codex에서 여는 법

Codex 앱이나 Codex CLI에서 이 프로젝트 폴더를 작업 폴더로 엽니다.

프로젝트 폴더:

```text
v0.1
```

Codex에게 처음 보낼 말:

```text
이 폴더는 cannedfruits v0.1 프로젝트입니다.
먼저 README.md, AGENTS.md, harness/LLM_PROMPT.md, harness/REFERENCE.md를 읽고 구조를 파악해줘.
모든 답변은 한국어로 해줘.
코드를 수정한 뒤에는 npm run check로 확인해줘.
```

Codex CLI를 쓴다면 터미널에서 프로젝트 폴더로 이동한 뒤 시작합니다.

```sh
cd /path/to/v0.1
codex
```

Codex가 읽어야 할 핵심 파일:

```text
README.md
AGENTS.md
harness/LLM_PROMPT.md
harness/REFERENCE.md
```

## Claude Code에서 여는 법

Claude Code에서도 방식은 거의 같습니다. 터미널에서 프로젝트 폴더로 이동한 뒤 Claude를 시작합니다.

```sh
cd /path/to/v0.1
claude
```

Claude에게 처음 보낼 말:

```text
이 폴더는 cannedfruits v0.1 프로젝트입니다.
먼저 README.md, AGENTS.md, harness/LLM_PROMPT.md, harness/REFERENCE.md를 읽고 구조를 파악해줘.
모든 답변은 한국어로 해줘.
코드를 수정한 뒤에는 npm run check로 확인해줘.
```

Claude Code는 프로젝트 루트의 `CLAUDE.md`를 자동 지침으로 활용할 수 있습니다. 이 패키지에는 아직 별도 `CLAUDE.md`가 없으므로, Claude가 필요하다고 하면 `AGENTS.md`와 `harness/LLM_PROMPT.md` 내용을 바탕으로 `CLAUDE.md`를 만들어달라고 요청하면 됩니다.

## Claude 웹 버전만 쓸 때

Claude 웹 채팅은 로컬 폴더를 직접 수정하지 못할 수 있습니다. 이 경우에는 아래 순서로 사용하세요.

1. `LLM 하네스 복사` 버튼을 누릅니다.
2. 모달의 내용을 복사합니다.
3. Claude 채팅에 붙여넣습니다.
4. 필요한 파일 내용을 추가로 붙여넣습니다.
5. Claude가 제안한 코드를 Codex나 편집기로 반영합니다.

로컬 파일을 직접 수정하려면 Claude 웹보다 Claude Code 또는 Codex가 더 적합합니다.

## LLM에게 요청하기 좋은 말

디자인 수정:

```text
기본 상품 목록 UI를 더 여백 있게 개선해줘. FruitsFamily 데이터 연결과 CTA 동작은 건드리지 마.
수정 후 npm run check를 실행해줘.
```

셀러 변경:

```text
새 FruitsFamily 셀러 링크로 site.config.json과 functions/_config.js를 업데이트해줘.
짧은 링크 일부를 seller id로 추측하지 말고, 실제 셀러 정보를 검증한 뒤 수정해줘.
```

배포 도움:

```text
이 cannedfruits 폴더를 GitHub에 올리고 Cloudflare Pages에 연결하는 과정을 한 단계씩 도와줘.
나는 개발 지식이 많지 않으니 아주 쉽게 설명해줘.
```

## LLM에게 꼭 지키라고 할 규칙

- 모든 답변은 한국어로 합니다.
- 결제, 장바구니, 로그인 기능은 만들지 않습니다.
- 구매 버튼은 FruitsFamily 상품 페이지로 이동해야 합니다.
- FruitsFamily와 무관한 비공식 독립 도구라는 고지를 유지합니다.
- 상세 페이지에서 category, size, condition, source는 기본 표시하지 않습니다.
- `archive` 표현은 쓰지 않고, 판매 완료 상품은 `Sold`로 표시합니다.
- 수정 후 `npm run check`를 실행합니다.

## 잘 연결됐는지 확인하는 법

LLM에게 아래 질문을 해보세요.

```text
이 프로젝트의 데이터 흐름과 가장 많이 수정하는 파일 5개를 한국어로 설명해줘.
```

좋은 답변에는 보통 아래 내용이 들어갑니다.

- `public/`은 화면 파일
- `functions/`는 FruitsFamily API 연결
- `site.config.json`은 샵 설정
- 설정과 내보내기는 CannedFruits Mac 앱에서 처리
- `harness/`는 LLM과 사용자 안내 문서
