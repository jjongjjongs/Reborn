// <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116_.NLNPLGOEHOB$$FEKEMKOBDAP @ RVA 0x1ae7c6c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8
<PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__FEKEMKOBDAP
          (long param_1)

{
  undefined8 uVar1;
  long *plVar2;
  uint uVar3;
  uint uVar4;
  
  if ((bRam0000000002c4886c & 1) == 0) {
    func_0x01978cf8(0x5369);
    bRam0000000002c4886c = 1;
  }
  uVar4 = 0;
  while( true ) {
    if (param_1 == 0) {
      func_0x019a516c(0);
    }
    uVar3 = (uint)*(undefined8 *)(param_1 + 0x18);
    if ((int)uVar3 <= (int)uVar4) goto LAB_01be7cf8;
    if (uVar3 <= uVar4) {
      uVar1 = func_0x019a5e50();
      func_0x019a50dc(uVar1,0,0);
    }
    if (*(char *)(param_1 + (int)uVar4 + 0x20) != '\0') break;
    uVar4 = uVar4 + 1;
  }
  uVar3 = (uint)*(undefined8 *)(param_1 + 0x18);
LAB_01be7cf8:
  if (uVar3 - uVar4 == 0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    return **(undefined8 **)(_DAT_02bf5540 + 0xb8);
  }
  uVar1 = func_0x019b9d20(_DAT_02bf5608,uVar3 - uVar4);
  System_Buffer__BlockCopy(param_1,uVar4,uVar1,0,*(int *)(param_1 + 0x18) - uVar4,0);
  if (((*(byte *)(_DAT_02bf56a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf56a0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  plVar2 = (long *)System_Text_Encoding__get_UTF8(0);
  if (plVar2 == (long *)0x0) {
    func_0x019a516c();
  }
                    /* WARNING: Could not recover jumptable at 0x01be7dc4. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  uVar1 = (**(code **)(*plVar2 + 0x298))(plVar2,uVar1,*(undefined8 *)(*plVar2 + 0x2a0));
  return uVar1;
}
