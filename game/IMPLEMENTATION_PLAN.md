# Unity 구현 계획 — PvE 웨이브 서바이벌 MVP

> 확정 범위: **오프라인 솔로 PvE 웨이브 서바이벌**. 서버·로그인·네트워크 전무.
> 경제는 **골드 단일**, 상점은 **인게임 강화(MVP) → 로비 메타(2단계) → 가챠(3단계)** 단계적.
> 근거 문서: `analysis/MVP_PVE_SURVIVAL.md`, `SYSTEMS_TEARDOWN.md`, `MODES_AND_MAPS.md`. 아트: 택티컬(시안 확정).

---

## 0. 전제조건 (빌드 환경)

- **Unity 2022 LTS** 권장(원작 2018보다 신기능·안정성↑, 메커니즘 이식엔 무관). 2D 아님, URP.
- 타깃: **Android** (원작과 동일, 세로 아님 **가로**).
- 의존: 내장 **NavMesh**(AI 경로), **CharacterController**(플레이어), uGUI(HUD).
- ⚠️ **빌드/실행엔 Unity 에디터가 도는 PC/Mac이 필요**합니다. 지금 이 클라우드 환경에선 **코드·에셋·데이터·씬 설계까지 전부 작성**해 레포에 커밋하고, 실제 열기/빌드/디바이스 테스트는 에디터가 있는 환경에서 진행합니다. (PC가 없으면 Unity Cloud Build 또는 에디터 가능한 환경 확보가 선행 과제.)
- 외부 에셋/플러그인 없이 **순정 Unity**로 시작(이식성·단순성).

---

## 1. 프로젝트 구조

```
game/
├─ IMPLEMENTATION_PLAN.md        ← (이 문서)
├─ ProjectSettings/              ← Unity 프로젝트 설정
├─ Assets/
│  ├─ Scenes/
│  │   ├─ Boot.unity             ← 부트/로딩
│  │   ├─ Lobby.unity            ← 로비·모드선택·장비
│  │   └─ Battle_Dust.unity      ← 전투 맵 1개(마커 계약 준수)
│  ├─ Scripts/
│  │   ├─ Core/       (GameManager, GameState, SaveSystem, DataLoader)
│  │   ├─ Player/     (PlayerController, WeaponController, PlayerHealth, CrossHair)
│  │   ├─ Enemy/      (ZombieAI, EnemyHealth, Hitbox)
│  │   ├─ Combat/     (DamageSystem, Hitscan, Projectile)
│  │   ├─ Wave/       (WaveManager, SpawnPoint)
│  │   ├─ Economy/    (PointSystem, UpgradeShop, Upgrade)
│  │   └─ UI/         (HUD, Joystick, FireButton, ShopUI, ResultUI)
│  ├─ Data/           ← 밸런싱 JSON (StreamingAssets)
│  │   ├─ player.json  weapons.json  zombies.json  waves.json  upgrades.json
│  ├─ Prefabs/        (Player, Zombie_Normal/Dog/Defense, Bullet, Barricade, SpawnMarker)
│  └─ Art/            (플레이스홀더 → 추후 교체)
```

- **데이터는 JSON(StreamingAssets)** 로 분리 → 코드 재컴파일 없이 밸런싱. (ScriptableObject 미러링은 선택.)
- 전투 맵은 `MODES_AND_MAPS.md`의 **마커 계약**만 지키면 어떤 맵이든 동작.

---

## 2. 데이터 레이어 (JSON)

`analysis/MVP_PVE_SURVIVAL.md` 표를 그대로 파일로. `DataLoader`가 부팅 시 역직렬화.

| 파일 | 내용 | 원작 근거 |
|---|---|---|
| `player.json` | HP·이동·점프·헤드샷/치명 배수·퍼짐·무게패널티 | `Player` 필드 |
| `weapons.json` | 무기 6축(데미지/연사/정확/반동/장탄/무게)+스코프 | `T_WEAPON_DATA` |
| `zombies.json` | HP·공격·속도·공격거리·쿨·포인트·타입 | `PlayerMonster`+`PVE_ZOMBIE_TYPE` |
| `waves.json` | 웨이브별 스폰(지점·종류·수·간격·딜레이)+보상·준비시간 | `T_LEVEL` |
| `upgrades.json` | 강화 5종(효과/레벨당/비용커브/최대)+소모품 | `T_PVENET2_DATA` |

---

## 3. 시스템 / 스크립트 맵

### Core
- **GameManager** (싱글톤): 게임 상태머신 `Boot → Lobby → Loadout → Battle ↔ WaveBreak(Shop) → Result`. 씬 로드, 흐름 제어.
- **DataLoader**: StreamingAssets JSON → 런타임 테이블(Dictionary). 부팅 1회.
- **SaveSystem**: 로컬 저장(보유 무기/골드/최고기록) — `Application.persistentDataPath`, JSON. 서버 없음.

### Player (조작 병사 — `Player` 역분석 기반)
- **PlayerController**: `CharacterController` 이동 + **수동 2단 점프**(상승 `jumpUp`→Max, 하강 `jumpDown` 중력적분), 무게→속도 패널티. 가상 조이스틱 입력.
- **WeaponController**: 발사 간격(`SPEED_SHOT`), 재장전, **동적 정확도**(`AIM_INIT`+연사 퍼짐, 미사격 회복), 무기 전환(주/보조/근접).
- **PlayerHealth**: HP, 피격, 사망/리스폰(5초), 긴급치료.
- **CrossHair**: 퍼짐 시각화(정지↓/연사↑).

