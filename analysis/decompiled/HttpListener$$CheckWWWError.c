// HttpListener$$CheckWWWError @ RVA 0x1c80bd0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long HttpListener__CheckWWWError(undefined8 param_1,undefined8 param_2,uint param_3)

{
  ulong uVar1;
  long lVar2;
  long lVar3;
  undefined8 uVar4;
  
  if ((bRam0000000002c49526 & 1) == 0) {
    func_0x01978cf8(0x3874);
    bRam0000000002c49526 = 1;
  }
  if ((param_3 & 1) == 0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar1 = System_String__IsNullOrEmpty(param_2,0);
    if (((uVar1 & 1) == 0) && (uVar1 = HttpListener__IsJson(param_2), (uVar1 & 1) != 0)) {
      return 0;
    }
  }
  uVar4 = _StringLiteral_6190;  /* "웹서버 시스템 에러" */
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
    uVar4 = _StringLiteral_6190;  /* "웹서버 시스템 에러" */
  }
  _StringLiteral_6190 = uVar4;  /* "웹서버 시스템 에러" */
  if ((param_3 & 1) == 0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar1 = System_String__IsNullOrEmpty(param_2,0);
    uVar4 = _StringLiteral_6191;  /* "서버로 부터 데이터가 없습니다" */
    if ((uVar1 & 1) == 0) {
      uVar4 = param_2;
    }
  }
  lVar2 = func_0x019b4464(_DAT_02bfd540);
  M_WEB_RESPONSE___ctor(lVar2,0);
  if (lVar2 == 0) {
    func_0x019a516c(0);
    uRam0000000000000010 = param_1;
    func_0x019a516c(0);
  }
  else {
    *(undefined8 *)(lVar2 + 0x10) = param_1;
  }
  *(undefined4 *)(lVar2 + 0x18) = 0;
  lVar3 = func_0x019b4464(_DAT_02bfd548);
  M_ERROR___ctor(lVar3,0);
  if (lVar3 == 0) {
    func_0x019a516c(0);
    uRam0000000000000010 = CONCAT44(uRam0000000000000010._4_4_,0xffffffff);
    func_0x019a516c(0);
    uRam0000000000000020 = uVar4;
    func_0x019a516c(0);
  }
  else {
    *(undefined4 *)(lVar3 + 0x10) = 0xffffffff;
    *(undefined8 *)(lVar3 + 0x20) = uVar4;
  }
  *(undefined8 *)(lVar3 + 0x18) = _StringLiteral_6192;  /* "NOW_CANT_JOIN_TO_SERVER" */
  if (((*(byte *)(_DAT_02bfc440 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc440 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar4 = MyJson__Serialize(lVar3,0);
  *(undefined8 *)(lVar2 + 0x20) = uVar4;
  return lVar2;
}
