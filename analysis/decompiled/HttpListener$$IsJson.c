// HttpListener$$IsJson @ RVA 0x1c80dbc

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

uint HttpListener__IsJson(long param_1)

{
  uint uVar1;
  ulong uVar2;
  
  if ((bRam0000000002c49527 & 1) == 0) {
    func_0x01978cf8(0x387c);
    bRam0000000002c49527 = 1;
  }
  if (param_1 == 0) {
    uVar1 = 0;
  }
  else {
    uVar2 = System_String__IndexOf(param_1,_StringLiteral_1063,0);  /* "{" */
    uVar1 = (uint)(uVar2 >> 0x1f) & 1 ^ 1;
  }
  return uVar1;
}
