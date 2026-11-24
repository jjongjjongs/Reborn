// U_Logo$$PM_SetConnectionString @ RVA 0x1c33518

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1  [16] U_Logo__PM_SetConnectionString(long param_1)

{
  long *plVar1;
  int iVar2;
  code *pcVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  undefined8 uVar6;
  undefined8 uVar7;
  undefined8 uVar8;
  long lVar9;
  undefined8 uVar10;
  long lVar11;
  undefined8 *puVar12;
  long lVar13;
  undefined1 auVar14 [16];
  
  if ((bRam0000000002c49317 & 1) == 0) {
    func_0x01978cf8(0x8c8e);
    bRam0000000002c49317 = 1;
  }
  if ((*(char *)(param_1 + 0x20) != '\0') && (*(char *)(param_1 + 0x21) != '\0')) {
    lVar11 = *(long *)(param_1 + 0x28);
    if (lVar11 == 0) {
      func_0x019a516c(0);
    }
    lVar11 = UnityEngine_Component__get_gameObject(lVar11,0);
    if (lVar11 == 0) {
      func_0x019a516c();
    }
    if (pcRam0000000002bebfc0 == (code *)0x0) {
      pcVar3 = (code *)func_0x019d73a0(&UNK_020d1ed7);
      if (pcVar3 == (code *)0x0) {
        uVar4 = func_0x019a6604(&UNK_020d1ed7);
        func_0x019a50dc(uVar4,0,0);
      }
      pcRam0000000002bebfc0 = pcVar3;
    }
                    /* WARNING: Could not recover jumptable at 0x0132477c. Too many branches */
                    /* WARNING: Treating indirect jump as call */
    auVar14 = (*pcRam0000000002bebfc0)(lVar11,1);
    return auVar14;
  }
  lVar11 = func_0x00f2d1ac(_DAT_02c27490);
  if (lVar11 == 0) {
    func_0x019a516c();
  }
  U_LoadingBar__View(lVar11,1,0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  HttpManager__SetDefaultUrl(5,0);
  uVar4 = HttpManager__GetConnectionSendInfo(0);
  uVar5 = func_0x019b4464(_DAT_02bfcef0);
  func_0x00e8958c(uVar5,param_1,_DAT_02c25220,_DAT_02c190a8);
  if ((bRam0000000002c495de & 1) == 0) {
    func_0x01978cf8(0x38b6,uVar5,0);
    bRam0000000002c495de = 1;
  }
  lVar11 = func_0x019b4464(_DAT_02bfda20);
  System_Object___ctor(lVar11,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  *(undefined8 *)(lVar11 + 0x10) = uVar5;
  uVar5 = func_0x019b4464(_DAT_02bfcef0);
  func_0x00e8958c(uVar5,lVar11,_DAT_02c14a78,_DAT_02c190a8);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar10 = _StringLiteral_6242;  /* "connection_string" */
  if ((bRam0000000002c4953c & 1) == 0) {
    func_0x01978cf8(0x38ef);
    bRam0000000002c4953c = 1;
  }
  lVar11 = func_0x019b4464(_DAT_02bfd598);
  System_Object___ctor(lVar11,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
    uRam0000000000000010 = uVar5;
    func_0x019a516c(0);
    uRam0000000000000018 = uVar10;
    func_0x019a516c(0);
    uVar10 = uRam0000000000000018;
  }
  else {
    *(undefined8 *)(lVar11 + 0x10) = uVar5;
    *(undefined8 *)(lVar11 + 0x18) = uVar10;
  }
  uVar5 = func_0x019b4464(_DAT_02bfd588);
  func_0x00e7f97c(uVar5,lVar11,_DAT_02c14bc8,_DAT_02c189f0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  if ((bRam0000000002c49539 & 1) == 0) {
    func_0x01978cf8(0x3921);
    bRam0000000002c49539 = 1;
  }
  lVar11 = func_0x019b4464(_DAT_02bfd570);
  HttpManager_<WWW_Response>c__AnonStorey4___ctor(lVar11,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
    puVar12 = (undefined8 *)0x10;
    uRam0000000000000010 = uVar10;
    func_0x019a516c(0);
  }
  else {
    puVar12 = (undefined8 *)(lVar11 + 0x10);
    *puVar12 = uVar10;
  }
  *(undefined8 *)(lVar11 + 0x18) = uVar5;
  lVar9 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  uVar10 = *puVar12;
  uVar5 = func_0x019b4464(_DAT_02bfd578);
  cbHttpDelegate___ctor(uVar5,lVar11,_DAT_02c14d50,0);
  if (lVar9 == 0) {
    func_0x019a516c(0);
  }
  if ((bRam0000000002c4952c & 1) == 0) {
    func_0x01978cf8(0x3891);
    bRam0000000002c4952c = 1;
  }
  lVar11 = func_0x019b4464(_DAT_02bfd130);
  Newtonsoft_Json_JsonSerializerSettings___ctor(lVar11,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  Newtonsoft_Json_JsonSerializerSettings__set_NullValueHandling(lVar11,1,0);
  if (((*(byte *)(_DAT_02bfd078 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfd078 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar4 = Newtonsoft_Json_JsonConvert__SerializeObject(uVar4,0,lVar11,0);
  if ((bRam0000000002c4952d & 1) == 0) {
    func_0x01978cf8(0x3890);
    bRam0000000002c4952d = 1;
  }
  lVar11 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar11 == 0) {
    func_0x019a516c();
  }
  iVar2 = *(int *)(lVar11 + 0x48);
  lVar11 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar11 == 0) {
    func_0x019a516c();
  }
  plVar1 = (long *)(lVar11 + 0x20);
  if (iVar2 != 1) {
    plVar1 = (long *)(lVar11 + 0x18);
  }
  lVar11 = *plVar1;
  uVar4 = HttpManager__ToWebRequestJson(lVar9,uVar10,uVar4);
  lVar13 = *(long *)(lVar9 + 0x18);
  if (lVar13 == 0) {
    func_0x019a516c(0);
  }
  *(undefined8 *)(lVar13 + 0x40) = uVar5;
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  uVar6 = M_CONFIG__get_guid(lVar11,0);
  uVar6 = Wellgames_Utils_DDJFIIMGIMP__BHANOEGMLLE(uVar6,uVar4,0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bfcec0);
  }
  uVar7 = HttpManager__GetUrl();
  uVar8 = HttpManager__GetProtocol(lVar9,uVar10);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar7 = System_String__Concat(uVar7,uVar8,0);
  HttpManager__Post(lVar9,uVar7,uVar10,uVar6,uVar5);
  uVar4 = System_String__Concat(_StringLiteral_6201,uVar10,_StringLiteral_782,uVar4,0);  /* "[DEBUG-HTTP] SEND:", "," */
  auVar14._8_8_ = uVar4;
  auVar14._0_8_ = 1;
  return auVar14;
}
