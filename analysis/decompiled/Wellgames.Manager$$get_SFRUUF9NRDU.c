// Wellgames.Manager$$get_SFRUUF9NRDU @ RVA 0x1d410f4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 Wellgames_Manager__get_SFRUUF9NRDU(void)

{
  long lVar1;
  
  if ((bRam0000000002c49c42 & 1) == 0) {
    func_0x01978cf8(0x4e82);
    bRam0000000002c49c42 = 1;
  }
  lVar1 = func_0x00f2d1ac(_DAT_02c27718);
  if (lVar1 == 0) {
    func_0x019a516c();
  }
  lVar1 = *(long *)(lVar1 + 0x18);
  if (lVar1 == 0) {
    func_0x019a516c(0);
  }
  return *(undefined8 *)(lVar1 + 0x18);
}
