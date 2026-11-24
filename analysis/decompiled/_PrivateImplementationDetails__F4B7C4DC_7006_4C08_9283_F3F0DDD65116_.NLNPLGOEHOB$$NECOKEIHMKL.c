// <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116_.NLNPLGOEHOB$$NECOKEIHMKL @ RVA 0x1aeb040

/* WARNING: Removing unreachable block (ram,0x00dbc328) */
/* WARNING: Removing unreachable block (ram,0x00dbc2d4) */
/* WARNING: Removing unreachable block (ram,0x00dbc2dc) */
/* WARNING: Removing unreachable block (ram,0x00dbbb0c) */
/* WARNING: Removing unreachable block (ram,0x00dbbae4) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
               (long param_1,ulong param_2)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  long lVar6;
  long *plVar7;
  long lVar8;
  long lVar9;
  long lVar10;
  undefined8 uVar11;
  long *plVar12;
  uint uVar13;
  long *plVar14;
  undefined8 *puVar15;
  undefined8 *puVar16;
  undefined8 uVar17;
  int *piVar18;
  int *piVar19;
  undefined1 auVar20 [16];
  uint uStack_64;
  
  if ((bRam0000000002c4886e & 1) == 0) {
    func_0x01978cf8(0x5371);
    bRam0000000002c4886e = 1;
  }
  if (param_1 == 0) {
    func_0x019a516c(0);
  }
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  if (*(int *)(*(long *)(_DAT_02bfc200 + 0xb8) + 8) == *(int *)(param_1 + 0x18)) {
    lVar10 = func_0x019b4464(_DAT_02bf7c88);
    Mono_Math_BigInteger___ctor(lVar10,param_1,0);
    if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar1 = *(undefined4 *)(*(long *)(_DAT_02bfc200 + 0xb8) + 0xc);
    if (((*(byte *)(_DAT_02bf7c88 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf7c88 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf7c88);
    }
    uVar11 = Mono_Math_BigInteger__op_Implicit(uVar1,0);
    uVar17 = *(undefined8 *)(*(long *)(_DAT_02bfc200 + 0xb8) + 0x10);
    if (lVar10 == 0) {
      func_0x019a516c(0);
    }
    lVar10 = Mono_Math_BigInteger__ModPow(lVar10,uVar11,uVar17,0);
    if (lVar10 == 0) {
      func_0x019a516c();
    }
    Mono_Math_BigInteger__GetBytes(lVar10,0);
    lVar10 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__FEKEMKOBDAP
                       ();
  }
  else {
    lVar10 = func_0x019b4464(_DAT_02bf5698);
    System_Text_StringBuilder___ctor(lVar10,0);
    iVar5 = 0;
    while( true ) {
      if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      iVar3 = *(int *)(*(long *)(_DAT_02bfc200 + 0xb8) + 8);
      iVar4 = 0;
      if (iVar3 != 0) {
        iVar4 = *(int *)(param_1 + 0x18) / iVar3;
      }
      if (iVar4 <= iVar5) break;
      if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
        func_0x0198ba0c();
        iVar3 = *(int *)(*(long *)(_DAT_02bfc200 + 0xb8) + 8);
      }
      uVar11 = func_0x019b9d20(_DAT_02bf5608,iVar3);
      iVar3 = *(int *)(*(long *)(_DAT_02bfc200 + 0xb8) + 8);
      System_Buffer__BlockCopy(param_1,iVar3 * iVar5,uVar11,0,iVar3,0);
      lVar9 = func_0x019b4464(_DAT_02bf7c88);
      Mono_Math_BigInteger___ctor(lVar9,uVar11,0);
      uVar1 = *(undefined4 *)(*(long *)(_DAT_02bfc200 + 0xb8) + 0xc);
      if (((*(byte *)(_DAT_02bf7c88 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf7c88 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      uVar11 = Mono_Math_BigInteger__op_Implicit(uVar1,0);
      uVar17 = *(undefined8 *)(*(long *)(_DAT_02bfc200 + 0xb8) + 0x10);
      if (lVar9 == 0) {
        func_0x019a516c(0);
      }
      lVar9 = Mono_Math_BigInteger__ModPow(lVar9,uVar11,uVar17,0);
      if (lVar9 == 0) {
        func_0x019a516c();
      }
      Mono_Math_BigInteger__GetBytes(lVar9,0);
      uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__FEKEMKOBDAP
                         ();
      if (lVar10 == 0) {
        func_0x019a516c(0);
      }
      System_Text_StringBuilder__Append(lVar10,uVar11,0);
      iVar5 = iVar5 + 1;
    }
    if (lVar10 == 0) {
      func_0x019a516c(0);
    }
    lVar10 = System_Text_StringBuilder__ToString(lVar10,0);
  }
  if ((param_2 & 1) == 0) {
    return lVar10;
  }
  if (lVar10 == 0) {
    func_0x019a516c(0);
    iVar5 = System_String__get_Length(0,0);
    func_0x019a516c(0);
  }
  else {
    iVar5 = System_String__get_Length(lVar10,0);
  }
  iVar5 = iVar5 + -2;
  if ((bRam0000000002be8baf & 1) == 0) {
    func_0x01978cf8(0x7582,1,iVar5,0);
    bRam0000000002be8baf = 1;
  }
  if (iVar5 < 0) {
    uVar11 = func_0x019b4464(_DAT_02bf5778);
    puVar15 = (undefined8 *)&StringLiteral_1505;  /* "length" */
    puVar16 = (undefined8 *)&StringLiteral_11367;  /* "Cannot be negative." */
  }
  else if (*(int *)(lVar10 + 0x10) < 1) {
    uVar11 = func_0x019b4464(_DAT_02bf5778);
    puVar15 = (undefined8 *)&StringLiteral_1484;  /* "startIndex" */
    puVar16 = (undefined8 *)&StringLiteral_11397;  /* "Cannot exceed length of string." */
  }
  else {
    if (0 < *(int *)(lVar10 + 0x10) - iVar5) {
      if ((bRam0000000002be8bb0 & 1) == 0) {
        func_0x01978cf8(0x7581);
        bRam0000000002be8bb0 = 1;
      }
      if (iVar5 == 0) {
        if (((*(ushort *)(_DAT_02bf5540 + 0x125) >> 9 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar9 = **(long **)(_DAT_02bf5540 + 0xb8);
      }
      else {
        if (((*(ushort *)(_DAT_02bf5540 + 0x125) >> 9 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar9 = thunk_FUN_019c327c(iVar5);
        iVar3 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
        iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
        System_String__CharCopy(lVar9 + iVar3,lVar10 + 2 + (long)iVar4,iVar5);
      }
      return lVar9;
    }
    uVar11 = func_0x019b4464(_DAT_02bf5778);
    puVar15 = (undefined8 *)&StringLiteral_1505;  /* "length" */
    puVar16 = (undefined8 *)&StringLiteral_11398;  /* "startIndex + length > this.length" */
  }
  System_ArgumentOutOfRangeException___ctor(uVar11,*puVar15,*puVar16,0);
  uVar13 = (uint)_DAT_02c125f8;
  func_0x019a50dc(uVar11,0);
  auVar20 = func_0x019da0a8();
  lVar10 = auVar20._8_8_;
  while( true ) {
    if ((bRam0000000002be8bac & 1) == 0) {
      func_0x01978cf8(0x757e);
      bRam0000000002be8bac = 1;
    }
    if ((lVar10 != 0) && (*(int *)(lVar10 + 0x18) != 0)) break;
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar10 = *(long *)(*(long *)(_DAT_02bf5540 + 0xb8) + 8);
  }
  if (uVar13 < 2) {
    lVar10 = FUN_019bb2cc(auVar20._0_8_,lVar10,0x7fffffff,uVar13);
    return lVar10;
  }
  uStack_64 = uVar13;
  uVar11 = func_0x019b43c8(_DAT_02bf6b60,&uStack_64);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar11 = System_String__Concat(_StringLiteral_11396,uVar11,_StringLiteral_424);  /* "Illegal enum value: ", "." */
  uVar17 = func_0x019b4464(_DAT_02bf5670);
  System_ArgumentException___ctor(uVar17,uVar11,0);
  plVar14 = _DAT_02c127a8;
  func_0x019a50dc(uVar17,0);
  auVar20 = func_0x019da0a8();
  plVar12 = auVar20._8_8_;
  plVar7 = auVar20._0_8_;
  if ((bRam0000000002be8bf1 & 1) == 0) {
    func_0x01978cf8(0x7543);
    bRam0000000002be8bf1 = 1;
  }
  if (plVar7 == (long *)0x0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar10 = **(long **)(_DAT_02bf5540 + 0xb8);
    if (plVar12 != (long *)0x0) goto LAB_00dbbc50;
LAB_00dbbcbc:
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar9 = **(long **)(_DAT_02bf5540 + 0xb8);
    if (plVar14 != (long *)0x0) goto LAB_00dbbc68;
LAB_00dbbcec:
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    lVar8 = **(long **)(_DAT_02bf5540 + 0xb8);
  }
  else {
    lVar10 = (**(code **)(*plVar7 + 0x158))(plVar7,*(undefined8 *)(*plVar7 + 0x160));
    if (plVar12 == (long *)0x0) goto LAB_00dbbcbc;
LAB_00dbbc50:
    lVar9 = (**(code **)(*plVar12 + 0x158))(plVar12,*(undefined8 *)(*plVar12 + 0x160));
    if (plVar14 == (long *)0x0) goto LAB_00dbbcec;
LAB_00dbbc68:
    lVar8 = (**(code **)(*plVar14 + 0x158))(plVar14,*(undefined8 *)(*plVar14 + 0x160));
  }
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  if ((bRam0000000002be8bf3 & 1) == 0) {
    func_0x01978cf8(0x7544);
    bRam0000000002be8bf3 = 1;
  }
  if ((lVar10 == 0) || (*(int *)(lVar10 + 0x10) == 0)) {
    if ((lVar9 == 0) || (*(int *)(lVar9 + 0x10) == 0)) {
      if ((lVar8 != 0) && (*(int *)(lVar8 + 0x10) != 0)) {
        return lVar8;
      }
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      return **(long **)(_DAT_02bf5540 + 0xb8);
    }
    if ((lVar8 == 0) || (*(int *)(lVar8 + 0x10) == 0)) {
      return lVar9;
    }
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar10 = **(long **)(_DAT_02bf5540 + 0xb8);
    if (lVar10 == 0) {
      func_0x019a516c(0);
    }
    piVar18 = (int *)(lVar10 + 0x10);
    iVar5 = *piVar18;
  }
  else {
    if ((lVar9 != 0) && (*(int *)(lVar9 + 0x10) != 0)) {
      if ((lVar8 == 0) || (*(int *)(lVar8 + 0x10) == 0)) {
        if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar8 = **(long **)(_DAT_02bf5540 + 0xb8);
        piVar18 = (int *)(lVar10 + 0x10);
        iVar5 = *piVar18;
        piVar19 = (int *)(lVar9 + 0x10);
        iVar3 = *piVar19;
        if (lVar8 == 0) {
          func_0x019a516c(0);
        }
      }
      else {
        piVar18 = (int *)(lVar10 + 0x10);
        iVar5 = *piVar18;
        piVar19 = (int *)(lVar9 + 0x10);
        iVar3 = *piVar19;
      }
      goto LAB_00da502c;
    }
    if ((lVar8 == 0) || (*(int *)(lVar8 + 0x10) == 0)) {
      return lVar10;
    }
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar9 = **(long **)(_DAT_02bf5540 + 0xb8);
    piVar18 = (int *)(lVar10 + 0x10);
    iVar5 = *piVar18;
    if (lVar9 == 0) {
      func_0x019a516c(0);
    }
  }
  piVar19 = (int *)(lVar9 + 0x10);
  iVar3 = *piVar19;
LAB_00da502c:
  iVar4 = *(int *)(lVar8 + 0x10);
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  lVar6 = thunk_FUN_019c327c(iVar3 + iVar5 + iVar4);
  if (*piVar18 != 0) {
    iVar3 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar5 = *piVar18;
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    System_String__CharCopy(lVar6 + iVar3,lVar10 + iVar4,iVar5);
  }
  if (*piVar19 != 0) {
    iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar2 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar5 = *piVar18;
    iVar3 = *piVar19;
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    System_String__CharCopy(lVar6 + iVar4 + (long)(iVar5 << 1),lVar9 + iVar2,iVar3);
  }
  if (*(int *)(lVar8 + 0x10) != 0) {
    iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar2 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar5 = *piVar18;
    iVar3 = *piVar19;
    uVar1 = *(undefined4 *)(lVar8 + 0x10);
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    System_String__CharCopy
              (lVar6 + iVar4 + (long)(iVar5 << 1) + (long)(iVar3 << 1),lVar8 + iVar2,uVar1);
  }
  return lVar6;
}
