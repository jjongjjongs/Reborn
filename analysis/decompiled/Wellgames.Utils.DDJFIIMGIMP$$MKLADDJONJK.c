// Wellgames.Utils.DDJFIIMGIMP$$MKLADDJONJK @ RVA 0x1e86498

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long Wellgames_Utils_DDJFIIMGIMP__MKLADDJONJK(void)

{
  int iVar1;
  long lVar2;
  ulong uVar3;
  long lVar4;
  undefined8 uVar5;
  long *plVar6;
  long lVar7;
  long lVar8;
  undefined8 *puVar9;
  undefined8 uVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  undefined4 uStack_6c;
  undefined4 uStack_68;
  undefined4 uStack_64;
  
  if ((bRam0000000002c4a664 & 1) == 0) {
    func_0x01978cf8(0x1d38);
    bRam0000000002c4a664 = 1;
  }
  lVar2 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar2 == 0) {
    func_0x019a516c();
  }
  iVar1 = *(int *)(lVar2 + 0x48);
  lVar2 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar2 == 0) {
    func_0x019a516c();
  }
  plVar6 = (long *)(lVar2 + 0x20);
  if (iVar1 != 1) {
    plVar6 = (long *)(lVar2 + 0x18);
  }
  lVar2 = *plVar6;
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar11 = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  if (lVar2 == 0) {
    func_0x019a516c(0);
    uVar3 = System_String__IsNullOrEmpty(uRam0000000000000018,0);
    func_0x019a516c(0);
    if ((uVar3 & 1) == 0) goto LAB_01f865c8;
LAB_01f8656c:
    uVar10 = *(undefined8 *)(lVar2 + 0x10);
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar3 = System_String__IsNullOrEmpty(uVar10,0);
    if ((uVar3 & 1) != 0) goto LAB_01f865d0;
    puVar9 = (undefined8 *)(lVar2 + 0x30);
  }
  else {
    uVar3 = System_String__IsNullOrEmpty(*(undefined8 *)(lVar2 + 0x18),0);
    if ((uVar3 & 1) != 0) goto LAB_01f8656c;
LAB_01f865c8:
    puVar9 = (undefined8 *)(lVar2 + 0x28);
  }
  uVar11 = *puVar9;
LAB_01f865d0:
  lVar4 = func_0x019b4464(_DAT_02bf8ec0);
  func_0x0179a6f8(lVar4,_DAT_02c1ca58);
  uVar10 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar10,_DAT_02c2a940,0);  /* dec: 'MARKET' */
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar10 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar10,0,0);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar12 = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  uStack_64 = 0;
  uVar5 = func_0x019b43c8(_DAT_02bfd010,&uStack_64);
  uVar5 = System_String__Concat(uVar12,uVar5,0);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar10,uVar5,_DAT_02c1ca68);
  uVar10 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar10,_DAT_02c2a948,0);  /* dec: 'VERSION' */
  uVar10 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar10,0,0);
  uStack_68 = 0x15b;
  uVar5 = func_0x019b43c8(_DAT_02bf55b8,&uStack_68);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar10,uVar5,_DAT_02c1ca68);
  uVar10 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar10,_DAT_02c2a958,0);  /* dec: 'EMAIL' */
  uVar10 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar10,0,0);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar10,uVar11,_DAT_02c1ca68);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a960,0);  /* dec: 'APPS' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  plVar6 = (long *)func_0x019b9d20(_DAT_02bf5610,2);
  uVar10 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar10,_DAT_02c2a968,0);  /* dec: 'a.b' */
  lVar7 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar10,0,0);
  if (plVar6 == (long *)0x0) {
    func_0x019a516c(0);
  }
  if ((lVar7 != 0) && (lVar8 = func_0x019b46fc(lVar7,*(undefined8 *)(*plVar6 + 0x40)), lVar8 == 0))
  {
    uVar10 = func_0x019a6488();
    func_0x019a50dc(uVar10,0,0);
  }
  if ((int)plVar6[3] == 0) {
    uVar10 = func_0x019a5e50();
    func_0x019a50dc(uVar10,0,0);
  }
  plVar6[4] = lVar7;
  uVar10 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar10,_DAT_02c2a970,0);  /* dec: 'b.c' */
  lVar7 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                    (uVar10,0,0);
  if ((lVar7 != 0) && (lVar8 = func_0x019b46fc(lVar7,*(undefined8 *)(*plVar6 + 0x40)), lVar8 == 0))
  {
    uVar10 = func_0x019a6488();
    func_0x019a50dc(uVar10,0,0);
  }
  if (*(uint *)(plVar6 + 3) < 2) {
    uVar10 = func_0x019a5e50();
    func_0x019a50dc(uVar10,0,0);
  }
  plVar6[5] = lVar7;
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar11,plVar6,_DAT_02c1ca68);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a978,0);  /* dec: 'UDID' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  lVar7 = func_0x00f2d1ac(_DAT_02c27718);
  if (lVar7 == 0) {
    func_0x019a516c();
  }
  uVar10 = Wellgames_Manager__OBCDKIGDCLN(lVar7,0);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar11,uVar10,_DAT_02c1ca68);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a980,0);  /* dec: 'SIG' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  uVar10 = Wellgames_Utils_JEFFHHLHJNB__OCECOHPKFMB(0);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar11,uVar10,_DAT_02c1ca68);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a988,0);  /* dec: 'AGREE' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  lVar7 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar7 == 0) {
    func_0x019a516c();
  }
  lVar7 = DataManager__get_DEV(lVar7,0);
  if (lVar7 == 0) {
    func_0x019a516c();
  }
  uStack_6c = *(undefined4 *)(lVar7 + 0x68);
  uVar10 = func_0x019b43c8(_DAT_02bf55b8,&uStack_6c);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar11,uVar10,_DAT_02c1ca68);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a990,0);  /* dec: 'ANDROIDID' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  if (((*(byte *)(_DAT_02bfc2d8 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc2d8 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bfc2d8);
  }
  uVar10 = *(undefined8 *)(*(long *)(_DAT_02bfc2d8 + 0xb8) + 0x40);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar11,uVar10,_DAT_02c1ca68);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a998,0);  /* dec: 'ADID' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  uVar10 = *(undefined8 *)(*(long *)(_DAT_02bfc2d8 + 0xb8) + 0x48);
  if (lVar4 == 0) {
    func_0x019a516c(0);
  }
  func_0x0179ccd0(lVar4,uVar11,uVar10,_DAT_02c1ca68);
  uVar3 = System_String__IsNullOrEmpty(*(undefined8 *)(lVar2 + 0x40),0);
  if ((uVar3 & 1) == 0) {
    lVar7 = *(long *)(lVar2 + 0x40);
    if (lVar7 == 0) {
      func_0x019a516c(0);
    }
    iVar1 = System_String__get_Length(lVar7,0);
    if (10 < iVar1) {
      uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
      System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a9a0,0);  /* dec: 'GCM' */
      if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                         (uVar11,0,0);
      uVar10 = *(undefined8 *)(lVar2 + 0x40);
      if (lVar4 == 0) {
        func_0x019a516c(0);
      }
      func_0x0179ccd0(lVar4,uVar11,uVar10,_DAT_02c1ca68);
    }
  }
  return lVar4;
}
