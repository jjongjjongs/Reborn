// Wellgames.Utils.GLLPHABKNEO$$OAINDKLODGG @ RVA 0x1cbb284

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 Wellgames_Utils_GLLPHABKNEO__OAINDKLODGG(undefined8 param_1,undefined8 param_2)

{
  undefined8 uVar1;
  long *plVar2;
  
  if ((bRam0000000002c4978e & 1) == 0) {
    func_0x01978cf8(0x315f);
    bRam0000000002c4978e = 1;
  }
  uVar1 = Wellgames_Utils_GLLPHABKNEO__FCJIFOHIPHH(param_1);
  if (((*(byte *)(_DAT_02bf5c38 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5c38 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5c38);
  }
  plVar2 = (long *)System_StringComparer__get_OrdinalIgnoreCase(0);
  if (plVar2 == (long *)0x0) {
    func_0x019a516c();
  }
  (**(code **)(*plVar2 + 0x1c8))(plVar2,uVar1,param_2,*(undefined8 *)(*plVar2 + 0x1d0));
  return 1;
}
