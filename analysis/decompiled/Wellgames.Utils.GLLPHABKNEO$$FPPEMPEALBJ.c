// Wellgames.Utils.GLLPHABKNEO$$FPPEMPEALBJ @ RVA 0x1cbc6a8

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Wellgames_Utils_GLLPHABKNEO__FPPEMPEALBJ(undefined8 param_1)

{
  long lVar1;
  long *plVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  uint uVar5;
  
  if ((bRam0000000002c4979d & 1) == 0) {
    func_0x01978cf8(0x3160);
    bRam0000000002c4979d = 1;
  }
  lVar1 = System_Security_Cryptography_MD5__Create(0);
  if (((*(byte *)(_DAT_02bf56a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf56a0 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf56a0);
  }
  plVar2 = (long *)System_Text_Encoding__get_UTF8(0);
  if (plVar2 == (long *)0x0) {
    func_0x019a516c();
  }
  uVar3 = (**(code **)(*plVar2 + 0x1c8))(plVar2,param_1,*(undefined8 *)(*plVar2 + 0x1d0));
  if (lVar1 == 0) {
    func_0x019a516c(0);
  }
  lVar1 = System_Security_Cryptography_HashAlgorithm__ComputeHash(lVar1,uVar3,0);
  plVar2 = (long *)func_0x019b4464(_DAT_02bf5698);
  System_Text_StringBuilder___ctor(plVar2,0);
  uVar5 = 0;
  while( true ) {
    if (lVar1 == 0) {
      func_0x019a516c(0);
    }
    if (*(int *)(lVar1 + 0x18) <= (int)uVar5) break;
    uVar3 = Wellgames_Manager__get_XFTUKF7IQVNIX1JFUExBQ0U(0);
    if (*(uint *)(lVar1 + 0x18) <= uVar5) {
      uVar4 = func_0x019a5e50();
      func_0x019a50dc(uVar4,0,0);
    }
    uVar3 = func_0x011cc814(lVar1 + (int)uVar5 + 0x20,uVar3,0);
    if (plVar2 == (long *)0x0) {
      func_0x019a516c(0);
    }
    System_Text_StringBuilder__Append(plVar2,uVar3,0);
    uVar5 = uVar5 + 1;
  }
  if (plVar2 == (long *)0x0) {
    func_0x019a516c(0);
  }
                    /* WARNING: Could not recover jumptable at 0x01db9a48. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (**(code **)(*plVar2 + 0x158))(plVar2,*(undefined8 *)(*plVar2 + 0x160));
  return;
}
