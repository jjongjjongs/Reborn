// HttpListener$$CheckError @ RVA 0x1c8089c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long HttpListener__CheckError(undefined8 param_1,undefined8 param_2,uint param_3)

{
  long lVar1;
  long lVar2;
  undefined8 uVar3;
  
  if ((bRam0000000002c49528 & 1) == 0) {
    func_0x01978cf8(0x3873);
    bRam0000000002c49528 = 1;
  }
  lVar1 = HttpListener__CheckWWWError(param_1,param_2,param_3 & 1);
  if (lVar1 == 0) {
    if (((*(byte *)(_DAT_02bfc440 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc440 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar1 = func_0x00fd4edc(param_2,_DAT_02c26cb0);
    if (lVar1 == 0) {
      lVar1 = func_0x019b4464(_DAT_02bfd540);
      M_WEB_RESPONSE___ctor(lVar1,0);
      if (lVar1 == 0) {
        func_0x019a516c(0);
        uRam0000000000000010 = param_1;
        func_0x019a516c(0);
      }
      else {
        *(undefined8 *)(lVar1 + 0x10) = param_1;
      }
      *(undefined4 *)(lVar1 + 0x18) = 0;
      lVar2 = func_0x019b4464(_DAT_02bfd548);
      M_ERROR___ctor(lVar2,0);
      if (lVar2 == 0) {
        func_0x019a516c(0);
      }
      *(undefined4 *)(lVar2 + 0x10) = 0xfffffffe;
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar3 = System_String__Concat(_StringLiteral_6188,param_2,0);  /* "응답 데이터 오류:" */
      *(undefined8 *)(lVar2 + 0x20) = uVar3;
      *(undefined8 *)(lVar2 + 0x18) = _StringLiteral_6189;  /* "#WEB_180" */
      if (((*(byte *)(_DAT_02bfc440 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc440 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar3 = MyJson__Serialize(lVar2,0);
      *(undefined8 *)(lVar1 + 0x20) = uVar3;
    }
  }
  return lVar1;
}
