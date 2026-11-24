// HttpManager$$LoadProtocols @ RVA 0x1c90088

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void HttpManager__LoadProtocols(long param_1)

{
  long lVar1;
  undefined8 uVar2;
  
  if ((bRam0000000002c495eb & 1) == 0) {
    func_0x01978cf8(0x388e);
    bRam0000000002c495eb = 1;
  }
  lVar1 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar1 == 0) {
    func_0x019a516c();
  }
  uVar2 = DataManager__GetProtocols(lVar1,0);
  *(undefined8 *)(param_1 + 0x58) = uVar2;
  return;
}
