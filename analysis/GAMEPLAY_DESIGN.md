# 스페셜솔져 게임플레이 설계 분석 (새 게임 청사진)

> 목적: 원작 `com.wellgames.ss`(Unity 2018.3 / IL2CPP)의 **실제 플레이 메커니즘**을 역분석해,
> 이를 토대로 **새 게임**을 설계·구현하기 위한 청사진.
> 출처: `analysis/il2cpp_dump/dump.cs` (전체 클래스 구조) + OBB 자산.
>
> **중요**: 원작은 스탯 "구조/모델"은 바이너리에 있지만 **실제 수치 값은 서버가 내려주던 데이터**라 유실됨.
> → 우리는 **모델(어떤 속성이 있는가)을 그대로 쓰고, 수치는 새로 설계**한다. 각 표의 값 칸은 "우리가 정할 값".

---

## 1. 장르 / 핵심 정의

- **장르**: 3D 아레나 슈터 (3인칭 기반, 모바일). 멀티 + PvE 혼합.
- **조작 유닛**: `Player`(MonoBehaviour) — `CharacterController` + 수동 점프 물리 + 크로스헤어 조준.
- **적/NPC 유닛**: `PlayerMonster`(MonoBehaviour) — `NavMeshAgent` 경로탐색 AI (좀비/공룡 등).
- **발사**: 히트스캔(`BulletHit`/`BulletLine`) + 투척/로켓 등 투사체.
- **핵심 루프**: 로비 → 모드 선택 → 장비(캐릭터+무기 로드아웃) → 전투 → 결과/보상 → 성장.
- **새 게임 1차 목표 권장**: **오프라인 솔로 PvE**(웨이브 생존) — 서버/네트워크 없이 완결 가능한 영역.

---

## 2. 조작 병사 (Player)

| 속성 | 필드 | 설명 |
|---|---|---|
| 최대 체력 | `HP_MAX`, `TEMP_HP_MAX` | 기본 HP / 임시(버프) HP |
| 이동 속도 | `MOVE_SPEED`, `INCREASE_MOVE_SPEED_VALUE` | 기본 / 증가 버프 |
| 점프 | `move_jump_up`, `move_jump_down`, `move_jump_speed`, `move_jump_Max_height` | 상승/하강/속도/최고점 — 수동 포물선 |
| 슈퍼점프 | `isSuperjump`, `m_vecSuperJumpMove` | 특수 모드용 |
| 중력 | `m_bNoGravity` | 무중력 토글 |
| 사격 상태 | `isShot`, `m_nNoShotCount` | 발사 중 / 미사격 카운트(정확도 회복용) |
| 장착 무기 | `w_data: List<T_WEAPON_DATA>` | 현재 로드아웃 무기 스탯 |
| 처치 | `killCount`, `m_nForSpeed_KillCount` | 킬 수 / 킬당 속도 증가(모드별) |
| 이벤트 | `bigHead_ID`, `_isBiggestHeadMode` | 빅헤드 등 이벤트 변형 |

**설계 포인트**: 이동은 NavMesh가 아니라 `CharacterController` + 직접 계산한 점프 물리.
정확도는 "가만히 있을수록↑, 쏠수록↓"(`m_nNoShotCount` + 무기 `AIM_INIT`) 구조 → 그대로 채택 권장.

---

## 3. 무기 시스템

### 3.1 무기 타입 (`TYPE_WEAPON`)
RIFLE, MACHINE, SNIPER, PISTOL, SHOTGUN, KNIFE, GRENADE, CROSSBOW, DUALPISTOLS, ROCKET, SWORD, DUALRIFLES, THROW_WEAPON

### 3.2 로드아웃 슬롯 (`TYPE_SLOT`)
PRIMARY(주무기) · SECOND(보조) · KNIFE(근접) · THROW(투척) · CHARACTER(캐릭터)

