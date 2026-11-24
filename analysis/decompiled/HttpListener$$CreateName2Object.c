// HttpListener$$CreateName2Object @ RVA 0x1c80808

/* WARNING: Removing unreachable block (ram,0x011be1c4) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long HttpListener__CreateName2Object(undefined8 param_1,undefined8 param_2)

{
  int iVar1;
  long lVar2;
  ulong uVar3;
  long *plVar4;
  undefined8 uVar5;
  undefined8 uVar6;
  long lVar7;
  long *plVar8;
  long lVar9;
  long lVar10;
  undefined8 uVar11;
  long *plVar12;
  uint *puVar13;
  uint uVar14;
  undefined4 unaff_w25;
  long *unaff_x26;
  ulong uVar15;
  undefined1 auVar16 [16];
  undefined8 uStack_98;
  
  if ((bRam0000000002c49524 & 1) == 0) {
    func_0x01978cf8(0x3877);
    bRam0000000002c49524 = 1;
  }
  if (((*(byte *)(_DAT_02bf55e0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf55e0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar11 = func_0x0199e1ec(param_2,&UNK_020c7a74);
  plVar12 = (long *)System_Type__GetType(uVar11,0);
  if (plVar12 == (long *)0x0) {
    plVar12 = (long *)System_Type__GetType(param_2,0);
  }
  if ((bRam0000000002beab00 & 1) == 0) {
    func_0x01978cf8(0x436);
    bRam0000000002beab00 = 1;
  }
  System_Activator__CheckType(plVar12);
  if (plVar12 == (long *)0x0) {
    func_0x019a516c(0);
  }
  uVar3 = (**(code **)(*plVar12 + 0x6e8))(plVar12,*(undefined8 *)(*plVar12 + 0x6f0));
  if ((uVar3 & 1) == 0) {
    System_Activator__CheckAbstractType(plVar12);
    if ((*(byte *)(*plVar12 + 0x120) < *(byte *)(_DAT_02bf59c8 + 0x120)) ||
       (*(long *)(*(long *)(*plVar12 + 200) + (ulong)*(byte *)(_DAT_02bf59c8 + 0x120) * 8 + -8) !=
        _DAT_02bf59c8)) {
      if (((*(byte *)(_DAT_02bf55e0 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf55e0 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      plVar4 = (long *)System_Type__GetConstructor
                                 (plVar12,0x14,0,3,
                                  *(undefined8 *)(*(long *)(_DAT_02bf55e0 + 0xb8) + 8),0,0);
LAB_011bde9c:
      if (plVar4 != (long *)0x0) {
        if ((bRam0000000002be9a3d & 1) == 0) {
          func_0x01978cf8(0x1a67,0,0);
          bRam0000000002be9a3d = 1;
        }
        uVar11 = func_0x019b9d20(_DAT_02bf5738,0);
                    /* WARNING: Could not recover jumptable at 0x00f75cc8. Too many branches */
                    /* WARNING: Treating indirect jump as call */
        lVar2 = (**(code **)(*plVar4 + 0x318))
                          (plVar4,0x200,0,uVar11,0,*(undefined8 *)(*plVar4 + 800));
        return lVar2;
      }
    }
    else {
      plVar4 = (long *)System_MonoType__GetDefaultConstructor(plVar12,0);
      if ((plVar4 == (long *)0x0) ||
         (uVar3 = System_Reflection_MethodBase__get_IsPublic(plVar4,0), (uVar3 & 1) != 0))
      goto LAB_011bde9c;
    }
    uVar3 = System_Type__get_IsValueType(plVar12,0);
    if ((uVar3 & 1) != 0) {
      lVar2 = func_0x0196e19c(plVar12[2]);
      if (lVar2 == 0) {
        return 0;
      }
      func_0x0196e58c(lVar2);
      lVar2 = func_0x019b4464(lVar2);
      return lVar2;
    }
    uVar11 = Locale__GetText(_StringLiteral_977,0);  /* "Default constructor not found." */
    uVar5 = (**(code **)(*plVar12 + 0x248))(plVar12,*(undefined8 *)(*plVar12 + 0x250));
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c(_DAT_02bf5540);
    }
    uVar6 = System_String__Concat(_StringLiteral_978,uVar5,0);  /* ".ctor() of " */
    uVar5 = func_0x019b4464(_DAT_02bf59c0);
    System_MissingMethodException___ctor(uVar5,uVar11,uVar6,0);
  }
  else {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar11 = System_String__Concat(plVar12,_StringLiteral_976,0);  /* " is an open generic type" */
    uVar5 = func_0x019b4464(_DAT_02bf5670);
    System_ArgumentException___ctor(uVar5,uVar11,_StringLiteral_974);  /* "type" */
  }
  func_0x019a50dc(uVar5,0,_DAT_02c10b38);
  auVar16 = func_0x019da0a8();
  lVar2 = auVar16._8_8_;
  plVar12 = auVar16._0_8_;
  if ((bRam0000000002beaafd & 1) == 0) {
    func_0x01978cf8(0x434);
    bRam0000000002beaafd = 1;
  }
  lVar7 = func_0x019b9d20(_DAT_02bf5738,0);
  if ((bRam0000000002beaafe & 1) == 0) {
    func_0x01978cf8(0x435);
    bRam0000000002beaafe = 1;
  }
  if (((*(byte *)(_DAT_02bf59a8 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf59a8 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  plVar4 = (long *)System_Reflection_Binder__get_DefaultBinder(0);
  puVar13 = (uint *)0x0;
  if ((bRam0000000002beaaff & 1) == 0) {
    func_0x01978cf8(0x437);
    bRam0000000002beaaff = 1;
  }
  System_Activator__CheckType(plVar12);
  if (plVar12 == (long *)0x0) {
    func_0x019a516c(0);
  }
  uVar3 = (**(code **)(*plVar12 + 0x6e8))(plVar12,*(undefined8 *)(*plVar12 + 0x6f0));
  if ((uVar3 & 1) != 0) {
    if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    uVar11 = System_String__Concat(plVar12,_StringLiteral_976,0);  /* " is an open generic type" */
    uVar5 = func_0x019b4464(_DAT_02bf5670);
    System_ArgumentException___ctor(uVar5,uVar11,_StringLiteral_974);  /* "type" */
    goto LAB_011be628;
  }
  unaff_w25 = 0x14;
  if (lVar2 == 0) {
LAB_011be3dc:
    if (((*(byte *)(_DAT_02bf55e0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf55e0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    plVar8 = *(long **)(*(long *)(_DAT_02bf55e0 + 0xb8) + 8);
  }
  else {
    iVar1 = (int)*(ulong *)(lVar2 + 0x18);
    if (iVar1 == 0) goto LAB_011be3dc;
    uVar3 = *(ulong *)(lVar2 + 0x18) & 0xffffffff;
    plVar8 = (long *)func_0x019b9d20(_DAT_02bf59b0,uVar3);
    if (0 < iVar1) {
      uVar15 = 0;
      do {
        if (*(uint *)(lVar2 + 0x18) <= uVar15) {
          uVar11 = func_0x019a5e50();
          func_0x019a50dc(uVar11,0,0);
        }
        lVar9 = *(long *)(lVar2 + 0x20 + uVar15 * 8);
        if (lVar9 != 0) {
          if (*(uint *)(lVar2 + 0x18) <= uVar15) {
            uVar11 = func_0x019a5e50();
            func_0x019a50dc(uVar11,0,0);
            lVar9 = *(long *)(lVar2 + 0x20 + uVar15 * 8);
            if (lVar9 == 0) {
              func_0x019a516c();
              lVar9 = 0;
            }
          }
          lVar9 = System_Object__GetType(lVar9,0);
          if (plVar8 == (long *)0x0) {
            func_0x019a516c(0);
          }
          if ((lVar9 != 0) &&
             (lVar10 = func_0x019b46fc(lVar9,*(undefined8 *)(*plVar8 + 0x40)), lVar10 == 0)) {
            uVar11 = func_0x019a6488();
            func_0x019a50dc(uVar11,0,0);
          }
          if (*(uint *)(plVar8 + 3) <= uVar15) {
            uVar11 = func_0x019a5e50();
            func_0x019a50dc(uVar11,0,0);
          }
          plVar8[uVar15 + 4] = lVar9;
        }
        uVar15 = uVar15 + 1;
      } while (uVar3 != uVar15);
    }
  }
  if (plVar4 == (long *)0x0) {
    if (((*(byte *)(_DAT_02bf59a8 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf59a8 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    plVar4 = (long *)System_Reflection_Binder__get_DefaultBinder(0);
  }
  if (plVar12 == (long *)0x0) {
    func_0x019a516c(0);
  }
  puVar13 = (uint *)0x0;
  uVar11 = (**(code **)(*plVar12 + 0x6a8))(plVar12,0x14,*(undefined8 *)(*plVar12 + 0x6b0));
  if (plVar4 == (long *)0x0) {
    func_0x019a516c(0);
  }
  unaff_x26 = (long *)(**(code **)(*plVar4 + 0x198))
                                (plVar4,0x14,uVar11,plVar8,0,*(undefined8 *)(*plVar4 + 0x1a0));
  if (unaff_x26 != (long *)0x0) {
    lVar9 = *unaff_x26;
    if ((*(byte *)(_DAT_02bf59b8 + 0x120) <= *(byte *)(lVar9 + 0x120)) &&
       (*(long *)(*(long *)(lVar9 + 200) + (ulong)*(byte *)(_DAT_02bf59b8 + 0x120) * 8 + -8) ==
        _DAT_02bf59b8)) goto LAB_011be644;
    func_0x019d7df0(&uStack_98,*(undefined8 *)(lVar9 + 0x40));
    uVar11 = func_0x019a5e1c(uStack_98);
    func_0x019a50dc(uVar11,0,0);
    func_0x0208fe80(&uStack_98);
  }
  uVar3 = System_Type__get_IsValueType(plVar12,0);
  if ((uVar3 & 1) != 0) {
    if (plVar8 == (long *)0x0) {
      func_0x019a516c(0);
    }
    if ((int)plVar8[3] == 0) {
      lVar2 = FUN_019d841c(plVar12);
      return lVar2;
    }
  }
  puVar13 = (uint *)(plVar8 + 3);
  lVar9 = func_0x019b4464(_DAT_02bf5698);
  System_Text_StringBuilder___ctor(lVar9,0);
  unaff_w25 = 0x2c2bb08;
  unaff_x26 = (long *)&StringLiteral_845;  /* ", " */
  plVar4 = (long *)0x0;
  while( true ) {
    if (plVar8 == (long *)0x0) {
      func_0x019a516c(0);
    }
    uVar14 = (uint)plVar4;
    if ((int)*puVar13 <= (int)uVar14) break;
    if (*puVar13 <= uVar14) {
      uVar11 = func_0x019a5e50();
      func_0x019a50dc(uVar11,0,0);
    }
    plVar4 = (long *)plVar8[(long)(int)uVar14 + 4];
    if (plVar4 == (long *)0x0) {
      lVar2 = _StringLiteral_979;  /* "(unknown)" */
      if (lVar9 != 0) goto LAB_011be4bc;
LAB_011be4d8:
      func_0x019a516c(0);
      System_Text_StringBuilder__Append(lVar9,lVar2,0);
      func_0x019a516c(0);
    }
    else {
      lVar2 = (**(code **)(*plVar4 + 0x158))(plVar4,*(undefined8 *)(*plVar4 + 0x160));
      if (lVar9 == 0) goto LAB_011be4d8;
LAB_011be4bc:
      System_Text_StringBuilder__Append(lVar9,lVar2,0);
    }
    System_Text_StringBuilder__Append(lVar9,_StringLiteral_845,0);  /* ", " */
    plVar4 = (long *)(ulong)(uVar14 + 1);
  }
  if (lVar9 == 0) {
    func_0x019a516c(0);
  }
  iVar1 = System_Text_StringBuilder__get_Length(lVar9,0);
  if (2 < iVar1) {
    if (lVar9 == 0) {
      func_0x019a516c(0);
      iVar1 = System_Text_StringBuilder__get_Length(0,0);
      func_0x019a516c(0);
    }
    else {
      iVar1 = System_Text_StringBuilder__get_Length(lVar9,0);
    }
    System_Text_StringBuilder__set_Length(lVar9,iVar1 + -2,0);
  }
  uVar11 = Locale__GetText(_StringLiteral_980,0);  /* "No constructor found for {0}::.ctor({1})" */
  if (plVar12 == (long *)0x0) {
    func_0x019a516c(0);
  }
  uVar5 = (**(code **)(*plVar12 + 0x248))(plVar12,*(undefined8 *)(*plVar12 + 0x250));
  if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
    func_0x0198ba0c(_DAT_02bf5540);
  }
  uVar11 = System_String__Format(uVar11,uVar5,lVar9,0);
  uVar5 = func_0x019b4464(_DAT_02bf59c0);
  System_MissingMethodException___ctor(uVar5,uVar11,0);
LAB_011be628:
  while( true ) {
    auVar16._8_8_ = lVar2;
    auVar16._0_8_ = uVar11;
    func_0x019a50dc(uVar5,0,_DAT_02c10b40);
    func_0x019da0a8();
LAB_011be644:
    lVar2 = auVar16._8_8_;
    plVar12 = auVar16._0_8_;
    System_Activator__CheckAbstractType(plVar12);
    if ((lVar7 == 0) || (*(int *)(lVar7 + 0x18) < 1)) goto LAB_011be6b0;
    uVar3 = System_Type__get_IsMarshalByRef(plVar12,0);
    if ((uVar3 & 1) != 0) break;
    uVar11 = func_0x019b9d20(_DAT_02bf5738,1);
    func_0x009750d4(plVar12,0);
    uVar5 = (**(code **)(*plVar12 + 0x248))(plVar12,*(undefined8 *)(*plVar12 + 0x250));
    func_0x009750d4(uVar11,0);
    func_0x00a46d0c(uVar11,uVar5);
    func_0x00a54774(uVar11,0,uVar5);
    uVar11 = Locale__GetText(_StringLiteral_981,uVar11,0);  /* "Type '{0}' doesn't derive from MarshalByRefObject." */
    uVar5 = func_0x019b4464(_DAT_02bf5660);
    System_NotSupportedException___ctor(uVar5,uVar11,0);
  }
  lVar7 = System_Runtime_Remoting_Activation_ActivationServices__CreateProxyFromAttributes
                    (plVar12,lVar7,0);
  if (lVar7 != 0) {
    (**(code **)(*unaff_x26 + 0x248))
              (unaff_x26,lVar7,unaff_w25,plVar4,lVar2,puVar13,*(undefined8 *)(*unaff_x26 + 0x250));
    return lVar7;
  }
LAB_011be6b0:
                    /* WARNING: Could not recover jumptable at 0x011be6ec. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  lVar2 = (**(code **)(*unaff_x26 + 0x318))
                    (unaff_x26,unaff_w25,plVar4,lVar2,puVar13,*(undefined8 *)(*unaff_x26 + 800));
  return lVar2;
}
