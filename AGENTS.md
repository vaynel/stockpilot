# StockPilot 문서 작성 규칙

이 저장소에서 문서를 새로 쓰거나 수정·검토할 때는 매번 `technical-writing`을 적용한다. 작업 전에 설치된 스킬의 `SKILL.md`를 읽고, 문장을 마무리할 때는 스킬이 지정한 `unslop`으로 표현을 검토한다. 로컬 스킬을 찾을 수 있으면 해당 설치본을 사용하고, 다른 환경에서는 아래의 고정된 원문을 읽는다. [technical-writing](https://github.com/cursor/plugins/blob/eb4db2b55b2b7dec3d9282754cddf0a56bf4ff10/pstack/skills/technical-writing/SKILL.md) · [unslop](https://github.com/cursor/plugins/blob/eb4db2b55b2b7dec3d9282754cddf0a56bf4ff10/pstack/skills/unslop/SKILL.md)

기능·인터페이스·테이블 정의서는 개발자가 항목을 찾아볼 수 있게 구성한다. 용어는 [용어 정의서](<용어 정의서.md>)의 표기를 따르고, 확정한 동작과 아직 결정할 사항을 구분한다. 문서별 전문 스킬은 [설계 TODO](<설계 TODO.md>)의 기준과 함께 적용한다.

## 새 환경에서 설계 스킬 복원

StockPilot 저장소 루트에서 아래 명령을 실행한다. Python 3, GitHub 접속, Codex 기본 스킬인 `skill-installer`가 필요하다. 설치기는 각 스킬의 지침과 함께 예제·참조 파일·스크립트도 복원한다.

```bash
bash scripts/install-design-skills.sh
```

기본 설치 위치는 `$CODEX_HOME/skills`이며, `CODEX_HOME`을 설정하지 않았으면 `~/.codex/skills`를 쓴다. 같은 이름의 스킬이 이미 있으면 기존 설치본을 사용한다. 버전을 비교하려면 스크립트의 첫 번째 인수로 빈 디렉터리를 지정해 고정 버전을 따로 설치한다. 설치 후 새 Codex 세션에서 아래 스킬 이름을 사용할 수 있다. GitHub 저장소, 커밋, 스킬 경로는 [복원 스크립트](scripts/install-design-skills.sh)에 있다.

## 작업별 스킬과 산출물

| 이어갈 작업 | 사용할 스킬 | 프로젝트에 적용한 방식 |
| --- | --- | --- |
| 설계 문서 작성·수정 | `technical-writing`, `unslop` | 기존 용어와 ID를 유지해 초안을 쓰고, 마지막에 모호한 문장과 중복 표현을 다듬는다. |
| 전체 아키텍처 | `architect`, `how`, `arena` | `how`로 기존 주문·원장 흐름을 추적하고, `arena`로 회차 중심안과 주문·원장 중심안을 비교했다. 선택한 구조와 책임은 [전체 아키텍처](<01. 전체 아키텍처.md>)에서 이어간다. |
| 기능과 인수 기준 | `wicked-garden-product-acceptance-criteria` | 문서에서 줄여 쓴 `acceptance-criteria`의 설치 이름이다. 기능 ID마다 시작 조건·동작·기대 결과를 쓰고, 중복 체결 같은 예외를 인수 사례와 연결한다. |
| API 계약 | `api-design-principles` | [인터페이스 정의서](<인터페이스 정의서.md>)에 전체 목록을 먼저 두고 IF별 송수신 주체, 호출 방식, 요청·응답 필드, 오류 예시를 기록한다. |
| 데이터 모델 | `postgresql-table-design` | [테이블 정의서](<테이블 정의서.md>)에서 주문과 개별 체결의 관계, 중복 방지 키, 계좌·기간별 조회 인덱스를 검토한다. |
| 장애 대응 | `incident-runbook-templates` | [운영·장애 복구서](<운영·장애 복구서.md>)에 접수 응답 유실 시 감지, 증권사 대조, 복구 확인 순서를 적는다. |
| 화면 구성과 시안 | `interface-design`, `wireframe` | `interface-design`으로 정보의 우선순위와 상태 표시를 검토한다. `wireframe`으로 768×1024 태블릿 SVG를 그리고 [화면 정의서](<화면 정의서.md>)의 메뉴 경로·API·기능표와 맞춘다. |
| 브라우저 검수·이미지 공유 | `playwright` | 문서 뷰어에서 화면 목차, IF 링크, SVG 표시를 확인한다. 그림을 보여줄 때는 해당 SVG를 태블릿 크기로 열어 PNG로 캡처한다. 실행 환경에는 Node.js의 `npx`와 Chromium이 필요하다. |

`pstack-`으로 시작하는 다섯 설치 폴더는 스킬 이름에서 접두사를 뺀다. 예를 들어 `pstack-technical-writing/SKILL.md`에 선언된 이름은 `technical-writing`이다. 프로젝트가 매매·복기에 사용할 AI 기능은 [AI 스킬 목록](<AI 스킬 목록.md>)에 정리돼 있다.
