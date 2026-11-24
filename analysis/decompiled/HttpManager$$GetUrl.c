// HttpManager$$GetUrl @ RVA 0x1c799d0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 HttpManager__GetUrl(void)

{
  if ((bRam0000000002c495e4 & 1) == 0) {
    func_0x01978cf8(0x388b);
    bRam0000000002c495e4 = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  return *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x38);
}
