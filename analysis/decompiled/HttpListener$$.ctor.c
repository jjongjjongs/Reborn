// HttpListener$$.ctor @ RVA 0x1c807b8

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1  [16] HttpListener___ctor(ulong param_1)

{
  undefined1 auVar1 [16];
  
  if ((bRam0000000002c49523 & 1) == 0) {
    func_0x01978cf8(0x387f);
    bRam0000000002c49523 = 1;
  }
  if (param_1 == 0) {
    func_0x019a516c(0,_DAT_02c18280);
  }
  if ((bRam0000000002bebd70 & 1) == 0) {
    func_0x01978cf8(0x19ba,0);
    bRam0000000002bebd70 = 1;
  }
  if (((*(byte *)(_DAT_02bf82e0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf82e0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  auVar1._8_8_ = 0;
  auVar1._0_8_ = param_1;
  return auVar1;
}
