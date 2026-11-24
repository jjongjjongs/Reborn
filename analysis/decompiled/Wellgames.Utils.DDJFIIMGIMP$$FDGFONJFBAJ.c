// Wellgames.Utils.DDJFIIMGIMP$$FDGFONJFBAJ @ RVA 0x1e7b358

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Wellgames_Utils_DDJFIIMGIMP__FDGFONJFBAJ(void)

{
  long lVar1;
  undefined8 uVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  undefined4 uStack_38;
  undefined4 uStack_34;
  
  if ((bRam0000000002c4a637 & 1) == 0) {
    func_0x01978cf8(0x1d18);
    bRam0000000002c4a637 = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  lVar1 = HttpManager__GetConnectionSendInfo(0);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  if (lVar1 == 0) {
    uVar2 = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  }
  else {
    uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
    System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c2a148,0);  /* dec: '&MARKET={0}&VERSION={1}&DEPLOYMENT={2}' */
    if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                      (uVar2,0,0);
    uVar5 = *(undefined8 *)(lVar1 + 0x18);
    uStack_34 = *(undefined4 *)(lVar1 + 0x20);
    uVar3 = func_0x019b43c8(_DAT_02bf55b8,&uStack_34);
    uVar4 = *(undefined8 *)(lVar1 + 0x28);
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    uVar2 = System_String__Format(uVar2,uVar5,uVar3,uVar4,0);
  }
  uVar3 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar3,_DAT_02c2a150,0);  /* dec: '/init/config.php?time= ' */
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar3 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar3,0,0);
  uStack_38 = UnityEngine_Random__Range(100,2000000,0);
  uVar4 = func_0x019b43c8(_DAT_02bf55b8,&uStack_38);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  System_String__Concat(uVar3,uVar4,uVar2,0);
  return;
}
