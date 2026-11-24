// HttpManager$$WWW_CONNECTION_STRING @ RVA 0x1c8faf4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1  [16] HttpManager__WWW_CONNECTION_STRING(undefined8 param_1,undefined8 param_2)

{
  long *plVar1;
  int iVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  undefined8 uVar6;
  long lVar7;
  long lVar8;
  undefined8 uVar9;
  undefined8 uVar10;
  undefined8 *puVar11;
  long lVar12;
  undefined1 auVar13 [16];
  
  if ((bRam0000000002c495de & 1) == 0) {
    func_0x01978cf8(0x38b6);
    bRam0000000002c495de = 1;
  }
  lVar8 = func_0x019b4464(_DAT_02bfda20);
  System_Object___ctor(lVar8,0);
  if (lVar8 == 0) {
    func_0x019a516c(0);
  }
  *(undefined8 *)(lVar8 + 0x10) = param_2;
  uVar9 = func_0x019b4464(_DAT_02bfcef0);
  func_0x00e8958c(uVar9,lVar8,_DAT_02c14a78,_DAT_02c190a8);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar10 = _StringLiteral_6242;  /* "connection_string" */
  if ((bRam0000000002c4953c & 1) == 0) {
    func_0x01978cf8(0x38ef);
    bRam0000000002c4953c = 1;
  }
  lVar8 = func_0x019b4464(_DAT_02bfd598);
  System_Object___ctor(lVar8,0);
  if (lVar8 == 0) {
    func_0x019a516c(0);
    uRam0000000000000010 = uVar9;
    func_0x019a516c(0);
    uRam0000000000000018 = uVar10;
    func_0x019a516c(0);
    uVar10 = uRam0000000000000018;
  }
  else {
    *(undefined8 *)(lVar8 + 0x10) = uVar9;
    *(undefined8 *)(lVar8 + 0x18) = uVar10;
  }
  uVar9 = func_0x019b4464(_DAT_02bfd588);
  func_0x00e7f97c(uVar9,lVar8,_DAT_02c14bc8,_DAT_02c189f0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  if ((bRam0000000002c49539 & 1) == 0) {
    func_0x01978cf8(0x3921);
    bRam0000000002c49539 = 1;
  }
  lVar8 = func_0x019b4464(_DAT_02bfd570);
  HttpManager_<WWW_Response>c__AnonStorey4___ctor(lVar8,0);
  if (lVar8 == 0) {
    func_0x019a516c(0);
    puVar11 = (undefined8 *)0x10;
    uRam0000000000000010 = uVar10;
    func_0x019a516c(0);
  }
  else {
    puVar11 = (undefined8 *)(lVar8 + 0x10);
    *puVar11 = uVar10;
  }
  *(undefined8 *)(lVar8 + 0x18) = uVar9;
  lVar7 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar8 == 0) {
    func_0x019a516c(0);
  }
  uVar10 = *puVar11;
  uVar9 = func_0x019b4464(_DAT_02bfd578);
  cbHttpDelegate___ctor(uVar9,lVar8,_DAT_02c14d50,0);
  if (lVar7 == 0) {
    func_0x019a516c(0);
  }
  if ((bRam0000000002c4952c & 1) == 0) {
    func_0x01978cf8(0x3891);
    bRam0000000002c4952c = 1;
  }
  lVar8 = func_0x019b4464(_DAT_02bfd130);
  Newtonsoft_Json_JsonSerializerSettings___ctor(lVar8,0);
  if (lVar8 == 0) {
    func_0x019a516c(0);
  }
  Newtonsoft_Json_JsonSerializerSettings__set_NullValueHandling(lVar8,1,0);
  if (((*(byte *)(_DAT_02bfd078 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfd078 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar3 = Newtonsoft_Json_JsonConvert__SerializeObject(param_1,0,lVar8,0);
  if ((bRam0000000002c4952d & 1) == 0) {
    func_0x01978cf8(0x3890);
    bRam0000000002c4952d = 1;
  }
  lVar8 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar8 == 0) {
    func_0x019a516c();
  }
  iVar2 = *(int *)(lVar8 + 0x48);
  lVar8 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar8 == 0) {
    func_0x019a516c();
  }
  plVar1 = (long *)(lVar8 + 0x20);
  if (iVar2 != 1) {
    plVar1 = (long *)(lVar8 + 0x18);
  }
  lVar8 = *plVar1;
  uVar3 = HttpManager__ToWebRequestJson(lVar7,uVar10,uVar3);
  lVar12 = *(long *)(lVar7 + 0x18);
  if (lVar12 == 0) {
    func_0x019a516c(0);
  }
  *(undefined8 *)(lVar12 + 0x40) = uVar9;
  if (lVar8 == 0) {
    func_0x019a516c(0);
  }
  uVar4 = M_CONFIG__get_guid(lVar8,0);
  uVar4 = Wellgames_Utils_DDJFIIMGIMP__BHANOEGMLLE(uVar4,uVar3,0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bfcec0);
  }
  uVar5 = HttpManager__GetUrl();
  uVar6 = HttpManager__GetProtocol(lVar7,uVar10);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar5 = System_String__Concat(uVar5,uVar6,0);
  HttpManager__Post(lVar7,uVar5,uVar10,uVar4,uVar9);
  uVar9 = System_String__Concat(_StringLiteral_6201,uVar10,_StringLiteral_782,uVar3,0);  /* "[DEBUG-HTTP] SEND:", "," */
  auVar13._8_8_ = uVar9;
  auVar13._0_8_ = 1;
  return auVar13;
}
