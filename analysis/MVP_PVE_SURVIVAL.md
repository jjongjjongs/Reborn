# MVP 상세 설계: 오프라인 PvE 웨이브 서바이벌

> 원작 `com.wellgames.ss`의 **PVENET2(호드 서바이벌)** 모델을 토대로 재구성한, **서버 없이 완결되는 솔로 게임**의 즉시 구현용 스펙.
> 수식 "구조"는 역분석으로 복원, 수치는 플레이 가능하도록 신규 밸런싱(원작 값은 서버측·난독화라 유실).
> 데이터는 전부 JSON 테이블로 분리 → 코드 수정 없이 밸런싱 가능.

---

## 0. 한 줄 정의
병사 1명이 맵 1개에서 **몰려오는 좀비 웨이브를 생존**하며, 처치로 얻은 **포인트로 인게임 강화**(공격/속도/체력/무기)를 사서 점점 강해지는 **3인칭 슈터**. 헤드샷·치명타·재장전·부스트 포함. 네트워크 전무.

---

## 1. 플레이어 (조작 병사)

| 파라미터 | 값 | 비고 (원작 필드) |
|---|---|---|
| 기본 HP | **100** | `HP_MAX` |
| 이동 속도 | **5.0 m/s** | `MOVE_SPEED` (무기 무게로 감속) |
| 회전/조준 감도 | 터치 드래그 기준 | `update_Rotate` |
| 점프 최고점 | **2.0 m** | `move_jump_Max_height` |
| 점프 상승량/프레임 | **0.09** | `move_jump_up` |
| 점프 하강 가속 | **0.012/프레임² 누적** | `move_jump_down` + `move_jump_down_add` (중력적분) |
| 수평 점프 속도 | **6.0 m/s** | `move_jump_speed` |
| 리스폰 시간 | **5초** | PVENET2 `_RESPAWN` |

### 1.1 이동/점프 공식 (복원된 구조)
- **이동**: `pos += moveDir * MOVE_SPEED * (1 - weightPenalty) * dt`
  - `weightPenalty = clamp(무기무게 / WEIGHT_MAX, 0, 0.4)` — 무거운 무기일수록 최대 40% 감속.
- **점프(수동 2단, NavMesh 아님 / CharacterController)**:
  ```
  상승기: height += move_jump_up (매 프레임), height가 Max_height 도달 시 하강 전환
  하강기: down_add += move_jump_down;  height -= down_add    // 가속 낙하(중력적분)
  수평:   dir * move_jump_speed * dt
  ```
  → 포물선. `isSuperjump`면 수평·높이 증폭(특수 아이템용, MVP에선 선택).

---

## 2. 무기 (MVP 3종)

### 2.1 스탯 모델 (`T_WEAPON_DATA`, MVP에서 쓰는 축만)
`DAMAGE_MIN, DAMAGE_MAX, CRITICAL(%), SPEED_SHOT(연사간격 s), AIM_INIT(초기퍼짐), REACTION(반동), WEIGHT, BULLET_MAX(탄창), BULLET_TOTAL(예비), SCOPE`

### 2.2 MVP 무기 3종 (슬롯별 1개씩)

| 무기 | TYPE | 슬롯 | DMG_MIN | DMG_MAX | CRIT% | 연사간격(s) | AIM_INIT | REACTION | WEIGHT | 탄창 | 예비 | SCOPE |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **M4 돌격소총** | RIFLE | PRIMARY | 18 | 26 | 8 | 0.11 | 0.9 | 1.0 | 40 | 30 | 150 | 1.0 |
| **데저트이글 권총** | PISTOL | SECOND | 34 | 46 | 12 | 0.28 | 0.6 | 1.6 | 20 | 7 | 56 | 1.0 |
| **전투나이프** | KNIFE | KNIFE | 55 | 75 | 20 | 0.5 | 0 | 0 | 5 | ∞ | ∞ | 1.0 |

- `AIM_INIT` = 정지 시 조준 원 반경(작을수록 정확). `SPEED_SHOT` = 발사 간격(작을수록 빠름).
- 나이프는 근접(사거리 ~2m), 탄약 무한.

### 2.3 사격/명중 공식 (복원된 구조)
- **발사 간격**: `nextFire = now + SPEED_SHOT`. 탄창 0 → 자동 재장전(`is_AutoReload`).
- **조준 퍼짐(동적 정확도)**:
  ```
  spread = AIM_INIT + m_nNoShotCount * SPREAD_PER_SHOT      // 연사할수록 벌어짐
  연사 중:  m_nNoShotCount++  (상한 존재)
  미사격:  시간당 m_nNoShotCount 감소 → 퍼짐 회복(isShot=false)
  ```
  - 권장: `SPREAD_PER_SHOT = 0.15`, 상한 `NoShot_MAX = 10`, 회복 `0.2초당 -1`.
- **탄착**: 조준선 ± `Random(-spread, spread)` 방향으로 히트스캔(`BulletHit`).

