// HttpManager$$PostProtocol @ RVA 0x1c8169c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1  [16]
HttpManager__PostProtocol(long param_1,undefined8 param_2,undefined8 param_3,undefined8 param_4)

{
  long *plVar1;
  int iVar2;
  long lVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  undefined8 uVar6;
  undefined8 uVar7;
  long lVar8;
  undefined1 auVar9 [16];
  
  if ((bRam0000000002c4952c & 1) == 0) {
    func_0x01978cf8(0x3891);
    bRam0000000002c4952c = 1;
  }
  lVar3 = func_0x019b4464(_DAT_02bfd130);
  Newtonsoft_Json_JsonSerializerSettings___ctor(lVar3,0);
  if (lVar3 == 0) {
    func_0x019a516c(0);
  }
  Newtonsoft_Json_JsonSerializerSettings__set_NullValueHandling(lVar3,1,0);
  if (((*(byte *)(_DAT_02bfd078 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfd078 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar4 = Newtonsoft_Json_JsonConvert__SerializeObject(param_3,0,lVar3,0);
  if ((bRam0000000002c4952d & 1) == 0) {
    func_0x01978cf8(0x3890);
    bRam0000000002c4952d = 1;
  }
  lVar3 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar3 == 0) {
    func_0x019a516c();
  }
  iVar2 = *(int *)(lVar3 + 0x48);
  lVar3 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar3 == 0) {
    func_0x019a516c();
  }
  plVar1 = (long *)(lVar3 + 0x20);
  if (iVar2 != 1) {
    plVar1 = (long *)(lVar3 + 0x18);
  }
  lVar3 = *plVar1;
  uVar4 = HttpManager__ToWebRequestJson(param_1,param_2,uVar4);
  lVar8 = *(long *)(param_1 + 0x18);
  if (lVar8 == 0) {
    func_0x019a516c(0);
  }
  *(undefined8 *)(lVar8 + 0x40) = param_4;
  if (lVar3 == 0) {
    func_0x019a516c(0);
  }
  uVar5 = M_CONFIG__get_guid(lVar3,0);
  uVar5 = Wellgames_Utils_DDJFIIMGIMP__BHANOEGMLLE(uVar5,uVar4,0);
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bfcec0);
  }
  uVar6 = HttpManager__GetUrl();
  uVar7 = HttpManager__GetProtocol(param_1,param_2);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar6 = System_String__Concat(uVar6,uVar7,0);
  HttpManager__Post(param_1,uVar6,param_2,uVar5,param_4);
  uVar4 = System_String__Concat(_StringLiteral_6201,param_2,_StringLiteral_782,uVar4,0);  /* "[DEBUG-HTTP] SEND:", "," */
  auVar9._8_8_ = uVar4;
  auVar9._0_8_ = 1;
  return auVar9;
}
