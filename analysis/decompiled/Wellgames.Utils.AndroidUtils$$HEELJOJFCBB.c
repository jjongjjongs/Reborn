// Wellgames.Utils.AndroidUtils$$HEELJOJFCBB @ RVA 0x1d4843c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long Wellgames_Utils_AndroidUtils__HEELJOJFCBB(long param_1)

{
  int iVar1;
  undefined8 uVar2;
  undefined8 uVar3;
  long lVar4;
  ulong uVar5;
  long *plVar6;
  long lVar7;
  long lVar8;
  uint uVar9;
  undefined4 uStack_64;
  
  if ((bRam0000000002c49c78 & 1) == 0) {
    func_0x01978cf8(0x5e3);
    bRam0000000002c49c78 = 1;
  }
  uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298c0,0);  /* dec: 'com.unity3d.player.UnityPlayer' */
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar2,0,0);
  uVar3 = func_0x019b4464(_DAT_02bf8280);
  UnityEngine_AndroidJavaClass___ctor(uVar3,uVar2,0);
  if (((*(byte *)(_DAT_02bfc2d8 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc2d8 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  lVar7 = _DAT_02bfc2d8;
  *(undefined8 *)(*(long *)(_DAT_02bfc2d8 + 0xb8) + 0x10) = uVar3;
  lVar7 = *(long *)(*(long *)(lVar7 + 0xb8) + 0x10);
  uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298c8,0);  /* dec: 'currentActivity' */
  uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar2,0,0);
  if (lVar7 == 0) {
    func_0x019a516c(0);
  }
  lVar7 = func_0x015ac894(lVar7,uVar2,_DAT_02c02a58);
  uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298d0,0);  /* dec: 'getPackageManager' */
  uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar2,0,0);
  uVar3 = func_0x019b9d20(_DAT_02bf5738,0);
  if (lVar7 == 0) {
    func_0x019a516c(0);
  }
  lVar4 = func_0x015b141c(lVar7,uVar2,uVar3,_DAT_02c065a0);
  uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298d8,0);  /* dec: 'getPackageName' */
  uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar2,0,0);
  uVar3 = func_0x019b9d20(_DAT_02bf5738,0);
  if (lVar7 == 0) {
    func_0x019a516c(0);
  }
  lVar7 = func_0x015b141c(lVar7,uVar2,uVar3,_DAT_02c06598);
  if (param_1 == 0) {
    func_0x019a516c(0);
  }
  uVar5 = System_String__Equals(param_1,lVar7,0);
  lVar8 = 0;
  if ((uVar5 & 1) != 0) {
    uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
    System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298e0,0);  /* dec: 'getPackageInfo' */
    if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                      (uVar2,0,0);
    plVar6 = (long *)func_0x019b9d20(_DAT_02bf5738,2);
    if (plVar6 == (long *)0x0) {
      func_0x019a516c();
    }
    if ((lVar7 != 0) && (lVar8 = func_0x019b46fc(lVar7,*(undefined8 *)(*plVar6 + 0x40)), lVar8 == 0)
       ) {
      uVar3 = func_0x019a6488();
      func_0x019a50dc(uVar3,0,0);
    }
    if ((int)plVar6[3] == 0) {
      uVar3 = func_0x019a5e50();
      func_0x019a50dc(uVar3,0,0);
    }
    plVar6[4] = lVar7;
    uStack_64 = 0x40;
    lVar7 = func_0x019b43c8(_DAT_02bf55b8,&uStack_64);
    if ((lVar7 != 0) && (lVar8 = func_0x019b46fc(lVar7,*(undefined8 *)(*plVar6 + 0x40)), lVar8 == 0)
       ) {
      uVar3 = func_0x019a6488();
      func_0x019a50dc(uVar3,0,0);
    }
    if (*(uint *)(plVar6 + 3) < 2) {
      uVar3 = func_0x019a5e50();
      func_0x019a50dc(uVar3,0,0);
    }
    plVar6[5] = lVar7;
    if (lVar4 == 0) {
      func_0x019a516c(0);
    }
    lVar7 = func_0x015b141c(lVar4,uVar2,plVar6,_DAT_02c065a0);
    uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
    System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298e8,0);  /* dec: 'signatures' */
    uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                      (uVar2,0,0);
    if (lVar7 == 0) {
      func_0x019a516c(0);
    }
    lVar7 = func_0x015ac84c(lVar7,uVar2,_DAT_02c02a50);
    uVar9 = 0;
    lVar8 = 0;
    while( true ) {
      if (lVar7 == 0) {
        func_0x019a516c(0);
      }
      if ((int)*(uint *)(lVar7 + 0x18) <= (int)uVar9) break;
      if (*(uint *)(lVar7 + 0x18) <= uVar9) {
        uVar2 = func_0x019a5e50();
        func_0x019a50dc(uVar2,0,0);
      }
      lVar4 = *(long *)(lVar7 + (long)(int)uVar9 * 8 + 0x20);
      uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
      System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c298f0,0);  /* dec: 'hashCode' */
      if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                        (uVar2,0,0);
      uVar3 = func_0x019b9d20(_DAT_02bf5738,0);
      if (lVar4 == 0) {
        func_0x019a516c(0);
      }
      iVar1 = func_0x015b137c(lVar4,uVar2,uVar3,_DAT_02c06580);
      lVar8 = (long)iVar1;
      uVar9 = uVar9 + 1;
    }
  }
  return lVar8;
}
