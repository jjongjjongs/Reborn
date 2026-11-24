// Wellgames.Utils.GLLPHABKNEO$$GBJCFAIMPIN @ RVA 0x1cbcdf8

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Wellgames_Utils_GLLPHABKNEO__GBJCFAIMPIN(undefined8 param_1)

{
  undefined4 uVar1;
  long *plVar2;
  long lVar3;
  undefined8 uVar4;
  
  if ((bRam0000000002c497a1 & 1) == 0) {
    func_0x01978cf8(0x3151);
    bRam0000000002c497a1 = 1;
  }
  plVar2 = (long *)func_0x019b4464(_DAT_02bf6c18);
  System_Text_UTF8Encoding___ctor(plVar2,0);
  if (plVar2 == (long *)0x0) {
    func_0x019a516c(0);
  }
  plVar2 = (long *)(**(code **)(*plVar2 + 0x238))(plVar2,*(undefined8 *)(*plVar2 + 0x240));
  if (((*(byte *)(_DAT_02bf55c0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf55c0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  lVar3 = System_Convert__FromBase64String(param_1,0);
  if (lVar3 == 0) {
    func_0x019a516c(0);
  }
  if (plVar2 == (long *)0x0) {
    func_0x019a516c(0);
  }
  uVar1 = (**(code **)(*plVar2 + 0x168))
                    (plVar2,lVar3,0,*(undefined4 *)(lVar3 + 0x18),*(undefined8 *)(*plVar2 + 0x170));
  uVar4 = func_0x019b9d20(_DAT_02bf56f8,uVar1);
  (**(code **)(*plVar2 + 0x178))
            (plVar2,lVar3,0,*(undefined4 *)(lVar3 + 0x18),uVar4,0,*(undefined8 *)(*plVar2 + 0x180));
  System_String__CreateString(0,uVar4,0);
  return;
}
