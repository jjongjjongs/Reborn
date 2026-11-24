// HttpManager$$ToWebRequestJson @ RVA 0x1c81410

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void HttpManager__ToWebRequestJson(long param_1,long param_2,long param_3)

{
  int iVar1;
  undefined4 uVar2;
  long lVar3;
  undefined8 uVar4;
  long *plVar5;
  undefined4 *puVar6;
  long lVar7;
  undefined8 uVar8;
  long *plVar9;
  undefined8 uStack_58;
  undefined4 uStack_44;
  
  if ((bRam0000000002c4952b & 1) == 0) {
    func_0x01978cf8(0x389d);
    bRam0000000002c4952b = 1;
  }
  uStack_44 = 0;
  lVar3 = func_0x00f2d1ac(_DAT_02c27248);
  if (lVar3 == 0) {
    func_0x019a516c();
  }
  iVar1 = *(int *)(lVar3 + 0x48);
  lVar3 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar3 == 0) {
    func_0x019a516c();
  }
  plVar9 = (long *)(lVar3 + 0x20);
  if (iVar1 != 1) {
    plVar9 = (long *)(lVar3 + 0x18);
  }
  lVar7 = *plVar9;
  lVar3 = func_0x00f2d1ac(_DAT_02c27228);
  if (lVar3 == 0) {
    func_0x019a516c();
  }
  if (*(long *)(lVar3 + 0x28) == 0) {
    func_0x019a516c(0);
    lVar3 = lRam0000000000000070;
    plVar9 = (long *)0x70;
    func_0x019a516c(0);
  }
  else {
    plVar9 = (long *)(*(long *)(lVar3 + 0x28) + 0x70);
    lVar3 = *plVar9;
  }
  *plVar9 = lVar3 + 1;
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  **(long **)(_DAT_02bfcec0 + 0xb8) = lVar3;
  plVar9 = (long *)func_0x019b4464(_DAT_02bfd550);
  M_WEB_REQUEST___ctor(plVar9,0);
  lVar3 = Wellgames_Manager__get_SFRUUF9NRDU(0);
  if (plVar9 == (long *)0x0) {
    func_0x019a516c(0);
  }
  plVar9[2] = lVar3;
  if (lVar7 == 0) {
    func_0x019a516c(0);
    uVar2 = M_CONFIG__get_guid(0,0);
    *(undefined4 *)(plVar9 + 4) = uVar2;
    func_0x019a516c(0);
  }
  else {
    uVar2 = M_CONFIG__get_guid(lVar7,0);
    *(undefined4 *)(plVar9 + 4) = uVar2;
  }
  uVar2 = M_CONFIG__get_token(lVar7,0);
  *(undefined4 *)((long)plVar9 + 0x24) = uVar2;
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar8 = **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  uStack_58 = **(undefined8 **)(_DAT_02bfcec0 + 0xb8);
  uVar4 = func_0x019b43c8(_DAT_02bf55d0,&uStack_58);
  lVar3 = System_String__Concat(uVar8,uVar4,0);
  plVar9[3] = lVar3;
  uStack_44 = UnityEngine_Application__get_systemLanguage(0);
  plVar5 = (long *)func_0x019b43c8(_DAT_02bfd088,&uStack_44);
  if (plVar5 == (long *)0x0) {
    func_0x019a516c();
  }
  lVar3 = (**(code **)(*plVar5 + 0x158))(plVar5,*(undefined8 *)(*plVar5 + 0x160));
  if (plVar5 == (long *)0x0) {
    func_0x019a516c(0);
  }
  puVar6 = (undefined4 *)func_0x019b4908(plVar5);
  uStack_44 = *puVar6;
  plVar9[5] = lVar3;
  plVar9[6] = param_2;
  plVar9[7] = param_3;
  *(long **)(param_1 + 0x18) = plVar9;
  (**(code **)(*plVar9 + 0x158))(plVar9,*(undefined8 *)(*plVar9 + 0x160));
  return;
}
