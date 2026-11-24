// HttpManager$$NonHeaderProtocol @ RVA 0x1c81a2c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1  [16] HttpManager__NonHeaderProtocol(long param_1,undefined8 param_2,undefined8 param_3)

{
  undefined8 uVar1;
  long lVar2;
  undefined8 uVar3;
  undefined1 auVar4 [16];
  
  if ((bRam0000000002c4952e & 1) == 0) {
    func_0x01978cf8(0x388f);
    bRam0000000002c4952e = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar3 = *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x38);
  uVar1 = Wellgames_Utils_DDJFIIMGIMP__FDGFONJFBAJ(0);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar1 = System_String__Concat(uVar3,uVar1,0);
  lVar2 = func_0x019b4464(_DAT_02bfd550);
  M_WEB_REQUEST___ctor(lVar2,0);
  if (lVar2 == 0) {
    func_0x019a516c(0);
    uRam0000000000000030 = param_2;
    func_0x019a516c(0);
  }
  else {
    *(undefined8 *)(lVar2 + 0x30) = param_2;
  }
  *(undefined8 *)(lVar2 + 0x40) = param_3;
  *(long *)(param_1 + 0x18) = lVar2;
  HttpManager__Post(param_1,uVar1,param_2,0,param_3);
  uVar1 = System_String__Concat(_StringLiteral_6201,uVar1,0);  /* "[DEBUG-HTTP] SEND:" */
  auVar4._8_8_ = uVar1;
  auVar4._0_8_ = 1;
  return auVar4;
}