### 3.3 등급 (`TYPE_WEAPON_GRADE`)
D < C < B < A < S < SS

### 3.4 무기 스탯 모델 (`T_WEAPON_DATA`) ★ 핵심
| 필드 | 의미 |
|---|---|
| `_DAMAGE_MIN` / `_DAMAGE_MAX` | 데미지 범위(거리/랜덤 보간) |
| `_CRITICAL` | 치명타 확률(float) |
| `_SPEED_SHOT` | 연사 속도(발사 간격) |
| `_AIM_INIT` | 초기 정확도(조준 퍼짐) |
| `AIM_PLUS` | 조준 보너스 |
| `REACTION` | 반동(피격반응/반동) |
| `_WEIGHT` | 무게 → 이동속도에 영향 |
| `_BULLET_MAX` | 탄창 크기 |
| `_BULLET_CNT` / `_BULLET_TOTAL` | 현재/총 예비탄 |
| `SCOPE` | 스코프(조준경 배율) |
| `SLOT` / `TYPE` / `GRADE` / `LEVEL` | 슬롯/종류/등급/레벨 |
| `_PVE` | PvE 전용 여부 |

### 3.5 무기 옵션/이펙트 (`T_WEAPON_OPTION_DATA`, `T_WEAPON_EFFECT`)
- 무기당 옵션 슬롯 `_EFFECT_1..5` + `EFFECTS: List<T_WEAPON_EFFECT>`.
- 이펙트 = `{ TYPE: TYPE_WEAPON_OPTION_EFFECT, VALUE: int }` (속성 증강).

### 3.6 무기 업그레이드 (`T_UPGRADE_W`, `T_UPGRADE_WEAPON_STAT`)
- 무기 레벨업 시 스탯 증가 커브. 소유 무기는 `M_WEAPON{ ID, UPGRADE, OPTION_ID[] }`로 기록.

**설계 포인트**: 데미지·연사·정확도·반동·무게·탄창 6축이 무기 밸런스의 전부.
무게↔이동속도 트레이드오프가 로드아웃 선택의 핵심.

---

## 4. 캐릭터 시스템

### 4.1 캐릭터 스탯 (`T_CHARACTER_DATA`)
| 필드 | 의미 |
|---|---|
| `_HP` | 체력 보너스 |
| `_SPEED` | 이동속도 |
| `_AVOID` | 회피율 |
| `SKILL` / `SKILL2` / `SKILL3` | 패시브 능력 3슬롯 (`TYPE_CHARACTER`) |
| `COST`, `SELL_TYPE`, `VIP`, `LEVEL`, `MAX` | 가격/재화/등급/레벨 |

### 4.2 캐릭터 능력 (`TYPE_CHARACTER`)
NONE, TEAM_KILL, **BULLET_UP**, **GRENADE_UP**, **SPEED_UP**, MISS_DOWN, GRENADE_POWER, RAGE_POWER,
**MAGAGINE_UP**, **CRITICAL_UP**, **JUMP_UP**, CRITICAL_DAMAGE_DOWN, CRITICAL_DAMAGE_UP,
SHOW_DAMAGE, SHOW_KILLER_HP, DAMAGE_DOWN, PROVOCATION

**설계 포인트**: 캐릭터 = "스탯(HP/속도/회피) + 패시브 3종" 조합. 능력들이 무기 스탯을 증폭(탄창↑/치명타↑/점프↑ 등).

---

## 5. 전투 메커니즘