### 2.4 데미지 공식 (복원된 구조 — 결합 순서)
```
base   = Random(DAMAGE_MIN, DAMAGE_MAX)
head   = isHead ? base * HEADSHOT_MULT : base          // 부위판정(t_head)
crit   = (rand% < CRITICAL) ? head * CRIT_MULT : head   // 치명타
opt    = crit * (1 + Σ 옵션이펙트%)                     // 무기옵션/캐릭터패시브 (AddEffectValuePercent)
final  = round(opt * (1 + bossWeakness or armorMod))    // 몬스터 방어/약점 보정
```
- 권장 상수: **HEADSHOT_MULT = 2.5**, **CRIT_MULT = 1.8**.
- 옵션이펙트는 `TYPE_WEAPON_OPTION_EFFECT`별 % 가산(MVP에선 생략 가능).

---

## 3. 캐릭터 (MVP 1~2종)

| 캐릭터 | HP보너스 | 속도 | 회피% | 패시브1 | 패시브2 | 패시브3 |
|---|---|---|---|---|---|---|
| **레인저(기본)** | +0 | 1.00 | 3 | BULLET_UP | — | — |
| **스카우트** | -10 | 1.12 | 6 | SPEED_UP | JUMP_UP | — |

- 패시브 효과(`TYPE_CHARACTER`) 권장 수치: BULLET_UP=데미지+8%, SPEED_UP=이동+10%, JUMP_UP=점프높이+25%, CRITICAL_UP=치명타확률+6%p, MAGAGINE_UP=탄창+20%.
- MVP는 레인저 1종만으로도 성립.

---

## 4. 적 (좀비 3종, NavMesh AI)

### 4.1 모델 (`PlayerMonster`)
`HP, MAXHP, ATTACK, SPEED, ATTACK_DISTANCE, TYPE(PVE_ZOMBIE_TYPE), POINT, 헤드박스`

### 4.2 MVP 좀비 3종

| 좀비 | TYPE | HP | ATTACK | SPEED | 공격거리 | 공격쿨 | POINT | 특징 |
|---|---|---|---|---|---|---|---|---|
| **노멀** | ZOMBIE_NORMALA | 60 | 10 | 2.2 | 1.6m | 1.2s | 10 | 기본 추적 |
| **대쉬독** | ZOMBIE_DOG | 35 | 8 | 4.5 | 1.4m | 0.9s | 15 | 고속·저체력 |
| **디펜스** | ZOMBIE_DEFENSE | 180 | 18 | 1.4 | 1.8m | 1.6s | 30 | 탱커·둔함 |

### 4.3 적 AI 상태머신 (복원된 구조)
```
IDLE → (플레이어가 searchDistance 내) → CHASE(NavMeshAgent.destination = player)
CHASE → (거리 ≤ ATTACK_DISTANCE) → ATTACK(공격쿨마다 ATTACK 데미지)
피격 → setDamage(dmg);  HP ≤ 0 → setDead(shooter, isHead)
       isHead==true면 헤드샷 처리(즉사/추가연출), POINT 지급
```
- 경로탐색: Unity NavMesh(원작 동일). 스폰포인트에서 생성 → 플레이어 추적.
- 보너스몹(`m_bBonus`): 일정 확률로 처치 시 포인트 2배.

---

## 5. 웨이브 (스폰 스케줄, `T_LEVEL` 모델)

### 5.1 스폰 모델
`{ WAVE, SPAWN_POINT, ZOMBIE_TYPE, COUNT, INTERVAL(s), START_DELAY(s) }`

### 5.2 MVP 5웨이브 (맵: 스폰포인트 4곳 A/B/C/D)

| 웨이브 | 구성 | 총 수 | 클리어 조건 | 웨이브 보상P |
|---|---|---|---|---|
| **1** | 노멀×8 (A,B) | 8 | 전멸 | +50 |
| **2** | 노멀×10 + 독×4 (A,B,C) | 14 | 전멸 | +80 |
| **3** | 노멀×12 + 독×8 (전 스폰) | 20 | 전멸 | +120 |
| **4** | 노멀×10 + 독×6 + 디펜스×3 | 19 | 전멸 | +160 |
| **5 (보스)** | 디펜스×6 + 독×12 + 노멀×15 | 33 | 전멸 | +300 |

- 웨이브 간 **준비 시간 8초**(강화 상점 오픈). START_DELAY로 순차 투입.
- 예시(웨이브3): `[{A,NORMAL,4,1.5,0},{B,NORMAL,4,1.5,0},{C,DOG,4,1.0,3},{D,DOG,4,1.0,3},{A,NORMAL,4,1.5,6}]`

---

## 6. 인게임 강화 경제 (`T_PVENET2_DATA` 모델)

### 6.1 포인트 획득
- 좀비 처치: `POINT`(표 참조), 헤드샷 보너스 +5, 보너스몹 ×2, 웨이브 클리어 보상.

### 6.2 강화 상점 (웨이브 사이 / 실시간, 포인트 소모)

