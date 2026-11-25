# 시스템별 완전 분해 (#3)

> 봇 AI · 무기 옵션 · 좀비2 모드 · PVE_NET_2를 클래스/메서드 레벨로 분해.
> 데이터 수치는 서버 다운로드였어 유실(OBB/APK에 CSV 미동봉 확인) → **행동/구조 로직**이 복원 대상.

---

## A. 봇 AI 시스템 ★ (대전용 AI 병사)

### A.1 아키텍처 (계층)
```
BotManager (Singleton)
  ├ m_DicBotInfo: Dictionary<int, BotInfo>      // 봇 ID → 정보
  ├ AddBot(index, BOT_TYPE) / CreateBotPlayer() // 봇 생성
  └ m_ArrayRespawnCount[]                        // 봇별 리스폰 횟수
       │
       ▼
BotInfo { M_PLAYER mPlayer, BotPlayer player, T_AI_CHARACTER aiData }
       │ (aiData = 난이도/성능 파라미터, CSV 원본은 유실)
       ▼
AIStateManager (Singleton)
  ├ m_BotList: List<FsmAiState>
  ├ AddBot(fas) / StartAI() / GetFsmAiState(BotPlayer)
  ├ m_AdminState (디버그용 전역 상태)
  └ CheckM67Explosion(M67_Grenade)   // 모든 봇에 수류탄 회피 신호 ★
       │
       ▼
FsmAiState : MonoBehaviour  (PlayMaker FSM 상태, co_CheckDead 포함)
       │
       ▼
AIHuman : FsmAiState  (실제 전투 봇)
  ├ m_arryAvoidDirection[] / avoidlist : eAvoidDirection
  └ 행동 코루틴 5종 (아래)
```

### A.2 행동 코루틴 ↔ `T_AI_CHARACTER` 파라미터 매핑
| 코루틴 | 동작 | 사용 파라미터 |
|---|---|---|
| `co_SearchTarget` | 사거리 내 적 탐색 | `searchDistance`, `reactionsSearchTarget` |
| `co_CheckCombatLink` | 현재 타깃 유효/시야 유지 검증, 교체 | `combatDistance`, `reactionsChangeTarget` (`<>m__0(Player)` = 타깃 필터) |
| `co_MoveProcess` | NavMesh로 접근/유지 | `minDistance`(너무 붙지 않음), `reactionsMove` |
| `co_CheckNearEnermy` | 근접 적 감지(백병/회피 전환) | `minDistance` |
| `co_Attack` | 사격 | `shotMin~shotMax`(버스트 길이), `shootingDelayMin~Max`(간격), `reactionsAttack`(교전 반응) |

### A.3 회피(스트레이프) — `eAvoidDirection`
FORWARD_LEFT, FORWARD_RIGHT, CENTER_LEFT, CENTER_RIGHT, BACK_LEFT, BACK_RIGHT, BACK_LEFT2 (7방향)
- `avoidCheckTime`마다 `avoidRate` 확률로 회피 실행, `avoidCount`만큼 지그재그.
- `CheckM67Explosion` → 수류탄 폭발 반경 감지 시 반대 방향으로 회피.

### A.4 난이도 설계 (`T_AI_LEVEL`)
- `level → minID~maxID` 범위의 `T_AI_CHARACTER` 풀에서 봇 선발.
- **난이도의 본질 = 반응시간 4종**: 값↓ → 즉각 조준/추적 = 고수봇. 값↑ → 굼뜬 봇.
- 보조 축: `searchDistance`(시야), `shootingDelay`(DPS), `avoidRate`(생존력), `weaponExp/charExp`(장비 파워).

### A.5 새 게임 적용
- 봇 1체 = `{HP/속도(캐릭터), 무기3, 반응4, 거리3, 버스트2, 회피3}` 파라미터 세트.
- 상태머신: `SEARCH → (타깃) → MOVE(교전거리 유지) → ATTACK(버스트+딜레이) ↔ AVOID(스트레이프)`, 죽으면 `co_CheckDead`.
- NavMesh 경로탐색 그대로 사용. PvE 적(`PlayerMonster`)보다 정교(엄폐/회피/타깃전환).

---

## B. 무기 옵션/강화 시스템 (`TYPE_WEAPON_OPTION_EFFECT`)