- **명중 판정**: 히트스캔(`BulletHit`). 투척/로켓은 투사체(`PlayerMonster.Parabola`, 로켓 config).
- **부위 판정**: `PlayerMonster.setDead(shooter, isHead)` → **헤드샷 즉사/추가피해**. 히트박스 `t_head/t_body/t_hand`.
- **치명타**: 무기 `_CRITICAL` 확률 + 캐릭터 `CRITICAL_UP/CRITICAL_DAMAGE_UP`.
- **데미지 모델**: `_DAMAGE_MIN~_DAMAGE_MAX` 범위 → (거리/부위/치명타/옵션) 보정.
- **부스트 소모품 (`T_BOOST` / `TYPE_BOOST`)**: BULLET, GRENADE, HP, EXP, RADER, CLIP, DEFENCE, GOLD, SPEED, RESPAWN, TEAMKILL, SCOREDOUBLE, PVE_HP, PVE_MAIN_CLIP …
- **점수→경험치 (`T_SCORE`)**: 이벤트(킬/헤드샷/어시스트)별 `EXP`.

---

## 6. 게임 모드 (`TYPE_ROOM`, 40+)

### 6.1 분류
- **기본 대전**: SINGLE(개인전), TEAM(팀 데스매치), CLAN, BEGINNER/SUPER_BEGINNER, PERSONAL
- **목표형**: FLAG(깃발), MODE_OCCUPY(점령), MODE_TOUCHDOWN(터치다운), MODE_EXPLOSION(폭파)/_CLAN/_RESPAWN, MODE_CATCH(술래)
- **무기 제한**: SNIPER, PISTOL, MODE_SHOTGUN, MODE_GRENADE, MODE_HEAD/MODE_HEAD_SHOT/MODE_NO_HEAD_SHOT
- **특수 룰**: MODE_SUPER_JUMP, MODE_SPEED, MODE_ROUND, MODE_MAN_TO_MAN(1:1)
- **이벤트 모드**: MODE_ZOMBIE / MODE_ZOMBIE_2, MODE_GLADIATOR, MODE_HIDEANDSEEK, MODE_CHICKENPHOBIA, MODE_SNOW_FIGHT, MODE_ROCKET, MODE_ROBOT
- **PvE**: MODE_PVE, MODE_PVE_NET, MODE_PVE_NET_2
- **매칭/연습**: MODE_TEAM_MATCHING, MODE_TEAM_AI, MODE_FAIRPLAY, DRILL_FILED, TRAINING, TUTORIAL, MODE_CUSTOM

### 6.2 특수 모드 규칙 (실제 튜닝 파라미터)

**좀비2 (`M_ZOMBIE_2_CONFIG`)** — 인간 vs 좀비 비대칭
- 좀비슬레이어 선발: `HUMAN_COUNT_TO_SELECT_ZOMBIE_SLAYER`, 선택시간/스킬쿨
- 좀비로드 스킬: 반경(`RADIUS`)/속도/스모그(연막)시간/사거리/데미지
- 캐릭터 리스폰 타임, 최대 플레이타임, 속도버프 값/시간, 생화학폐기물 스폰(횟수/시간/수량)

**글래디에이터 (`M_GLADIATOR_CONFIG`)**
- 검 최초 리스폰/획득 시간, 검 아이템, 스킬(쿨/속도업 유지시간/속도업 값/무피격 유지/데미지)

**숨바꼭질 (`M_HIDE_AND_SEEK_CONFIG`)** — 변신 술래잡기
- 변신 이벤트캐릭 3종 + 등장률/공격력/은신공격/속도증가
- 오브젝트(숨는쪽): 점프↑/HP↓/이동↓ 보정, 술래: 피격↓/HP↑/이동↑ 보정
- 버닝타임(가속 구간), 오브젝트 변신 타이밍

**스노우파이트 (`M_SNOW_FIGHT_CONFIG`)**
- 기본무기 + 눈폭탄/눈돌/눈로켓, 폭발반경, **동결시간**/해제상호작용, 회복(본인/팀)

**로켓 (`M_ROCKET_CONFIG`)** — 로켓점프 액션
- 로켓속도/폭발반경, **로켓점프 쿨타임**, 점프패드 무조작시간, 아이템 버프(DP/AP/SPD/HP) + 버프시간
- 파괴오브젝트 HP, 발사 카메라 흔들림(파워/시간), 리스폰 타임