| 강화 | 효과/레벨 | 비용(레벨별 증가) | 최대레벨 | 원작 필드 |
|---|---|---|---|---|
| **공격력↑** | 데미지 +10%/레벨 | 60 × 1.5^Lv | 10 | `_ATK_UPGRADE_COUNT` |
| **이동속도↑** | 속도 +5%/레벨 | 50 × 1.5^Lv | 6 | `_SPEED_UPGRADE_COUNT` |
| **최대체력↑** | HP +25/레벨 | 70 × 1.5^Lv | 8 | `_HP_INC_COUNT` |
| **무기레벨↑** | 탄창+2·재장전-5%/레벨 | 80 × 1.6^Lv | 5 | `_WP_INC_LEVEL` |
| **긴급치료** | HP 즉시 +50% | 100 (고정) | 소모 | `_HEAL_MY_COUNT` |
| **바리케이드** | 스폰로 차단물 설치(HP 300) | 150 (고정) | 소모 | `_BARRICADE` |

### 6.3 결과 집계 (클리어/사망 시)
`_WAVE_COUNT, _PLAY_TIME, _KILL_COUNT, _HEADSHOT, _TOTAL_DAMAGE, _DEATH, _TOTAL_POINT` → 로컬 저장(최고기록).

---

## 7. 부스트 소모품 (`T_BOOST`, 시작 전 장착 — 선택)
BULLET(예비탄+), HP(시작HP+), SPEED(이동+), PVE_HP, PVE_MAIN_CLIP(탄창+) 중 2슬롯. MVP는 생략 가능.

---

## 8. 데이터 스키마 (JSON, 바로 사용)

```jsonc
// weapons.json
[{ "id":1,"name":"M4","type":"RIFLE","slot":"PRIMARY",
   "dmgMin":18,"dmgMax":26,"crit":8,"fireInterval":0.11,"aimInit":0.9,
   "reaction":1.0,"weight":40,"clip":30,"reserve":150,"scope":1.0 }, ...]

// zombies.json
[{ "id":1,"type":"NORMAL","hp":60,"attack":10,"speed":2.2,
   "attackDist":1.6,"attackCool":1.2,"point":10 }, ...]

// waves.json
[{ "wave":1,"prepTime":8,"reward":50,
   "spawns":[{"point":"A","zombie":"NORMAL","count":4,"interval":1.5,"delay":0}, ...] }, ...]

// upgrades.json
[{ "id":"ATK","perLevel":"dmg+10%","baseCost":60,"costMul":1.5,"maxLv":10 }, ...]

// player.json
{ "hp":100,"moveSpeed":5.0,"jumpHeight":2.0,"jumpUp":0.09,"jumpDownAcc":0.012,
  "jumpSpeed":6.0,"respawn":5,"headshotMult":2.5,"critMult":1.8,
  "spreadPerShot":0.15,"noShotMax":10,"spreadRecover":"-1/0.2s","weightMaxPenalty":0.4 }
```

---

## 9. 구현 체크리스트 (순서)
1. **플레이어 컨트롤러**: 이동 + 수동 2단 점프 + 조준 회전.
2. **사격 시스템**: 히트스캔 + 동적 퍼짐 + 재장전 + 탄창/예비.
3. **데미지 파이프라인**: Random(min,max)→헤드샷→치명타→옵션%→몬스터 적용.
4. **좀비 AI**: NavMeshAgent 추적 + 공격거리 상태머신 + 헤드박스 피격.
5. **웨이브 매니저**: 스폰포인트 + 스케줄 + 준비시간 + 클리어 판정.
6. **포인트/강화 상점**: 처치 포인트 → 실시간 강화 구매.
7. **HUD/결과**: HP·탄약·포인트·웨이브 + 결과 집계·로컬 저장.

> 1~7을 맵 1개로 완성하면 **서버·로그인·네트워크 없는 완결 게임**이 된다.
> 원작과 달리 모든 수치는 위 JSON에서 조정 → 반복 밸런싱 용이.

---

## 10. 원작 대비 매핑 (추적성)
| MVP 개념 | 원작 근거 |
|---|---|
| 무기 6축 | `T_WEAPON_DATA._DAMAGE/_CRITICAL/_SPEED_SHOT/_AIM_INIT/REACTION/_WEIGHT/_BULLET_*` |
| 동적 정확도 | `Player.m_nNoShotCount` + `isShot` + `update_Shot` |
| 데미지 결합 | `callShot`→`setHitMonster`(headshot 분기) + `WeaponManager.AddEffectValuePercent` |
| 2단 점프 | `Player.update_Move`(중력적분) + `move_jump*` 필드 |
| 좀비 AI | `PlayerMonster`(NavMeshAgent, ATTACK_DISTANCE, setDead(isHead)) |
| 웨이브 | `T_LEVEL`(POS/COUNT/TIME) |
| 강화 경제 | `T_PVENET2_DATA`(_ATK/_SPEED/_HP/_WP 업그레이드, _BARRICADE, _HEAL) |
