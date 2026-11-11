# NOVA BMS

고객 화면의 문구·이미지·대체텍스트 관리. 고객은 http://localhost:18080 하나의 사이트를 이용합니다. 이 레포가 소유한 고객 경로는 `http://localhost:18085`입니다. JSP·JavaScript·처리 코드가 해당 업무 레포에 함께 있습니다. BMS는 별도 편집기입니다.

## 전체 사이트 실행

6개 레포를 형제 폴더로 clone한 뒤 `bank-home/demo`의 안내를 따릅니다.

```sh
python3 bank-home/demo/setup.py
docker compose up -d
```

고객 화면: http://localhost:18080 · BMS: http://localhost:18085

각 레포의 compose는 전체 사이트가 사용하는 `nova-retail` 네트워크에서 해당 업무 서버만 실행합니다. 고객용 단일 진입점은 루트 compose가 제공합니다. 루트 전체 실행과 개별 compose를 동시에 사용하지 않습니다.

## 동작 범위

가상 고객 김민준(C001)의 개인뱅킹 체험입니다. 실제 인증·송금·상품 계약·잔액 변경을 수행하지 않습니다. 체험 이체·상품 가입은 기록을 저장하며 같은 요청번호 재전송 시 중복 생성하지 않습니다. 알림 설정은 이체 알림 생성에 반영됩니다. `.runtime`은 실행 데이터이며 Git에 포함하지 않습니다.

공통 메뉴·CSS와 표시 스크립트는 home에서 제공하고, 업무별 화면과 처리는 각 레포가 소유합니다. BMS 관리 링크는 고객 메뉴에 노출하지 않습니다.

## 확인

```sh
python3 -m unittest discover -s bank-bms/tests -v
```

위 명령은 형제 폴더들을 포함한 루트에서 전체 사이트가 실행된 상태로 수행합니다. SR20·검색·통합 테스트·설계는 `bank-home/demo`에도 포함됩니다. Java21 / Tomcat9 / Gson2.13.2 / vanilla JavaScript.