**SD/맨투맨 (`M_SD_CONFIG`)**
- 맵 인덱스, 최대 킬, 리스폰 수, 메달 충전, 체크타임, 하트 코스트, 입장 시간

**공정전 (`M_FAIRPLAY_CONFIG`)** — 장비 강제 통일
- 캐릭터 레벨 / 주·보조·근접 무기 등급+레벨 고정 → 실력 위주 밸런스

---

## 7. PvE 시스템 ★ (새 게임 1차 타깃)

### 7.1 적 유닛 (`PlayerMonster`, NavMesh AI)
| 속성 | 필드 |
|---|---|
| 체력/공격 | `HP`, `MAXHP`, `ATTACK` |
| 이동 | `SPEED` (+ NavMeshAgent 경로탐색) |
| 교전 거리 | `ATTACK_DISTANCE`, `MAINOBJ_ATTACK_DISTANCE`, `SUBOBJ_ATTACK_DISTANCE` |
| 종류 | `TYPE: PVE_ZOMBIE_TYPE`, `DINO_TYPE: PVE_DINO_TYPE`, `ATTACK_TYPE` |
| 판정 | `setDead(shooter, isHead)` 헤드샷, `t_head/t_body/t_hand` 히트박스 |
| 점수 | `POINT`, 보너스몹 `m_bBonus` |

- **좀비 종류 (`PVE_ZOMBIE_TYPE`)**: DEFAULT, NORMAL A/B, DEFENSE(방어형), DOG(개=고속)
- **공룡 종류 (`PVE_DINO_TYPE`)**: DEFAULT, DILOPHO, TYRANNOSAURUS, PENTACERATOPS, VELOCIRAPTOR, MORDRED(보스)
- **공격 타입 (`PVE_MONSTER_ATTACK_TYPE`)**: MULTI / PLAYER(플레이어 추적) / OBJECT(거점 공격)

### 7.2 봇 AI (`T_AI_CHARACTER`) — 대전용 AI 병사
| 파라미터 | 의미 |
|---|---|
| `searchDistance`/`combatDistance`/`minDistance` | 탐지/교전/최소접근 거리 |
| `weapon1/2/3` | 봇 로드아웃 |
| `shotMin`/`shotMax` | 버스트 사격 길이 |
| `shootingDelayMin/Max` | 발사 간격(연사감) |
| `reactionsAttack/Move/SearchTarget/ChangeTarget` | **반응시간 4종 = 난이도의 핵심** |
| `avoidCheckTime`/`avoidRate`/`avoidCount` | 회피 행동 |
| `charExp`/`weaponExp` | 봇 파워 레벨 |

- **난이도 티어 (`T_AI_LEVEL`)**: `level → minID~maxID` 범위의 봇 캐릭터 풀. 반응시간↓ = 고난이도.

### 7.3 웨이브 스폰 (`T_LEVEL`)
`{ TYPE, LEVEL, POS(스폰위치), COUNT(수), TIME(타이밍), list_monster }`
→ 웨이브별 "어디서/몇 마리/언제" 몬스터 스폰 스케줄.

### 7.4 PvE 진행/서바이벌 (`T_PVENET2_DATA` = 호드 모드)
- 입력: 맵, 캐릭터, 무기 3종.
- 진행 추적: `_WAVE_COUNT`, `_PLAY_TIME`, `_KILL_COUNT`, `_HEADSHOT`, `_TOTAL_DAMAGE`, `_DEATH`, `_RESPAWN`
- **인게임 업그레이드**(포인트 소모): `_ATK_UPGRADE_COUNT`, `_SPEED_UPGRADE_COUNT`, `_HP_INC_COUNT`, `_WP_INC_LEVEL`, `_WP_CHARGE`
- 협동 요소: `_HEAL_COUNT`/`_TARGET_HEAL_COUNT`, `_BARRICADE`(방어물)
- 경제: `_BUY_POINT`, `_TOTAL_POINT`, `_COST_POINT`
- (`T_PVENET_DATA`는 구버전: 무기별 WP1/WP2 충전·공격레벨, 부활/치료 카운트)

