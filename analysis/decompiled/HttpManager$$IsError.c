// HttpManager$$IsError @ RVA 0x1c82354

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 HttpManager__IsError(undefined8 param_1,long *param_2,undefined8 param_3)

{
  long lVar1;
  undefined8 uVar2;
  ulong uVar3;
  
  if ((bRam0000000002c49537 & 1) == 0) {
    func_0x01978cf8(0x388d);
    bRam0000000002c49537 = 1;
  }
  if (param_2 == (long *)0x0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar3 = System_String__IsNullOrEmpty(param_3,0);
    if ((uVar3 & 1) == 0) {
      return 0;
    }
    lVar1 = func_0x00f2d1ac(_DAT_02c27528);
    if (lVar1 == 0) {
      func_0x019a516c();
    }
    uVar2 = _StringLiteral_6200;  /* "json IsNullOrEmpty" */
  }
  else {
    lVar1 = func_0x00f2d1ac(_DAT_02c27528);
    uVar2 = (**(code **)(*param_2 + 0x158))(param_2,*(undefined8 *)(*param_2 + 0x160));
    if (lVar1 == 0) {
      func_0x019a516c(0);
    }
  }
  U_Message__View(0,lVar1,uVar2,0,0);
  return 1;
}
