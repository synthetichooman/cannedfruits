# 에이전트 작업 지침

이 프로젝트는 한 명의 FruitsFamily 셀러를 위한 미러 스토어프론트입니다.

변경 전에는 아래 파일을 먼저 읽으세요.

1. `harness/LLM_PROMPT.md`
2. `harness/REFERENCE.md`
3. `README.md`

항상 지켜야 할 규칙:

- 구매 CTA는 FruitsFamily로 이동해야 합니다.
- 체크아웃, 결제, 장바구니, PG 기능을 추가하지 않습니다.
- 명시 요청이 없다면 팔로워 수, 평점, 리뷰 수, 좋아요 수를 보여주지 않습니다.
- 판매 완료 상품은 `Sold`로 표시합니다.
- `site.config.json`과 `functions/_config.js`는 함께 맞춰야 합니다.
- 코드나 설정 변경 후 `npm run check`를 실행합니다.
