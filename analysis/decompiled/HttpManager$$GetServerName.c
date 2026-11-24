// HttpManager$$GetServerName @ RVA 0x1c90290

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long HttpManager__GetServerName(void)

{
  undefined8 uVar1;
  ulong uVar2;
  long lVar3;
  undefined8 uVar4;
  long lVar5;
  
  if ((bRam0000000002c495e7 & 1) == 0) {
    func_0x01978cf8(0x388a);
    bRam0000000002c495e7 = 1;
  }
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar4 = *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x38);
  uVar1 = Wellgames_Data__GIJBACLFCAD(_StringLiteral_1400,0);  /* "DEFAULT" */
  uVar2 = System_String__op_Equality(uVar4,uVar1,0);
  if ((uVar2 & 1) == 0) {
    if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar5 = *(long *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x38);
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    uVar1 = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
    if (lVar5 == 0) {
      func_0x019a516c(0);
    }
    lVar5 = System_String__Replace(lVar5,_StringLiteral_6199,uVar1,0);  /* "http://fps." */
    lVar3 = func_0x019b9d20(_DAT_02bf56f8,1);
    if (lVar3 == 0) {
      func_0x019a516c();
    }
    if (*(int *)(lVar3 + 0x18) == 0) {
      uVar1 = func_0x019a5e50();
      func_0x019a50dc(uVar1,0,0);
    }
    *(undefined2 *)(lVar3 + 0x20) = 0x2e;
    if (lVar5 == 0) {
      func_0x019a516c(0);
    }
    lVar3 = System_String__Split(lVar5,lVar3,0);
    if (lVar3 == 0) {
      func_0x019a516c();
    }
    if (0 < *(int *)(lVar3 + 0x18)) {
      lVar5 = *(long *)(lVar3 + 0x20);
    }
  }
  else {
    lVar5 = _StringLiteral_6198;  /* "live" */
  }
  return lVar5;
}