**설계 포인트**: PVENET2 = **웨이브 생존 + 인게임 포인트로 공격/속도/체력/무기 강화 + 협동(치료/바리케이드)**.
이 한 모드만으로도 완결된 오프라인 솔로 게임이 성립 (봇 동료 or 순수 솔로).

---

## 8. 성장 / 경제

- **레벨/경험치**: `T_SCORE`(행동별 EXP) → 플레이어 레벨(`M_PLAYER` exp/level 계산).
- **티어/랭크**: `T_TIER`, 클래스게임(`M_CLASS_GAME_*`) 시즌 랭크(그룹 D~상위).
- **재화 (`TYPE_MONEY`)**: 골드/캐시 등. 상점 `T_STORE`, 박스 `T_BOX`, 캐시 `T_CASH`.
- **무기/캐릭터 구매·업그레이드·스킨**: `T_CHARACTER_SKIN`, `T_WEAPON_*`, 수리비(`REPAIR_COST`).

---

## 9. 새 게임 설계 제안

### 9.1 가져올 것 (검증된 재미 구조)
1. **무기 6축 밸런스**(데미지/연사/정확도/반동/무게/탄창) + 무게↔속도 트레이드오프.
2. **정확도 동역학**(정지 조준↑ / 연사 퍼짐↑) + **헤드샷 부위판정**.
3. **캐릭터 = 스탯 3종 + 패시브 3슬롯** 조합.
4. **PvE 웨이브 서바이벌(PVENET2 모델)**: 스폰 스케줄 + 인게임 업그레이드 경제.
5. **봇 AI 반응시간 기반 난이도**(T_AI_CHARACTER).

### 9.2 단순화/제거 (오프라인 솔로 기준)
- 서버/로그인/매칭/클랜/랭킹/상점 캐시결제 → 전부 제거 또는 로컬화.
- 네트워크 동기화(PACKET.*) → 불필요(싱글).
- 40개 모드 → **핵심 3~4개**로 시작: PvE 웨이브 / 팀 데스매치(봇) / 좀비 / 한 가지 이벤트 모드.

### 9.3 권장 1차 구현 범위 (MVP)
> **"오프라인 PvE 웨이브 서바이벌"** 하나를 완성품으로:
> 조작 병사 1명 + 무기 2~3종 + 캐릭터 1~2종 → 맵 1개에서 좀비 웨이브(T_LEVEL 스폰) 생존,
> 처치 포인트로 공격/속도/체력 강화(PVENET2). 헤드샷·치명타·부스트 포함. 서버 없음.

### 9.4 기술 스택 제안
- 엔진: Unity(원작과 동일 메커니즘 이식 용이) 또는 신규 엔진에 위 모델 재구현.
- 적 AI: NavMesh(원작과 동일) — 스폰포인트 + 경로탐색 + 교전거리 상태머신.
- 데이터: 위 `T_*` 구조를 JSON 테이블로 정의하고 값은 신규 밸런싱.

---

## 부록: 분석 산출물 위치
- 전체 클래스 구조: `analysis/il2cpp_dump/dump.cs`
- 메서드/문자열 테이블: `analysis/il2cpp_dump/methods.csv`, `string_literals.csv`
- API 엔드포인트 맵: `analysis/obb_text/T_PROTOCOLS.json`
- 현지화 텍스트: `analysis/obb_text/Localization_server.txt`

> 다음 단계로 특정 시스템(예: 정확한 데미지 수식, 무기 업그레이드 커브, 점프 물리 상수)의
> **메서드 본문 역어셈블**이 필요하면 지정해 주세요 — 해당 RVA를 디스어셈블해 수식까지 복원합니다.
