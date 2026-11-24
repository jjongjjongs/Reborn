// HttpManager$$Post @ RVA 0x1c80ea8

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long HttpManager__Post(undefined8 param_1,undefined8 param_2,undefined8 param_3,long param_4,
                      undefined8 param_5)

{
  char cVar1;
  long lVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  long *plVar5;
  undefined8 uVar6;
  undefined8 extraout_x1;
  undefined8 extraout_x1_00;
  long lVar7;
  
  if ((bRam0000000002c4952a & 1) == 0) {
    func_0x01978cf8(0x3892);
    bRam0000000002c4952a = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  cVar1 = *(char *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x40);
  if ((bRam0000000002c49531 & 1) == 0) {
    func_0x01978cf8(0x3884);
    bRam0000000002c49531 = 1;
  }
  lVar2 = func_0x019b4464(_DAT_02bfd560);
  System_Object___ctor(lVar2,0);
  if (lVar2 == 0) {
    func_0x019a516c(0);
    uRam0000000000000010 = param_3;
    func_0x019a516c(0);
    uRam0000000000000018 = param_5;
    func_0x019a516c(0);
  }
  else {
    *(undefined8 *)(lVar2 + 0x10) = param_3;
    *(undefined8 *)(lVar2 + 0x18) = param_5;
  }
  *(undefined8 *)(lVar2 + 0x20) = param_1;
  if (((*(byte *)(_DAT_02bfc4a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc4a0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  BestHTTP_HTTPManager__set_MaxConnectionPerServer(1,0);
  if (cVar1 != '\0') {
    uVar3 = func_0x019b4464(_DAT_02bf7170);
    System_Uri___ctor(uVar3,param_2,0);
    uVar4 = func_0x019b4464(_DAT_02bfc5f0);
    BestHTTP_OnRequestFinishedDelegate___ctor(uVar4,lVar2,_DAT_02c149a8,0);
    lVar2 = func_0x019b4464(_DAT_02bfc5d0);
    BestHTTP_HTTPRequest___ctor(lVar2,uVar3,2,uVar4,0);
    if (param_4 != 0) {
      plVar5 = (long *)func_0x0179b9c0(param_4,_StringLiteral_5847,_DAT_02c05400);  /* "a" */
      if (plVar5 == (long *)0x0) {
        func_0x019a516c();
      }
      uVar3 = (**(code **)(*plVar5 + 0x158))(plVar5,*(undefined8 *)(*plVar5 + 0x160));
      if (lVar2 == 0) {
        func_0x019a516c(0);
      }
      BestHTTP_HTTPRequest__AddField(lVar2,_StringLiteral_5847,uVar3,0);  /* "a" */
      plVar5 = (long *)func_0x0179b9c0(param_4,_StringLiteral_5880,_DAT_02c05400);  /* "b" */
      if (plVar5 == (long *)0x0) {
        func_0x019a516c();
      }
      uVar3 = (**(code **)(*plVar5 + 0x158))(plVar5,*(undefined8 *)(*plVar5 + 0x160));
      if (lVar2 == 0) {
        func_0x019a516c(0);
      }
      BestHTTP_HTTPRequest__AddField(lVar2,_StringLiteral_5880,uVar3,0);  /* "b" */
      plVar5 = (long *)func_0x0179b9c0(param_4,_StringLiteral_1488,_DAT_02c05400);  /* "c" */
      if (plVar5 == (long *)0x0) {
        func_0x019a516c();
      }
      uVar3 = (**(code **)(*plVar5 + 0x158))(plVar5,*(undefined8 *)(*plVar5 + 0x160));
      if (lVar2 == 0) {
        func_0x019a516c(0);
      }
      BestHTTP_HTTPRequest__AddField(lVar2,_StringLiteral_1488,uVar3,0);  /* "c" */
    }
    if (lVar2 == 0) {
      func_0x019a516c(0);
    }
    BestHTTP_HTTPRequest__Send(lVar2,0);
    if ((bRam0000000002c495e8 & 1) == 0) {
      func_0x01978cf8(0x389b);
      bRam0000000002c495e8 = 1;
    }
    lVar2 = _DAT_02bfcec0;
    if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
      lVar2 = _DAT_02bfcec0;
    }
    _DAT_02bfcec0 = lVar2;
    *(undefined1 *)(*(long *)(lVar2 + 0xb8) + 0x40) = 0;
    return lVar2;
  }
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  if (param_4 == 0) {
    uVar3 = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  }
  else {
    uVar3 = func_0x0179b9c0(param_4,_StringLiteral_5847,_DAT_02c05400);  /* "a" */
    uVar4 = func_0x0179b9c0(param_4,_StringLiteral_5880,_DAT_02c05400);  /* "b" */
    uVar6 = func_0x0179b9c0(param_4,_StringLiteral_1488,_DAT_02c05400);  /* "c" */
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    uVar3 = System_String__Format(_StringLiteral_6196,uVar3,uVar4,uVar6,0);  /* "?a={0}&b={1}&c={2}" */
  }
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar3 = System_String__Concat(param_2,uVar3,0);
  uVar4 = func_0x019b4464(_DAT_02bf7170);
  System_Uri___ctor(uVar4,uVar3,0);
  uVar3 = func_0x019b4464(_DAT_02bfc5f0);
  BestHTTP_OnRequestFinishedDelegate___ctor(uVar3,lVar2,_DAT_02c149a0,0);
  lVar2 = func_0x019b4464(_DAT_02bfc5d0);
  BestHTTP_HTTPRequest___ctor(lVar2,uVar4,0,uVar3,0);
  if (((*(byte *)(_DAT_02bf5c70 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5c70 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar3 = System_TimeSpan__FromSeconds(0x403e000000000000,0);
  if (lVar2 == 0) {
    func_0x019a516c(0);
    BestHTTP_HTTPRequest__set_Timeout(0,uVar3,0);
    func_0x019a516c(0);
    BestHTTP_HTTPRequest__set_DisableRetry(0,1,0);
    func_0x019a516c(0);
  }
  else {
    BestHTTP_HTTPRequest__set_Timeout(lVar2,uVar3,0);
    BestHTTP_HTTPRequest__set_DisableRetry(lVar2,1,0);
  }
  uVar3 = 0;
  if ((bRam0000000002c49ef2 & 1) == 0) {
    func_0x01978cf8(0x3738,0);
    bRam0000000002c49ef2 = 1;
    uVar3 = extraout_x1;
  }
  if (((*(byte *)(_DAT_02bfc4a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc4a0 + 0xd8) == 0)) {
    func_0x0198ba0c();
    uVar3 = extraout_x1_00;
  }
  if ((bRam0000000002c49eb3 & 1) == 0) {
    func_0x01978cf8(0x36f4,uVar3);
    bRam0000000002c49eb3 = 1;
  }
  if (((*(byte *)(_DAT_02bfc4a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc4a0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar3 = *(undefined8 *)(*(long *)(_DAT_02bfc4a0 + 0xb8) + 0xb0);
  System_Threading_Monitor__Enter(uVar3,0);
  if (((*(byte *)(_DAT_02bfc4a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc4a0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  BestHTTP_HTTPManager__Setup();
  if (*(char *)(*(long *)(_DAT_02bfc4a0 + 0xb8) + 0xa8) == '\0') {
    if (((*(byte *)(_DAT_02bfc4a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc4a0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    BestHTTP_HTTPManager__SendRequestImpl(lVar2);
  }
  else {
    if (lVar2 == 0) {
      func_0x019a516c(0);
    }
    lVar7 = _DAT_02bfc4a0;
    *(undefined4 *)(lVar2 + 0xb4) = 1;
    if (((*(byte *)(lVar7 + 0x126) >> 1 & 1) != 0) && (*(int *)(lVar7 + 0xd8) == 0)) {
      func_0x0198ba0c();
      lVar7 = _DAT_02bfc4a0;
    }
    lVar7 = *(long *)(*(long *)(lVar7 + 0xb8) + 0xa0);
    if (lVar7 == 0) {
      func_0x019a516c(0);
    }
    func_0x018662b0(lVar7,lVar2,_DAT_02c1d9d8);
  }
  System_Threading_Monitor__Exit(uVar3,0);
  return lVar2;
}
