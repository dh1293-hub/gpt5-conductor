# Kobong Project Declaration — v0.1.2

## 목적
- 한민수 & GPT-5 프로젝트 실행 표준 고정: 선택지 최소화, 재현성 보장.
- 한 채팅=한 단계, GPT-5 주도.

## 불변 규칙
- 작업 경로: D:/ChatGPT5_AI_Link/dosc/gpt5-conductor
- 출력 경로: out/gh/run_<RunID>/, out/summary/<timestamp>/
- 앱 로그: logs/app.log (JSON Lines)
- 스크립트 이름: PS-<BLOCK>-<STEP> (vN)  예: PS-KKB-3.3 (v4)
- 경고 색: 연주황(DarkYellow)

## CLI 호환 정책
- gh run view --watch 금지  gh run watch <runId> --interval 5 --exit-status
- 완료 후 gh run view <runId> --log
- 아티팩트: 사전 조회 후 있을 때만 다운로드 (gh api .../artifacts -q .total_count)

## 빨간 글씨 제로
- 예측 가능 오류는 사전 조건 검사로 차단.
- $Error 버퍼를 수집하여 사후 요약에 반영.

## Post-Run Collector(의무)
- 주요 스크립트 종료 시 PS-KKB-3.4 실행.
- 산출물: session-summary.md, errors.json, env.txt, gh_run_<ID>_log.txt(있으면), grep.csv(있으면), summary_<timestamp>.zip

## 릴리스/액션 표준 흐름
1) PS-KKB-3.x: 트리거  완료대기  로그확인 (있으면) 아티팩트
2) 릴리스/태그 상태 요약
3) PS-KKB-3.4 사후 수집

## 보안
- 토큰/PII 마스킹. .env.sample만 커밋, 실제 시크릿은 외부 보관.

## 추적/버전
- Conventional Commits + SemVer.
- 스크립트 변경 사유를 주석 한 줄로 남김 (예: gh 구버전 호환).

## DoR / DoD
- DoR: 목적성공지표I/O 예시예외/로그리스크롤백 정의.
- DoD: 빌드/정적분석/테스트/아티팩트/릴리스노트/모니터링 설정 + out/summary/.../session-summary.md 확인.

End of Declaration
