// <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116_.NLNPLGOEHOB$$.cctor @ RVA 0x1aea728

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB___cctor(void)

{
  undefined1 uVar1;
  undefined1 uVar2;
  long lVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  long lVar6;
  
  if ((bRam0000000002c4886a & 1) == 0) {
    func_0x01978cf8(0x5377);
    bRam0000000002c4886a = 1;
  }
  uVar4 = func_0x019b9d20(_DAT_02bf5608,0x94);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar4,_DAT_02c2b018,0);
  **(undefined8 **)(_DAT_02bfc200 + 0xb8) = uVar4;
  lVar6 = _DAT_02bfc200;
  *(undefined4 *)(*(long *)(_DAT_02bfc200 + 0xb8) + 8) = 0x80;
  lVar6 = **(long **)(lVar6 + 0xb8);
  if (lVar6 == 0) {
    func_0x019a516c(0);
  }
  if (*(uint *)(lVar6 + 0x18) < 0x11) {
    uVar4 = func_0x019a5e50();
    func_0x019a50dc(uVar4,0,0);
  }
  uVar1 = *(undefined1 *)(lVar6 + 0x30);
  lVar6 = **(long **)(_DAT_02bfc200 + 0xb8);
  if (lVar6 == 0) {
    func_0x019a516c(0);
  }
  if (*(uint *)(lVar6 + 0x18) < 0x12) {
    uVar4 = func_0x019a5e50();
    func_0x019a50dc(uVar4,0,0);
  }
  uVar2 = *(undefined1 *)(lVar6 + 0x31);
  lVar6 = **(long **)(_DAT_02bfc200 + 0xb8);
  if (lVar6 == 0) {
    func_0x019a516c(0);
  }
  if (*(uint *)(lVar6 + 0x18) < 0x13) {
    uVar4 = func_0x019a5e50();
    func_0x019a50dc(uVar4,0,0);
  }
  lVar3 = _DAT_02bfc200;
  *(uint *)(*(long *)(_DAT_02bfc200 + 0xb8) + 0xc) =
       (uint)CONCAT12(*(undefined1 *)(lVar6 + 0x32),CONCAT11(uVar2,uVar1));
  uVar4 = func_0x019b9d20(_DAT_02bf5608,*(undefined4 *)(*(long *)(lVar3 + 0xb8) + 8));
  System_Buffer__BlockCopy
            (**(undefined8 **)(_DAT_02bfc200 + 0xb8),0x14,uVar4,0,
             *(undefined4 *)(*(undefined8 **)(_DAT_02bfc200 + 0xb8) + 1),0);
  System_Array__Reverse(uVar4,0);
  uVar5 = func_0x019b4464(_DAT_02bf7c88);
  Mono_Math_BigInteger___ctor(uVar5,uVar4,0);
  *(undefined8 *)(*(long *)(_DAT_02bfc200 + 0xb8) + 0x10) = uVar5;
  return;
}
