# MyFin 기존 구현 지도와 StockPilot 차용 기준

**이 파일의 용도**는 StockPilot의 기능을 설계할 때 “MyFin에서 어떤 문제를 이미 다뤘고, 어느 파일과 테스트부터 읽을까?”에 답하는 것이다. 조사 기준은 [MyFin main의 고정 커밋](https://github.com/vaynel/myfin/commit/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7)이다. 아래 판단은 소스와 테스트 정의를 읽은 결과다. 현재 운영 서버의 설정, 테스트 통과 여부, 체결 지연 및 전략 수익률은 이번 조사에서 측정하지 않았다.

## 주문 지연과 웹훅 확인

주문 경로는 후속 체크아웃 `eaec47b`에서 다시 확인했다. v2.1 룰 정의서의 ‘주문 실행 or 웹훅 발송’은 룰 평가 뒤에 가능한 두 동작이다. 알림 워커와 notifier는 Discord·Slack URL로 메시지를 보낸다. 이 체크아웃의 앱 라우터와 주문 호출 경로에서는 외부 HTTP 웹훅을 받아 실주문을 시작하는 핸들러를 찾지 못했다. [당시 룰 정의서](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/docs/v2.1/13_룰_정의서.md#L307-L323) · [알림 워커](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/backend/app/worker/tasks/notification.py#L150-L156) · [웹훅 발송](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/backend/app/services/notifier.py#L38-L49)

실시간 단타 경로는 증권사 WebSocket의 시세 틱을 받아 조건을 평가한다. LIVE 모드에서 적용 대상 매수 신호가 계좌·예산·중복 검사를 통과하면 주문 처리 함수를 직접 호출한다. 이 경로의 청산 룰은 등록 후 장중 1분 주기 감시 작업이 평가한다. 1분은 설정된 평가 간격이며, 실제 신호→전송·전송→접수 지연은 측정하지 않았다. [틱 수신과 신호 전달](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/backend/app/services/realtime/consumer.py#L142-L179) · [진입과 청산 분기](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/backend/app/services/auto_trading/intraday_scalp.py#L1370-L1412) · [감시 주기](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/backend/app/worker/celery_app.py#L252-L262)

MyFin 감시 작업에는 지정가 전송 중 예외가 나면 시장가로 재시도하는 분기도 있다. StockPilot은 최초 전송의 접수 여부가 불명확할 때 같은 의도를 보류하고 증권사 내역과 대조한다. [MyFin 전송 예외 분기](https://github.com/vaynel/myfin/blob/eaec47bcdaee916d2cdcb211b3b88ade5bc6acd5/backend/app/worker/tasks/rule_watcher.py#L610-L626) · [StockPilot 주문 대조](<인터페이스 정의서.md#if-042>)

## 1. 어디부터 읽을까

| 질문 | 진입점 | 여기서 확인할 것 |
| --- | --- | --- |
| 무엇이 실행되는가? | [start.sh](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/start.sh) · [FastAPI 진입점](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/main.py) · [Celery 설정](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/worker/celery_app.py) | 로컬 시작 스크립트가 API, 웹, 워커, 정기 작업을 어떻게 띄우는지 읽는다. 작업 큐에서 시장 데이터·거래·검증 작업의 실행 경계를 확인한다. |
| 설계와 실제 동작이 달랐던 사례는? | [v2.6 문서 색인](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/docs/v2.6/README.md) · [기존 TODO](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/docs/v2.6/01_TODO.md) | 주문 상태 보존, 분봉 동기화, AI 리포트 복구처럼 변경 이유가 남은 문서부터 읽는다. 루트 VERSION은 2.2.0이고 작업 문서 디렉터리는 v2.6이므로 분석 기준은 위 커밋으로 고정한다. |
| 투자자가 보던 화면은? | [기존 웹 라우트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/frontend/src/App.tsx) · [V2 웹 라우트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/frontend_v2/src/App.tsx) | 두 화면 트리가 공존하고 start.sh는 frontend를 시작한다. 자동매매·리포트·투자 일지의 탐색과 상태를 비교할 수 있다. 실제 배포 중인 웹 버전은 별도 확인 대상이다. |

## 2. 데이터에서 주문·복기까지

1. **데이터와 시장 분석.** 시장 데이터 보강 서비스는 일봉·분봉 수집 작업과 증권사별 데이터 경로를 다룬다. 수급 분석은 한투·키움 어댑터에서 투자자별 수급을 읽어 점수와 설명을 만든다. 시장 국면 모듈은 지수 추종 ETF의 가격 이력으로 추세를 계산하므로 결과를 사용할 때 대용 지표 이름과 관측 시각이 필요하다. [데이터 보강](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/market_data_backfill.py) · [수급 분석](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/analysis/flow_analyzer.py) · [시장 국면](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/market_regime.py)
2. **회차와 전략.** Celery Beat가 회차 작업을 시작하면 스케줄러가 한국 거래일과 활성 계좌를 확인한다. 계좌별로 플래너 또는 개장 후 재조정·마감 전 위험 평가를 호출한다. 플래너는 후보 선정 결과로 룰을 등록하고 재생에 쓸 입력을 남긴다. 기존 회차는 OPEN, OPEN_ADJUST, MIDDAY, PRECLOSE 네 종류다. [회차 분기](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/worker/tasks/scheduler.py) · [세션 플래너](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/planner.py)
3. **실행과 계좌 원장.** 룰 감시 워커가 조건·주문 가드를 평가하고 증권사 주문을 요청한다. 별도로 실시간 단타 신호에서 진입하는 경로도 있다. 체결 대사 서비스는 증권사가 돌려준 주문·누적 체결을 내부 주문과 맞추고 실현 거래를 연결한다. 회차를 세 번으로 바꾸더라도 실주문을 생성할 수 있는 모든 진입점을 확인해야 한다. [룰 감시·주문](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/worker/tasks/rule_watcher.py) · [실시간 진입 경로](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/realtime/order_handler.py) · [체결 대사](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/execution_reconciliation.py)
4. **검증과 사용자 기록.** Quant V2에는 고정한 입력으로 확인된 계획을 재생하고 결과를 대조하는 경로가 있다. 리포트는 자료 수집과 모델 호출을 조율하며 투자 일지는 거래를 스냅샷으로 연결한다. 웹의 /journal은 투자자 일지이고 /dev-journal은 개발 기록이다. [고정 입력 재생](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/quant_v2/frozen_replay.py) · [리포트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/report/orchestrator.py) · [투자 일지](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/journal.py)

## 3. 무엇을 차용할까

| StockPilot 영역 | 차용 제안 | 가져오기 전에 확인할 사례 |
| --- | --- | --- |
| 키움·한투 연동 | **응답 해석과 테스트 사례 우선.** 주문번호·잔고·주문 가능 금액·체결 필드의 대응을 참고하고, 새 주문 원장의 인터페이스에 맞춰 어댑터를 작성한다. [키움](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/broker_kiwoom.py) · [한투](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/broker_kis.py) | 같은 10주 주문의 접수·부분 체결·취소 응답을 두 증권사에서 같은 의미로 표현할 수 있는가? |
| 체결과 알림 | **누적 수량 대사와 외부 주문 구분을 차용.** 기존 대사 코드는 누적 체결량 증가를 감지하고 Discord·Slack 전송 코드를 갖췄다. StockPilot은 전송·접수·개별 체결 시점과 알림 전달 상태를 명시적으로 기록한다. [대사 테스트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_execution_reconciliation.py) · [알림 전송](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/notifier.py) | 조회 사이에 2주와 4주가 따로 체결돼 누적 6주로만 보인 상황에서 실제 체결 건을 복원할 수 있는가? 재접속·중복 통지·알림 재시도도 확인한다. |
| 한국 시장 분석과 개인 리스크 | **입력·산식·결측 처리를 발췌.** 수급의 금액 단위와 지수 대용 ETF를 명시하고, 위험 평가의 변동성·상관·업종 집중도를 개인 기준과 연결한다. [포트폴리오 위험 계산](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/analysis/portfolio_risk.py) · [시장 국면 테스트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_market_regime.py) | 오전 판단에 오후 데이터가 섞였는가? 특정 국면의 임계값과 업종 쏠림 기준이 다른 기간에도 유효한지는 투자자가 검증한다. |
| 개인 전략 연구 | **고정 입력과 재생 테스트를 먼저 차용.** 당시 후보·분봉·전략 버전·보유 상태를 재현하는 방식을 활용한다. [재생 테스트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_quant_v2_frozen_replay.py) · [분봉 실행 재생](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/quant_v2/session.py) | 같은 입력이면 같은 신호가 나오는가? 재현 가능성과 비용 차감 후 투자 성과는 각각 검증한다. |
| 세 회차와 AI의 권한 | **StockPilot 기준으로 재설계.** 거래일 확인과 계좌별 실행 격리는 참고한다. 사용자 배정 전략의 버전을 회차에 묶고 AI는 해당 신호·시장·리스크를 해석한다. MyFin의 LLM 파라미터 제안기는 별도 연구 사례다. [기존 LLM 제안기](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/proposer.py) · [거래일 처리](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/core/market_calendar.py) | 오후에는 오후에 배정된 전략을 실행하는가? 오전 미체결분은 계속 추적하면서 새 주문의 출처는 구분할 수 있는가? |
| 웹·리포트·투자 학습 | **사용 사례와 화면 상태를 차용.** 두 웹의 계좌·일지·전략 탐색을 비교하고 StockPilot의 새 디자인으로 구현한다. 회차 기록과 체결 사실을 본인 메모에 연결한다. [V2 자동매매 화면](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/frontend_v2/src/pages/AutoTradingPage.tsx) · [V2 투자 일지](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/frontend_v2/src/pages/JournalPage.tsx) · [일지 스냅샷 테스트](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_journal_snapshot.py) | 모바일에서도 매수 요청·접수·부분 체결·잔량을 구별하고, 해당 거래를 열어 당시 생각과 사후 복기를 따로 기록할 수 있는가? |

## 4. 첫 차용 검증 사례

기존 대사 테스트를 참고해 **오전 10주 매수 → 4주 체결 → 오후 전략에서 매도 신호 → 잔량 취소 확인 전 1주 추가 체결**을 두 증권사 응답 예시로 각각 재생한다. 오후 전략의 매도 신호가 발생한 순간과 매도 주문을 실제로 전송한 순간을 구분하고, 두 번째 체결 후 매도 체결 전 보유량이 5주인지 확인한다. 알림·계좌 원장·개인 일지에서 같은 거래를 추적할 수 있으면, 두 제품 사이에서 보존할 행위가 정의된다.

후속 설계에서 채택한 항목은 StockPilot의 기능 문서에 **MyFin 기준 파일·커밋, 가져올 동작, 바꿀 동작, 검증 결과와 투자자 결정**을 함께 남긴다. 조사 당시의 후보 중 개인 주문 추적과 12개 기능을 채택했다. 현재 제품 범위는 [기능 정의서](<기능 정의서.md>)에서 확인한다.

## 5. 현재 StockPilot 설계와의 차이

2026-11-26에 MyFin 원격 main이 기존 조사 기준과 같은 `db6fdd3`임을 확인했다. 해당 커밋의 웹 라우트, 서버에 등록된 API, 서비스 코드와 테스트 정의를 현재 서버의 [StockPilot 기능 정의서](<기능 정의서.md>), [인터페이스 정의서](<인터페이스 정의서.md>), [전략·운용 규칙서](<전략·운용 규칙서.md>), [업무 흐름·상태 전이서](<업무 흐름·상태 전이서.md>)와 비교했다. 표의 현재 상태는 최초 대조 당시의 기록이며 우선순위는 다음 테이블 정의에 미치는 영향을 기준으로 제안한다. 실계좌 호출, 서비스 기동, 테스트 실행은 이번 비교 범위에 포함하지 않았다.

### 테이블을 정하기 전에 논의할 항목

| 항목 | MyFin의 동작과 코드 | StockPilot의 현재 상태 | 설계에 반영할 경우의 확인 사례 |
|---|---|---|---|
| 주문 출처와 매매 방식별 실현손익 | 외부 MTS·HTS 주문까지 가져와 진입·청산 출처를 자동·외부·혼합·미확인으로 분류한다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/execution_reconciliation.py#L233) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_execution_reconciliation.py#L41) | 원장과 잔고 대조는 있으나 앱 밖에서 발생해 내부 판단·주문 식별자가 없는 거래의 수신 계약이 없다. | 계좌 전체 손익과 매매 방식별 실현손익을 각각 조회한다. 직접 매수하고 자동 매도한 거래는 ‘혼합’에 포함한다. 체결 출처·내부 주문 연결 여부를 인터페이스와 원장에 남긴다. |
| 후보 종목 선정과 제외 사유 | 전략 적합도 등을 바탕으로 후보에 순위를 매기고 선정 여부·사유를 저장한다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/selection.py#L168) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/candidate_snapshot.py#L21) | 종목을 분석하는 기능은 있으나 회차가 어떤 종목 집합을 어디에서 받아 누구를 제외하는지 빠져 있다. | 오전 회차의 검색 대상·선정 종목·제외 사유를 재조회한다. 보유 종목의 매도 검토와 신규 매수 후보를 구분한다. |
| 중복 매수 의도와 자동 중지 | 같은 규칙의 미결 주문·최근 같은 방향 주문을 검사하고 계좌 손실·연속 주문 실패를 평가한다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/order_guards.py#L17) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/account_gates.py#L215) | 동일 체결 중복 수신, 수동 OFF, 한도 검증은 있다. 서로 다른 주문번호로 같은 신호를 두 번 주문하는 경우와 자동 중지 후 재개가 비어 있다. | 재실행된 회차에서 같은 판단의 신규 주문은 한 건이어야 한다. 계좌별 중지 사유와 재개 주체를 정하고 기존 체결 추적을 유지한다. |
| 거래일과 회차 실행 이력 | 한국 거래일을 확인한 뒤 활성 자동매매 설정을 읽어 회차 작업을 분기한다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/worker/tasks/scheduler.py#L338) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_kr_market_calendar.py#L90) | 오전·오후·장 마감 전 세 회차는 정의했다. 휴장·미실행·판단 보류를 구분하는 결과와 재시작 시 같은 회차를 식별하는 계약은 부족하다. | 휴장일에는 주문 없이 건너뛴 이유를 확인한다. 한 계좌의 연결 실패와 다른 계좌의 실행 결과를 구별한다. |

### 실계좌 연동·전략 검증 전에 보완할 항목

| 항목 | MyFin의 동작과 코드 | StockPilot의 현재 상태 | 설계에 반영할 경우의 확인 사례 |
|---|---|---|---|
| 계좌 동기화와 종목별 거래 이력 | 계좌별 잔고 동기화, 체결 동기화, 보유 종목의 기간별 이력 조회가 각각 있다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/accounts.py#L481) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/accounts.py#L266) | 인터페이스에 계좌 목록·상세·잔고 기준 시각은 이미 있다. 사용자가 재동기화를 요청하고 특정 종목의 잔고 변화를 거래까지 추적하는 동작이 부족하다. | 동기화 전후 기준 시각과 차이를 보여주고 해당 계좌·종목의 거래와 연결한다. |
| 누락 시세 재수집 | 종목군별 일봉·분봉 수집 작업의 상태 조회 및 실패 항목 재시도 경로가 있다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/backfill.py#L562) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_market_data_backfill.py#L168) | 과거 시점 조회에서 누락 구간을 표시하지만 누가 어떤 범위를 복구하고 결과를 확인할지 빠져 있다. | 일부 종목의 분봉만 누락된 날에 실패 범위를 재수집하고, 당시 회차에 실제 사용한 자료 버전은 추적한다. |
| AI 공급자·모델 설정과 실행 실패 | 공급자·모델·사용자 키 설정, 모델 사용 비용 조회 경로가 있다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/settings.py#L63) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/dashboard.py#L616) | 증권사 키와 AI 수량 기준은 있으나 모델을 어디서 선택하는지, AI 호출 실패 시 수량과 주문 상태를 어떻게 남기는지 명시되지 않았다. | 판단에 사용한 모델과 성공·실패를 회차에 남긴다. 수량 응답이 없는 건은 이전 회차 수량을 재사용하지 않는 사례로 검증한다. 사용자 키 지원 여부는 별도 선택이다. |
| 실행 입력 보존과 모의 비교 | 확정 계획·분봉·계좌·거래일을 고정해 당시 계획을 재생하고 비교한다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/quant_v2/frozen_replay.py#L109) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_quant_v2_frozen_replay.py#L1) | 백테스트·전략 버전은 있으나 실운용 당시 후보와 판단 입력을 다시 읽어 실제 판단과 대조하는 기능은 부분적이다. | 과거 오전의 입력으로 전략 신호를 재계산하고 실제 AI 응답은 원본으로 보존한다. 같은 입력에서 새 모델의 수량이 달랐는지도 별도 실험으로 기록할 수 있다. |
| 체결 품질과 전략 재검토 | 진입 시 예상한 가격과 실제 체결가 차이, 표본 수, 실현 성과로 기존 가정을 재평가한다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/services/auto_trading/feedback_slippage.py#L36) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/tests/test_feedback_slippage.py#L19) | 주간 목표와 손익 비교는 있지만 신호 당시 가격 대비 실제 체결 차이를 전략 버전별로 분석하는 항목이 없다. | 주간 목표 미달 시 전략 판단과 체결 비용의 영향을 따로 확인하고, 표본이 부족하면 판정을 보류한다. |

### 화면·운영 설계에서 보완할 항목

| 항목 | MyFin의 동작과 코드 | StockPilot의 현재 상태 | 설계에 반영할 경우의 확인 사례 |
|---|---|---|---|
| 알림 설정과 발송 이력 조회 | 채널·이벤트별 알림 설정 변경과 발송 이력 조회가 있다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/notifications.py#L75) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/notifications.py#L107) | StockPilot은 알림 종류·재시도·이벤트별 전달 결과를 이미 명시했다. 채널을 연결하고 사용자 화면에서 실패 건을 조회하는 계약이 부족하다. | 체결 알림을 어느 채널에 보냈는지 주문 상세에서 확인하고 실패한 알림만 다시 보낸다. |
| 비동기 보고서와 분석 작업 상태 | 보고서 생성 요청으로 식별자를 발급하고 별도 API에서 진행 상태를 조회한다. 백테스트에도 실행별 조회와 실패 재시도가 있다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/reports.py#L308) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/auto_trading.py#L1432) | 기존 인터페이스는 결과 조회 위주다. 요청이 오래 걸리거나 중단될 때 화면이 어떤 실행을 다시 조회할지 정의하지 않았다. | 요청 뒤 화면을 닫았다 다시 열어도 같은 실행 결과를 찾고, 실패를 수익률 0이나 빈 리포트와 구분한다. |
| 운영 상태와 설정 변경 기록 | 거래·규칙·오류 로그 조회, 실행 경로 설정과 관리자 변경 이력 조회가 있다. [코드](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/runtime_admin.py#L112) · [관련 근거](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/api/routers/logs.py#L542) | 설정 버전과 장애 복구서 TODO는 있다. 어느 변경이 해당 회차에 적용됐고 운영자가 어떤 오류를 확인했는지 조회하는 계약은 부족하다. | 계좌 OFF 직전 결정과 실제 전송 시각을 대조하고, 누가 언제 설정을 바꿨는지를 확인한다. |

### 이미 반영된 동작과 제품 범위

계좌별 자동매매 ON/OFF와 정액·비율 한도, AI가 사용자 기준 안에서 실제 수량을 정하고 전송 직전에 재검증하는 절차, 부분 체결·취소 경합, 중복 체결 처리와 알림 재시도는 StockPilot 문서에 있다. MyFin의 네 회차 구성을 가져올 필요 없이 거래일 확인과 실행 이력만 현재의 세 회차에 적용할 수 있다. MyFin의 관심종목 관리는 StockPilot 제품 범위에 포함됐다. 종목 리서치 전용 화면과 실시간 단타 레이더의 채택 여부는 미정이다. [MyFin 화면 경로](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/frontend_v2/src/App.tsx#L1) · [MyFin 서버 라우터 등록](https://github.com/vaynel/myfin/blob/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7/backend/app/main.py#L1)

[테이블 정의서](<테이블 정의서.md>)를 검토할 때는 계좌별 주문 출처와 매매 방식별 실현손익, 회차별 후보 종목과 제외 사유, 계좌·회차 실행 이력과 주문 의도의 식별 관계부터 검토한다. 이미 합의한 인터페이스에 새 필드가 필요하면 채택 시 해당 문서에도 반영한다. 한도값·시간 간격·손익 계산식은 개발 단계에서 정한다.
