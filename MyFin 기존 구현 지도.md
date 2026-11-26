# MyFin 기존 구현 지도와 StockPilot 차용 기준

**이 파일의 용도**는 StockPilot의 기능을 설계할 때 “MyFin에서 어떤 문제를 이미 다뤘고, 어느 파일과 테스트부터 읽을까?”에 답하는 것이다. 조사 기준은 [MyFin main의 고정 커밋](https://github.com/vaynel/myfin/commit/db6fdd3549aa14fb30ec9cd113e7f19083e12aa7)이다. 아래 판단은 소스와 테스트 정의를 읽은 결과다. 현재 운영 서버의 설정, 테스트 통과 여부, 체결 지연 및 전략 수익률은 이번 조사에서 측정하지 않았다.

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

후속 설계에서 채택한 항목은 StockPilot의 기능 문서에 **MyFin 기준 파일·커밋, 가져올 동작, 바꿀 동작, 검증 결과와 투자자 결정**을 함께 남긴다. 현재 이 문서의 항목은 모두 차용 후보 단계다.
