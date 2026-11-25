# 모드 상세 규칙 + 맵 구조 분석

> 폭파/점령/터치다운/깃발 모드의 오브젝트·규칙과, 맵 구조(스폰·오브젝트)를 분석.
> **맵 지오메트리/스폰 좌표는 OBB에 없음 → 런타임 CDN AssetBundle로 유실 확정**(아래 D.3). 복원 대상은 **구조 계약**.

---

## A. 모드 파라미터 모델 (공통)

### A.1 `M_CONFIG_MODE` (모드별 설정)
`{ MODE(이름), MAPS[](허용 맵ID 풀), NEW_MAPS[], OUT_TIME(매치 제한시간), USE_PARTY, USE_HOST }`
→ 모드마다 "쓸 수 있는 맵 목록 + 제한시간 + 파티/호스트 사용 여부".

### A.2 `M_MODE_SETTINGS` (모드별 전투 타이밍)
`{ _RESPAWN_TIME, _DELAY_TIME_BEFORE_SHOW_SCOREBOARD, _SHOW_SCORE_TIME, _SHOW_BOOST_TIME, _AUTO_READY_DELAY_TIME, _AFTER_GAME }`
→ 리스폰 시간, 스코어보드 표시 지연/시간, 부스트 표시, 자동 준비 지연, 경기후 처리.

---

## B. 폭파 모드 (EXPLOSION / C4) ★

### B.1 오브젝트 (`C4 : MonoBehaviour`)
| 필드/메서드 | 의미 |
|---|---|
| `idx`, `sideType` | 폭탄 인덱스 / 설치 진영(공격팀) |
| `countTime`, `TICK_BOOM` | 카운트다운 / 폭발 틱(절대시각) |
| `IDLE` / `SETUP` (GameObject) | 미설치 / 설치됨 비주얼 상태 |
| `BOOM_SETUP_BGM` / `BOOM_TIMER` (Audio) | 설치 BGM / 타이머 사운드 |
| `ActionCamPos[]` (Transform) | 설치·해체 연출 카메라 위치 |
| `setTick(add_second)` | 타이머 가감 |
| `StartTimer()` / `explosion()` | 타이머 시작 / 폭발 실행 |
| `get_PlayRemain()` / `get_InstallBombTime()` | 남은 시간 / 설치 시각 |
| `getArea()` | 설치된 구역(A/B) |

### B.2 규칙 흐름
```
공격팀: 폭탄 소지 → 설치구역(Map.BombArea[])에서 설치(홀드) → IDLE→SETUP, StartTimer()
         타이머(countTime) 경과 → explosion() → 설치팀 승
수비팀: 설치된 C4에 접근 → 해체(홀드) → 타이머 중단(StopSetupBGM)
라운드 종료: 폭발 / 해체 / 시간초과(OUT_TIME) / 전멸
```
- 설치/해체는 홀드 상호작용. 설치 구역은 맵의 `BombArea[]`(보통 A/B 2곳).

---

## C. 깃발(CTF) / 점령 / 터치다운

### C.1 깃발 (FLAG) — `Flag : Singleton` + `FlagTarget`
| 클래스 | 역할 |
|---|---|
| `Flag` | **운반 가능한 깃발 오브젝트**: `CapsuleCollider`+`Rigidbody`(떨어뜨리면 물리), `arrow`(위치 표시), `player`(현재 소지자), `Remove()` |
| `FlagTarget` | **각 팀의 반납 지점**: `team: TYPE_TEAM`, `SetFlagModeCheck(Collider)`(깃발소지자 진입 감지), `set_FlagGall(team)`(득점) |
| `Obj_Flag` (프리팹) | 씬의 깃발 오브젝트 |

**흐름**: 중앙/적진 깃발 획득 → 자기 `FlagTarget`로 운반 → 진입 감지 시 득점. 소지자 사망 시 깃발 드롭(Rigidbody).

### C.2 점령 (OCCUPY) — 태그드 존 + FSM
- 전용 C# 클래스 없음. **`OCCUPYTARGET`** 이름의 트리거 존 + PlayMaker FSM.
- 상태 문자열: `OccupyProcessing`(점령 진행중) → `CompleteOccupy`(완료) / `LostOccupy`(뺏김), `OccupySucceeVoice`, `Icon_occupy_place`.
- **흐름**: 점령 존에 머무르면 진행 게이지↑ → 완료 시 점수/승리, 적이 들어오면 경합/상실.

### C.3 터치다운 (TOUCHDOWN) — 데이터 희박
- 전용 클래스/문자열 없음 → **운반 오브젝트를 적 엔드존으로 운반**하는 FLAG 변형(미식축구식)으로, `Flag`+`FlagTarget` 유사 구조를 FSM으로 재사용한 것으로 추정. (원작 상세 로직은 FSM·맵에 내장되어 코드 역산만으로는 불완전.)

---

## D. 맵 구조

