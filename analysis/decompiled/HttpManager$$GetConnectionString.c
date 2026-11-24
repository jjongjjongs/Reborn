// HttpManager$$GetConnectionString @ RVA 0x1c8fe04

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void HttpManager__GetConnectionString(void)

{
  undefined8 uVar1;
  undefined8 uVar2;
  long *plVar3;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  if ((bRam0000000002c495e1 & 1) == 0) {
    func_0x01978cf8(0x3887);
    bRam0000000002c495e1 = 1;
  }
  uStack_28 = 0;
  uVar1 = CommonFunc__GetMarketCode(0);
  uStack_24 = CommonFunc__GetVersionCode(0);
  uVar2 = func_0x01487aa4(&uStack_24,0);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar1 = System_String__Concat(_StringLiteral_6197,uVar1,uVar2,0);  /* "SPECIAL" */
  uStack_28 = UnityEngine_Animator__StringToHash(uVar1,0);
  plVar3 = (long *)func_0x01487b20(&uStack_28,_StringLiteral_4582,0);  /* "x8" */
  if (plVar3 == (long *)0x0) {
    func_0x019a516c();
  }
  (**(code **)(*plVar3 + 0x158))(plVar3,*(undefined8 *)(*plVar3 + 0x160));
  return;
}