### Combat (`callShot`→`setHit*` 파이프라인)
- **Hitscan**: 카메라/총구 레이캐스트, 퍼짐 적용, 부위(Hitbox) 판정.
- **DamageSystem**: `Random(min,max) → ×헤드샷(2.5) → ×치명타(prob→1.8) → ×(1+강화%) → 대상 적용`.
- **Projectile**(후순위): 투척/로켓.

### Enemy (`PlayerMonster` NavMesh AI)
- **ZombieAI**: FSM `IDLE→CHASE(NavMeshAgent.destination=player)→ATTACK(쿨마다 데미지)`. 타입별(노멀/대쉬독/디펜스) 스탯.
- **EnemyHealth** + **Hitbox**(머리/몸): `setDead(shooter,isHead)` 헤드샷 즉사/추가피해, 처치 시 포인트.

### Wave (`T_LEVEL` 스폰)
- **WaveManager**: `waves.json` 읽어 스폰포인트에서 종류·수·간격·딜레이대로 생성. 전멸 판정 → 웨이브 클리어 → `WaveBreak`(상점) → 다음.
- **SpawnPoint**: 씬 마커(A/B/C/D).

### Economy (인게임 강화 — PVENET2)
- **PointSystem**: 처치/헤드샷/클리어 포인트 적립(1판 한정).
- **UpgradeShop**: 웨이브 사이, 포인트로 공격/속도/체력/무기 강화 + 긴급치료/바리케이드. 레벨·비용커브.

### UI (택티컬 HUD)
- **HUD**: 체력바·탄약·웨이브·포인트·킬피드.
- **Joystick**(좌 이동) / **FireButton**(우) + 재장전/투척/점프.
- **ShopUI**(웨이브 사이) / **ResultUI**(집계+보상+최고기록).

---

## 4. 전투 수식/상수 (복원 구조 + MVP 값)

```
이동:   pos += dir * MOVE_SPEED(5.0) * (1 - weightPenalty) * dt
점프:   up: h += 0.09 (→ max 2.0);  down: acc += 0.012; h -= acc;  수평 6.0
데미지: base=Random(MIN,MAX); if head base*=2.5; if rand<CRIT base*=1.8; base*=(1+upgrade%)
정확도: spread = AIM_INIT + noShot*0.15 (max 10), 미사격 0.2s당 -1
발사:   nextFire = now + SPEED_SHOT; 탄창0 → 자동재장전
```
(정확한 원작 매직넘버는 난독화·서버측 유실 → 위 값은 MVP 초기 밸런싱, `*.json`에서 조정)

---

## 5. 씬 구성 (전투 맵 마커 계약)

`Battle_Dust.unity` 최소 구성:
- **NavMesh 베이크**된 바닥/장애물(플레이스홀더 지오메트리).
- `PlayerSpawn` ×1, `SpawnPoint` ×4(A/B/C/D, NavMesh 위), `DeadZone`(추락).
- (후속 모드용 마커는 계약만 정의, MVP 미사용): BombArea, OccupyTarget, FlagTarget.
- 원작 맵은 유실 → **신규 제작**(저작권·데이터 부재). 마커 계약만 지키면 교체 자유.

---

## 6. 마일스톤 (버티컬 슬라이스 우선)

| M | 목표 | 완료 기준 |
|---|---|---|
| **M0** | 프로젝트+입력+이동 | 빈 씬에서 조이스틱으로 이동·2단 점프 |
| **M1** | 사격 | 히트스캔+크로스헤어 퍼짐+재장전, 벽에 탄착 |
| **M2** | 적 1종 | 좀비 NavMesh 추적→공격→피격→사망, **헤드샷** |
| **M3** | 웨이브 | WaveManager가 waves.json대로 스폰·전멸판정 |
| **M4** | 경제 | 처치 포인트→웨이브 사이 강화상점 구매 반영 |
| **M5** | 루프 완성 | HUD+결과+로컬 최고기록 = 1판 완결 |
| **M6** | 콘텐츠 | 무기 3·좀비 3·웨이브 5 채우고 밸런싱 |

→ **M0~M2가 핵심 재미 증명**(쏘고 맞추고 좀비 잡는 손맛). 여기서 "재밌다" 확인 후 M3+.

---

## 7. 원작 추적성

| MVP 시스템 | 원작 클래스/데이터 |
|---|---|
| PlayerController | `Player`(move_jump*, MOVE_SPEED) |
| WeaponController/DamageSystem | `callShot`/`setHitMonster`/`WeaponManager`, `T_WEAPON_DATA` |
| ZombieAI/EnemyHealth | `PlayerMonster`(NavMeshAgent, ATTACK_DISTANCE, setDead) |
| WaveManager | `T_LEVEL`(POS/COUNT/TIME) |
| PointSystem/UpgradeShop | `T_PVENET2_DATA`(_ATK/_SPEED/_HP/_WP, _BARRICADE, _HEAL) |
| SaveSystem | (신규 — 서버 대체, 로컬) |

---

## 8. 다음 액션 (제안)

1. `game/Assets/Data/*.json` **데이터 테이블부터 작성**(밸런싱 확정, 코드 전 선행).
2. `game/Assets/Scripts/` **핵심 스크립트 스캐폴딩**(Core→Player→Combat→Enemy→Wave→Economy→UI).
3. 씬·프리팹 설계 명세(에디터에서 조립할 수 있게 셋업 가이드 동봉).
4. 에디터 환경에서 M0부터 순차 검증.

> 이 클라우드 환경에서 1~3(코드·데이터·명세)을 전부 만들어 레포에 올리고, Unity 에디터 환경에서 열어 M0부터 돌리는 흐름입니다.