### D.1 맵 중심 클래스 (`Map : Singleton`)
런타임에 맵의 게임플레이 오브젝트를 수집·관리:
| 필드 | 의미 |
|---|---|
| `respawn: Transform` | 기본 리스폰 지점 |
| `BombArea: Transform[]` | 폭파 설치 구역 (A/B) |
| `array_ItemSpawn: ItemSpawn[]` | 아이템 스폰 지점 |
| `array_JumpPad: JumpPad[]` | 점프대 |
| `array_breakobj: BreakObj[]` | 파괴 가능 오브젝트 |
| `m_arrBiochemicalWaste: BiochemicalWaste[]` | 좀비2 거점 |
| `doors: Doors`, `boxes: SafeBox[]` | 문 / 상자 |
| `jump: Jump_Setting` | 맵별 점프 물리 |
| lightmap/probe/skybox | 조명(런타임 렌더) |

### D.2 맵 오브젝트 카탈로그
| 클래스 | 역할 |
|---|---|
| `JumpPad` {m_vecDir, Jump_Setting} | 점프대(방향+세기) |
| `Jump_Setting` {jump_height_max, jump_speed_up, jump_speed_down, jump_speed} | **점프 물리 상수**(맵/패드별) |
| `Item` {m_nPosId, m_eItemID} + `ItemSpawn` {m_nId} | 필드 아이템 + 스폰포인트 |
| `BreakObj` | 파괴물(엄폐/장애) |
| `SafeBox` + `SafeboxChecker` | 상자(루팅/오브젝트) |
| `Doors` | 열리는 문 |
| `DeadZone` | 추락/이탈 즉사 구역 |
| `BiochemicalWaste` | 좀비2 생화학 거점 |

### D.3 맵 지오메트리/스폰 좌표 — **유실 확정**
UnityPy로 OBB 전체 파싱 결과:
- **Mesh 46개 전부 무기/아이템 소품**(rpg7, rocket, c4, flag, snowball, crossbow_arrow, giftbox…), **배틀맵 지형 메시 없음**(정점수 0 = 스트리밍).
- GameObject 10,357개 대부분 **UI 프리팹**(txt_/img_/btn_/card). 스폰류는 generic 이름(`POS`/`START`/`Point`/`WAVE`/`RED`/`BLUE`/`Obj_Flag`)만 소수.
- 45개 씬 슬롯(level1~45)에 `RenderSettings`/`LightmapSettings`만 있고 **지형은 미포함**.
- → **배틀맵(지형+스폰 레이아웃)은 런타임 CDN AssetBundle로 다운로드**되던 콘텐츠. 서버 사망으로 **좌표·지오메트리 복원 불가**(설정·CSV·무기수치와 동일 운명).

### D.4 복원된 것 (맵 설계 계약)
- 맵 1개가 제공해야 할 **마커 세트**: `respawn`(+팀별 RED/BLUE 스폰), `BombArea[2]`, `OCCUPYTARGET`, `FlagTarget×2`, `ItemSpawn[]`, `JumpPad[]`, `BreakObj[]`, `DeadZone`.
- 맵 로스터 규모: **~44개**(level1~45 슬롯).
- 소품 메시(무기/아이템/이펙트)는 OBB에 존재 → 필요 시 3D 모델로 추출 가능(`UnityPy`).

---

## E. 새 게임 적용

### E.1 모드별 맵 마커 요구사항 (맵 에디터 설계 기준)
| 모드 | 필요 마커 |
|---|---|
| 팀전/개인전 | 팀 스폰(RED/BLUE) 다수, DeadZone |
| 폭파 | 공격/수비 스폰 + `BombArea` A/B |
| 점령 | 스폰 + `OCCUPYTARGET` 존(1~3) |
| 깃발/터치다운 | 팀 스폰 + 중앙 깃발 + 팀별 `FlagTarget` |
| PvE 웨이브 | 플레이어 스폰 + 몬스터 스폰포인트(A/B/C/D) + (선택)아이템/점프대 |

### E.2 권장
- 맵은 **신규 제작**(원작 지오메트리 유실·저작권). 위 "마커 계약"만 지키면 모든 모드가 동일 맵 포맷에서 동작.
- 점프대/점프물리는 `Jump_Setting` 4필드로 맵별 조정.
- MVP(PvE 웨이브)는 **플레이어 스폰 1 + 몬스터 스폰 4 + DeadZone**만 있으면 성립.

---

## 부록: 분해 대상 (`dump.cs`)
| 시스템 | 클래스(라인) |
|---|---|
| 폭파 | `C4`(137439) |
| 깃발 | `Flag`(137486), `FlagTarget`(119091), `M_FLAG_INFO`(124044) |
| 맵 | `Map`(검색), `JumpPad`/`Jump_Setting`/`Item`/`ItemSpawn`/`BreakObj`/`SafeBox`/`Doors`/`DeadZone`/`BiochemicalWaste` |
| 모드 설정 | `M_CONFIG_MODE`(123554), `M_MODE_SETTINGS`(124578) |
| 점령 | 문자열 `OCCUPYTARGET`/`OccupyProcessing`/`CompleteOccupy`/`LostOccupy` |
