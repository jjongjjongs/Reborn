// U_Logo$$<PM_SetConnectionString>m__0 @ RVA 0x1c3365c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void U_Logo__<PM_SetConnectionString>m__0(long param_1,long *param_2,undefined8 param_3)

{
  undefined8 uVar1;
  undefined8 uVar2;
  undefined8 uVar3;
  long lVar4;
  ulong uVar5;
  undefined8 uVar6;
  long *plVar7;
  long lVar8;
  long *plStack_50;
  undefined8 uStack_48;
  
  if ((bRam0000000002c49318 & 1) == 0) {
    func_0x01978cf8(0x8c92);
    bRam0000000002c49318 = 1;
  }
  plStack_50 = (long *)0x0;
  if (param_2 == (long *)0x0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar5 = System_String__IsNullOrEmpty(param_3,0);
    if ((uVar5 & 1) == 0) {
      if (((*(byte *)(_DAT_02bfc440 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc440 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      lVar8 = MyJson__ToDictionary(param_3,0);
      plStack_50 = (long *)0x0;
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c(_DAT_02bf5540);
      }
      if (lVar8 == 0) {
        func_0x019a516c(0);
      }
      uVar5 = func_0x0179e1f0(lVar8,_StringLiteral_12435,&plStack_50,_DAT_02c08ec8);  /* "URL" */
      if ((uVar5 & 1) != 0) {
        plVar7 = plStack_50;
        if ((plStack_50 != (long *)0x0) && (*plStack_50 != _DAT_02bf5540)) {
          func_0x019d7df0(&uStack_48,*(undefined8 *)(*plStack_50 + 0x40));
          uVar2 = func_0x019a5e1c(uStack_48);
          func_0x019a50dc(uVar2,0,0);
          func_0x0208fe80(&uStack_48);
          plVar7 = (long *)0x0;
        }
        if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) &&
           (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        HttpManager__SetDefaultUrl(plVar7,0);
      }
      if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar2 = HttpManager__GetServerName(0);
      *(undefined8 *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x30) = uVar2;
      lVar8 = func_0x00f2d1ac(_DAT_02c27490);
      if (lVar8 == 0) {
        func_0x019a516c();
      }
      U_LoadingBar__View(lVar8,0,0);
      lVar8 = *(long *)(param_1 + 0x18);
      if (lVar8 == 0) {
        func_0x019a516c(0);
      }
      PlayMakerFSM__SendEvent(lVar8,_StringLiteral_12948,0);  /* "END_CONNECTION_STRING" */
    }
  }
  else {
    uVar2 = (**(code **)(*param_2 + 0x158))(param_2,*(undefined8 *)(*param_2 + 0x160));
    if (((*(byte *)(_DAT_02bfc210 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc210 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bfc210);
    }
    uVar3 = Localization__Get(uVar2,1,0);
    lVar4 = func_0x00f2d1ac(_DAT_02c275d8);
    uVar1 = _StringLiteral_12220;  /* "MSG_TITLE_ERROR" */
    uVar2 = _StringLiteral_1271;  /* "OK" */
    lVar8 = **(long **)(_DAT_02c019b8 + 0xb8);
    if (lVar8 == 0) {
      uVar6 = func_0x019b4464(_DAT_02bfcd00);
      EventDelegate_Callback___ctor(uVar6,0,_DAT_02c25228,0);
      **(undefined8 **)(_DAT_02c019b8 + 0xb8) = uVar6;
      lVar8 = **(long **)(_DAT_02c019b8 + 0xb8);
    }
    if (lVar4 == 0) {
      func_0x019a516c(0);
    }
    U_Popup__Confirm(lVar4,uVar1,uVar3,uVar2,lVar8,0);
    lVar8 = func_0x00f2d1ac(_DAT_02c27718);
    if (lVar8 == 0) {
      func_0x019a516c();
    }
    Wellgames_Manager__PNKNPPEBEPC(0x40a00000,lVar8,0);
  }
  return;
}
