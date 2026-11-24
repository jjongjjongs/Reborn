// Wellgames.Manager$$OBCDKIGDCLN @ RVA 0x1d3da0c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 Wellgames_Manager__OBCDKIGDCLN(long param_1)

{
  ulong uVar1;
  undefined8 uVar2;
  long lVar3;
  
  if ((bRam0000000002c49c4d & 1) == 0) {
    func_0x01978cf8(0x4e78);
    bRam0000000002c49c4d = 1;
  }
  uVar2 = *(undefined8 *)(param_1 + 0x20);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar1 = System_String__IsNullOrEmpty(uVar2,0);
  if ((uVar1 & 1) != 0) {
    uVar2 = UnityEngine_SystemInfo__get_deviceUniqueIdentifier(0);
    *(undefined8 *)(param_1 + 0x20) = uVar2;
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar1 = System_String__IsNullOrEmpty(uVar2,0);
    if ((uVar1 & 1) == 0) {
      lVar3 = *(long *)(param_1 + 0x20);
      uVar2 = func_0x019b9d20(_DAT_02bf5608,0x80);
      System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar2,_DAT_02c2aff8,0);  /* dec: 'cd9e459ea708a948d5c2f5a6ca8838cf' */
      if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar2 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                        (uVar2,0,0);
      if (lVar3 == 0) {
        func_0x019a516c(0);
      }
      uVar1 = System_String__Equals(lVar3,uVar2,0);
      if ((uVar1 & 1) == 0) goto LAB_01e3dbd8;
    }
    if (((*(byte *)(_DAT_02bfc2d8 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc2d8 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar2 = *(undefined8 *)(*(long *)(_DAT_02bfc2d8 + 0xb8) + 0x40);
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    uVar1 = System_String__IsNullOrEmpty(uVar2,0);
    if ((uVar1 & 1) == 0) {
      if (((*(byte *)(_DAT_02bfc2d8 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc2d8 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar2 = *(undefined8 *)(*(long *)(_DAT_02bfc2d8 + 0xb8) + 0x40);
    }
    else {
      lVar3 = func_0x00f2d1ac(_DAT_02c27238);
      if (lVar3 == 0) {
        func_0x019a516c();
      }
      uVar2 = *(undefined8 *)(lVar3 + 0x18);
    }
    *(undefined8 *)(param_1 + 0x20) = uVar2;
  }
LAB_01e3dbd8:
  return *(undefined8 *)(param_1 + 0x20);
}
