// HttpManager$$SetDefaultUrl @ RVA 0x1c900f4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void HttpManager__SetDefaultUrl(int param_1)

{
  long lVar1;
  undefined8 uVar2;
  undefined8 *puVar3;
  
  if ((bRam0000000002c495e5 & 1) == 0) {
    func_0x01978cf8(0x3899);
    bRam0000000002c495e5 = 1;
  }
  if (param_1 == 7) {
    puVar3 = (undefined8 *)&StringLiteral_1953;  /* "CHECK" */
  }
  else if (param_1 == 6) {
    puVar3 = (undefined8 *)&StringLiteral_5740;  /* "STAGE" */
  }
  else if (param_1 == 4) {
    lVar1 = func_0x00f2d1ac(_DAT_02c27248);
    if (lVar1 == 0) {
      func_0x019a516c();
    }
    if (*(int *)(lVar1 + 0x4c) == 4) {
      puVar3 = (undefined8 *)&StringLiteral_6204;  /* "DEV_GT" */
    }
    else {
      puVar3 = (undefined8 *)&StringLiteral_5741;  /* "DEV" */
    }
  }
  else {
    puVar3 = (undefined8 *)&StringLiteral_1400;  /* "DEFAULT" */
  }
  uVar2 = Wellgames_Data__GIJBACLFCAD(*puVar3,0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bfcec0);
  }
  *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x38) = uVar2;
  return;
}
