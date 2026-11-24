// CommonFunc$$GetMarketCode @ RVA 0x1f2bee4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 CommonFunc__GetMarketCode(void)

{
  long *plVar1;
  undefined8 uVar2;
  undefined4 uStack_24;
  
  if ((bRam0000000002c4abad & 1) == 0) {
    func_0x01978cf8(0x18c9);
    bRam0000000002c4abad = 1;
  }
  uStack_24 = 0;
  plVar1 = (long *)func_0x019b43c8(_DAT_02bfd010,&uStack_24);
  if (plVar1 == (long *)0x0) {
    func_0x019a516c();
  }
  uVar2 = (**(code **)(*plVar1 + 0x158))(plVar1,*(undefined8 *)(*plVar1 + 0x160));
  if (plVar1 == (long *)0x0) {
    func_0x019a516c(0);
  }
  func_0x019b4908(plVar1);
  return uVar2;
}
