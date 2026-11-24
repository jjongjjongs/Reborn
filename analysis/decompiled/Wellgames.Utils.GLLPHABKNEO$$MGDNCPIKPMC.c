// Wellgames.Utils.GLLPHABKNEO$$MGDNCPIKPMC @ RVA 0x1cbb330

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

bool Wellgames_Utils_GLLPHABKNEO__MGDNCPIKPMC(undefined8 param_1,undefined8 param_2)

{
  int iVar1;
  undefined8 uVar2;
  long *plVar3;
  
  if ((bRam0000000002c4978f & 1) == 0) {
    func_0x01978cf8(0x315b);
    bRam0000000002c4978f = 1;
  }
  uVar2 = Wellgames_Utils_GLLPHABKNEO__ADKLEGDDFNO(param_1);
  if (((*(byte *)(_DAT_02bf5c38 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5c38 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5c38);
  }
  plVar3 = (long *)System_StringComparer__get_OrdinalIgnoreCase(0);
  if (plVar3 == (long *)0x0) {
    func_0x019a516c();
  }
  iVar1 = (**(code **)(*plVar3 + 0x1c8))(plVar3,uVar2,param_2,*(undefined8 *)(*plVar3 + 0x1d0));
  return iVar1 == 0;
}
