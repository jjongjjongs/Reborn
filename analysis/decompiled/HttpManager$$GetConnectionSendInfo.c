// HttpManager$$GetConnectionSendInfo @ RVA 0x1c8fef4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long HttpManager__GetConnectionSendInfo(void)

{
  undefined4 uVar1;
  long lVar2;
  undefined8 uVar3;
  
  if ((bRam0000000002c495e2 & 1) == 0) {
    func_0x01978cf8(0x3886);
    bRam0000000002c495e2 = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  HttpManager__GetConnectionString();
  lVar2 = func_0x019b4464(_DAT_02bfda38);
  HttpManager_CONNECTION_STRING_SEND_INFO___ctor(lVar2,0);
  uVar3 = HttpManager__GetConnectionString();
  if (lVar2 == 0) {
    func_0x019a516c(0);
    uRam0000000000000010 = uVar3;
    uVar3 = CommonFunc__GetMarketCode(0);
    func_0x019a516c(0);
    uRam0000000000000018 = uVar3;
    uVar1 = CommonFunc__GetVersionCode(0);
    func_0x019a516c(0);
    uRam0000000000000020 = uVar1;
    func_0x019a516c(0);
  }
  else {
    *(undefined8 *)(lVar2 + 0x10) = uVar3;
    uVar3 = CommonFunc__GetMarketCode(0);
    *(undefined8 *)(lVar2 + 0x18) = uVar3;
    uVar1 = CommonFunc__GetVersionCode(0);
    *(undefined4 *)(lVar2 + 0x20) = uVar1;
  }
  *(undefined8 *)(lVar2 + 0x28) = _StringLiteral_1449;  /* "NONE" */
  return lVar2;
}