### B.1 전체 옵션 목록 (슬롯 분리형)
| 그룹 | 옵션 |
|---|---|
| 탄약 | WE_BULLET_MAX, WE_BULLET_CNT_PRIMARY/SECOND, WE_BULLET_TOTAL_PRIMARY/SECOND |
| 연사 | WE_SPEED_SHOT_PRIMARY/SECOND |
| 데미지 | WE_DAMAGE_MIN_PRIMARY/SECOND/KNIFE, WE_DAMAGE_MAX_PRIMARY/SECOND/KNIFE |
| 명중 | WE_AIM_INIT_PRIMARY/SECOND, WE_AIM_PLUS_PRIMARY/SECOND |
| 치명타 | WE_CRITICAL_PRIMARY/SECOND/KNIFE |
| 반동 | WE_REACTION_PRIMARY/SECOND |
| 무게 | WE_WEIGHT |
| 캐릭터 버프 | WE_SPEED, WE_HP, WE_AVOID, WE_GRENADE_POWER, WE_RAGE_POWER |

### B.2 적용 로직 (`WeaponManager`)
```
apply_WeaponOptionEffect(Player, type, value, isPVE)   // 단일 적용
AddEffectValuePercent(target, value, type, IsRound)    // target * (1 + value%)  (int/float 오버로드)
GetWeaponOptionEffectAll(List<M_WEAPON>) : Dict<type,float>  // 장착 무기 옵션 합산
IsExcludeOptionMode(type)                              // 모드별 옵션 제외
get_WeaponOptionEffect_RAGE_POWER(Player)              // 분노(연속킬?) 특수
```
- 옵션 = **% 가산 버프**. 무기별 옵션 슬롯 `_EFFECT_1..5`(`T_WEAPON_OPTION_DATA`) + 레벨값(`T_WEAPON_EFFECT{TYPE,VALUE}`).
- 소유 무기 `M_WEAPON.OPTION_ID[]`로 어떤 옵션이 붙었는지 기록.

### B.3 새 게임 적용
- 무기 커스터마이즈 = "슬롯에 옵션칩 장착 → 해당 스탯 %↑". MVP는 생략 가능, 확장 시 강력한 성장축.

---

## C. 좀비2 모드 (인간 vs 좀비 비대칭 PvP)

### C.1 구성 클래스
- `PlayerZombie` — 좀비화 플레이어, `PlayerZombieSlayer` — 인간 슬레이어(특수).
- `ZombieLordSkillObj` / `ZombieLordSkill_Smog` / `POOL_ZombieLordSkillObj` — 좀비로드 광역 스킬(연막/범위).
- `Player.simulateZombieSlayerSkill` (코루틴) — 슬레이어 스킬.

### C.2 규칙 (`M_ZOMBIE_2_CONFIG`)
- **진영 전환**: 인간 N명 중(`HUMAN_COUNT_TO_SELECT_ZOMBIE_SLAYER`) 슬레이어 선발, `ZOMBIE_SLAYER_SELECT_TIME` 내.
- **슬레이어**: 기본무기/스킬무기, 스킬 쿨 `ZOMBIE_SLAYER_SKILL_COOL_TIME`.
- **좀비로드 스킬**: 반경 `RADIUS`, 속도/사거리 `RANGE`, 연막 `SMOG_TIME`/`SMOG_COLLIDER_TIME`, 데미지 `ZOMBIE_LOAD_SKILL_DAMAGE`, 쿨 `LORD_SKILL_COOL_TIME`.
- **버프**: 속도업 값/시간(`BUFF_SPD_UP_*`).
- **거점**: 생화학폐기물 스폰(횟수 `BIOCHEMICALWASTES_SPAWN_COUNT`, 타이밍 `SETTING_TIMES`, 획득 `GETTING_TIME`), HUD 표시 거리.
- 리스폰 `CHARACTER_RESPAWN_TIME`, 최대 플레이 `MAX_PLAYTIME`.

### C.3 흐름
`라운드 시작 → 슬레이어 선발 → 좀비 감염 확산(접촉) → 인간 생존 or 전원 감염 → 좀비로드 각성(광역스킬)`

---

## D. PVE_NET_2 (호드 서바이벌, 협동)

