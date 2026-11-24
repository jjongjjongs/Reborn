// HttpListener$$GetError @ RVA 0x1c80a2c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 HttpListener__GetError(long param_1)

{
  ulong uVar1;
  long *plVar2;
  long lVar3;
  undefined8 uVar4;
  
  if ((bRam0000000002c49525 & 1) == 0) {
    func_0x01978cf8(0x387b);
    bRam0000000002c49525 = 1;
  }
  if (param_1 != 0) {
    uVar4 = *(undefined8 *)(param_1 + 0x20);
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar1 = System_String__IsNullOrEmpty(uVar4,0);
    if ((uVar1 & 1) != 0) {
      return 0;
    }
    if (*(int *)(param_1 + 0x18) == -1) {
      uVar4 = *(undefined8 *)(param_1 + 0x20);
      if (((*(byte *)(_DAT_02bfc440 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc440 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      plVar2 = (long *)func_0x00fd4edc(uVar4,_DAT_02c26bc8);
      lVar3 = func_0x00f2d1ac(_DAT_02c27528);
      if (plVar2 == (long *)0x0) {
        func_0x019a516c(0);
      }
      uVar4 = (**(code **)(*plVar2 + 0x158))(plVar2,*(undefined8 *)(*plVar2 + 0x160));
      if (lVar3 == 0) {
        func_0x019a516c(0);
      }
      U_Message__View(0,lVar3,uVar4,0,0);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      *(undefined8 *)(param_1 + 0x20) = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
      return 0;
    }
    if (*(int *)(param_1 + 0x18) == 0) {
      uVar4 = *(undefined8 *)(param_1 + 0x20);
      if (((*(byte *)(_DAT_02bfc440 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc440 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar4 = func_0x00fd4edc(uVar4,_DAT_02c26bc8);
      return uVar4;
    }
  }
  return 0;
}
