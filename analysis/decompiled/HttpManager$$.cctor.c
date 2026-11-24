// HttpManager$$.cctor @ RVA 0x1c904f4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void HttpManager___cctor(void)

{
  undefined8 uVar1;
  long lVar2;
  
  if ((bRam0000000002c495ec & 1) == 0) {
    func_0x01978cf8(0x3944);
    bRam0000000002c495ec = 1;
  }
  **(undefined8 **)(_DAT_02bfcec0 + 0xb8) = 0;
  *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 8) = 0;
  uVar1 = func_0x019b4464(_DAT_02bfda48);
  func_0x018651cc(uVar1,_DAT_02c1e1d8);
  lVar2 = _DAT_02bfcec0;
  *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x10) = uVar1;
  *(undefined8 *)(*(long *)(lVar2 + 0xb8) + 0x18) = 0;
  *(undefined8 *)(*(long *)(lVar2 + 0xb8) + 0x20) = _StringLiteral_6414;  /* "9AD1137B" */
  *(undefined8 *)(*(long *)(lVar2 + 0xb8) + 0x28) = _StringLiteral_6415;  /* "161e4ee1" */
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
    lVar2 = _DAT_02bfcec0;
  }
  *(undefined8 *)(*(long *)(lVar2 + 0xb8) + 0x30) = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  uVar1 = Wellgames_Data__GIJBACLFCAD(_StringLiteral_1400,0);  /* "DEFAULT" */
  lVar2 = _DAT_02bfcec0;
  *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x38) = uVar1;
  *(undefined1 *)(*(long *)(lVar2 + 0xb8) + 0x40) = 0;
  return;
}