### D.1 클래스
- `U_PVE_NET_2` (Singleton) — 모드 컨트롤러, `U_PVE_NET_2_Result` — 결과.
- `U_PointShop_PVE_2` (Singleton) — **인게임 포인트 상점**, `UpdateBarricadeInfo`(코루틴) — 바리케이드.
- `M_PVENET2_INFO / _REWARD / _DATA`, `T_PVENET2_DATA`(진행 추적), `M_PVENET2_REWARD`(보상).

### D.2 루프
```
입장(맵+캐릭터+무기3) → 웨이브 반복:
  [전투: 몬스터 처치 → 포인트] → [준비: U_PointShop_PVE_2에서 강화 구매]
  강화: 공격/속도/HP/무기레벨(_ATK/_SPEED/_HP/_WP_INC) + 긴급치료 + 바리케이드 설치
클리어/전멸 → 결과 집계(_WAVE_COUNT/_KILL/_HEADSHOT/_TOTAL_DAMAGE/_DEATH) → 보상/기록
```
- 협동 요소(멀티): `_HEAL_COUNT`/`_TARGET_HEAL_COUNT`(아군 치료), `_REVIVE`(구버전 PVENET), `_BARRICADE`(공용 방어물).
- **솔로化**: 치료/부활/바리케이드는 본인용으로 축소하면 1인 플레이 완결(= MVP).

### D.3 PvE 적 소환 (`T_LEVEL` + `PlayerMonster`)
- `T_LEVEL{TYPE,LEVEL,POS,COUNT,TIME,list_monster}` = 웨이브별 스폰 스케줄.
- 적 `PlayerMonster`: NavMeshAgent 추적 + `ATTACK_DISTANCE` 교전 + `setDead(shooter,isHead)` 헤드샷.
- 좀비 5종(`PVE_ZOMBIE_TYPE`) / 공룡 6종(`PVE_DINO_TYPE`, MORDRED=보스) / 공격타입 3종.

---

## E. 복원된 전투 수식 구조 (#1 요약)

> 정확한 매직넘버는 난독화(Obscured*)·서버측이라 유실. **결합 구조**만 복원 → 수치는 재밸런싱.

- **점프(수동 2단, `Player.update_Move`)**: 상승기 `height += move_jump_up`(→Max_height), 하강기 `down_add += move_jump_down; height -= down_add`(중력적분), 수평 `move_jump_speed`. 상수 `move_jump`/`move_gravity`는 정적영역 로드.
- **데미지(`callShot`→`setHitMonster/setHitTarget`)**: `Random(MIN,MAX) → ×헤드샷 → ×치명타(prob _CRITICAL) → ×(1+옵션%) → 방어/약점 보정`. 헤드 판정 = `isHead`(히트박스 t_head).
- **동적 정확도(`update_Shot`)**: `spread = AIM_INIT + m_nNoShotCount×k`, 연사 중 증가/미사격 시 회복(`isShot`).
- **연사**: `SPEED_SHOT` 간격, 탄창 0 → `is_AutoReload`.
- **무게↔속도**: `_WEIGHT` ↑ → `MOVE_SPEED` 패널티.

---

## 부록: 분해 대상 클래스 색인 (`dump.cs`)
| 시스템 | 클래스 (라인) |
|---|---|
| 봇 매니저 | `BotManager`, `BotInfo`, `AIStateManager`(135046) |
| 봇 FSM | `FsmAiState`(135167), `AIHuman`(134859) + co_* |
| 봇 데이터 | `T_AI_CHARACTER`(135286), `T_AI_LEVEL`(135320), `AICharacterParser`/`AILEVELParser`(119628) |
| 무기 옵션 | `WeaponManager`(134256), `T_WEAPON_OPTION_DATA`(127463), `T_WEAPON_EFFECT`(127503) |
| 좀비2 | `PlayerZombie`(137157), `PlayerZombieSlayer`(137190), `ZombieLordSkillObj`(138159), `M_ZOMBIE_2_CONFIG`(126793) |
| PVE_NET_2 | `U_PVE_NET_2`(139972), `U_PointShop_PVE_2`(139920), `T_PVENET2_DATA`(140116) |
| PvE 적 | `PlayerMonster`(136709), `T_LEVEL`(159351) |
