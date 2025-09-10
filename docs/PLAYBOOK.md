# Error Playbook (Sprint-B seed)

> 단일 진실원천. 한 에러 = 한 ID = 재현 단계/원인/조치/가드레일 포함.

## ERR-TS-PORTS-001
- 징후: TS2307 '.../domain/reporting/ports' 모듈 없음, TS7006 implicit any
- 원인: ports.ts 미정의/이름 불일치
- 조치: ports.ts 작성(ReportRequest/ReportResult/ReportEnginePort), 엔진/서비스 타입 보강, `npx tsc -p tsconfig.build.json`
- 가드레일: Contract-first. 빌드 전 계약 존재 검사.

## ERR-TS-1343
- 징후: "import.meta 는 module=es2022|esnext|node16|nodenext 에서만 허용"
- 조치: tsconfig.build.json exclude에 해당 파일(예: app/hardening.ts) 추가

## ERR-TS-2307
- 징후: 상대경로 모듈 못찾음
- 조치: include에 app/**, domain/**, infra/**, ui/** 명시, dist 정리 후 재빌드

## ERR-NODE-MODULE-NOT-FOUND
- 징후: dist/ui/reporting/cli.js 없음
- 조치: `npx tsc -p tsconfig.build.json` → 정확 경로 실행

## ERR-INPUT-MISKEY
- 징후: 콘솔에 "name,amount" 등 출력값을 직접 타이핑해 파서 오류
- 조치: 출력값은 입력하지 않음(런북에 주의 문구)