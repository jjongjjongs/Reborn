// Wellgames.Utils.GLLPHABKNEO$$NNLLEHJOGGB @ RVA 0x1cbb804

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Wellgames_Utils_GLLPHABKNEO__NNLLEHJOGGB(long param_1)

{
  undefined4 uVar1;
  long *plVar2;
  undefined8 uVar3;
  
  if ((bRam0000000002c49795 & 1) == 0) {
    func_0x01978cf8(0x315c);
    bRam0000000002c49795 = 1;
  }
  if (param_1 == 0) {
    func_0x019a516c(0);
  }
  uVar1 = System_String__get_Length(param_1,0);
  func_0x019b9d20(_DAT_02bf5608,uVar1);
  if (((*(byte *)(_DAT_02bf56a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf56a0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  plVar2 = (long *)System_Text_Encoding__get_UTF8(0);
  if (plVar2 == (long *)0x0) {
    func_0x019a516c(0);
  }
  uVar3 = (**(code **)(*plVar2 + 0x1c8))(plVar2,param_1,*(undefined8 *)(*plVar2 + 0x1d0));
  if (((*(byte *)(_DAT_02bf55c0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf55c0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  System_Convert__ToBase64String(uVar3,0);
  return;
}
