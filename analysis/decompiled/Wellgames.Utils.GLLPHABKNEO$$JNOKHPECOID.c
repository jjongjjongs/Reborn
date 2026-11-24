// Wellgames.Utils.GLLPHABKNEO$$JNOKHPECOID @ RVA 0x1cb9c68

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long Wellgames_Utils_GLLPHABKNEO__JNOKHPECOID(long param_1)

{
  long lVar1;
  ushort uVar2;
  undefined1 *puVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  long lVar10;
  long lVar11;
  long lVar12;
  ushort *puVar13;
  ushort *puVar14;
  undefined8 unaff_x19;
  long unaff_x20;
  long lVar15;
  long unaff_x21;
  undefined8 uVar16;
  int *piVar17;
  undefined8 unaff_x22;
  int *piVar18;
  undefined8 unaff_x23;
  undefined8 unaff_x24;
  ulong uVar19;
  undefined8 unaff_x25;
  undefined8 unaff_x26;
  undefined8 unaff_x27;
  undefined8 unaff_x28;
  undefined1 *puVar20;
  undefined1 *unaff_x29;
  code *unaff_x30;
  undefined1 auVar21 [16];
  undefined1 auStack_b0 [128];
  
  puVar3 = auStack_b0 + 0x80;
  lVar11 = Wellgames_Utils_GLLPHABKNEO__OCOEIBNMPBK();
  lVar12 = Wellgames_Manager__get_SFRUUF9NRDU(0);
  if (param_1 == 0) {
    func_0x019a516c(0);
  }
  puVar20 = auStack_b0 + 0xa0;
  uVar16 = 0x2be8000;
  if ((bRam0000000002be8bdf & 1) == 0) {
    func_0x01978cf8(0x757b,lVar12,lVar11,0);
    bRam0000000002be8bdf = 1;
  }
  if (lVar12 == 0) {
    unaff_x19 = func_0x019b4464(_DAT_02bf5658);
    System_ArgumentNullException___ctor(unaff_x19,_StringLiteral_11393,0);  /* "oldValue" */
  }
  else {
    if (*(int *)(lVar12 + 0x10) != 0) {
      if (*(int *)(param_1 + 0x10) == 0) {
        return param_1;
      }
      lVar15 = lVar11;
      if (lVar11 == 0) {
        if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar15 = **(long **)(_DAT_02bf5540 + 0xb8);
      }
      puVar3 = (undefined1 *)register0x00000008;
      lVar10 = param_1;
      param_1 = unaff_x20;
      lVar11 = unaff_x21;
      uVar16 = unaff_x22;
      puVar20 = unaff_x29;
      goto code_r0x00dc0c38;
    }
    unaff_x19 = func_0x019b4464(_DAT_02bf5670);
    System_ArgumentException___ctor(unaff_x19,_StringLiteral_11394,0);  /* "oldValue is the empty string." */
  }
  lVar15 = _DAT_02c125e0;
  func_0x019a50dc(unaff_x19,0);
  unaff_x30 = System_String__ReplaceUnchecked;
  auVar21 = func_0x019da0a8();
  lVar12 = auVar21._8_8_;
  lVar10 = auVar21._0_8_;
code_r0x00dc0c38:
  *(undefined8 *)(puVar3 + -0x60) = unaff_x28;
  *(undefined8 *)(puVar3 + -0x58) = unaff_x27;
  *(undefined8 *)(puVar3 + -0x50) = unaff_x26;
  *(undefined8 *)(puVar3 + -0x48) = unaff_x25;
  *(undefined8 *)(puVar3 + -0x40) = unaff_x24;
  *(undefined8 *)(puVar3 + -0x38) = unaff_x23;
  *(undefined8 *)(puVar3 + -0x30) = uVar16;
  *(long *)(puVar3 + -0x28) = lVar11;
  *(long *)(puVar3 + -0x20) = param_1;
  *(undefined8 *)(puVar3 + -0x18) = unaff_x19;
  *(undefined1 **)(puVar3 + -0x10) = puVar20;
  *(code **)(puVar3 + -8) = unaff_x30;
  if ((bRam0000000002be8be0 & 1) == 0) {
    func_0x01978cf8(0x7579);
    bRam0000000002be8be0 = 1;
  }
  if (lVar12 == 0) {
    func_0x019a516c(0);
  }
  lVar11 = lVar10;
  if (*(int *)(lVar12 + 0x10) <= *(int *)(lVar10 + 0x10)) {
    if (*(int *)(lVar12 + 0x10) == 1) {
      if (lVar15 == 0) {
        func_0x019a516c(0);
      }
      if (*(int *)(lVar15 + 0x10) == 1) {
        uVar6 = System_String__get_Chars(lVar12,0);
        uVar7 = System_String__get_Chars(lVar15,0);
        *(undefined8 *)(puVar3 + -0x50) = *(undefined8 *)(puVar3 + -0x50);
        *(undefined8 *)(puVar3 + -0x48) = *(undefined8 *)(puVar3 + -0x48);
        *(undefined8 *)(puVar3 + -0x40) = *(undefined8 *)(puVar3 + -0x40);
        *(undefined8 *)(puVar3 + -0x38) = *(undefined8 *)(puVar3 + -0x38);
        *(undefined8 *)(puVar3 + -0x30) = *(undefined8 *)(puVar3 + -0x30);
        *(undefined8 *)(puVar3 + -0x28) = *(undefined8 *)(puVar3 + -0x28);
        *(undefined8 *)(puVar3 + -0x20) = *(undefined8 *)(puVar3 + -0x20);
        *(undefined8 *)(puVar3 + -0x18) = *(undefined8 *)(puVar3 + -0x18);
        *(undefined8 *)(puVar3 + -0x10) = *(undefined8 *)(puVar3 + -0x10);
        *(undefined8 *)(puVar3 + -8) = *(undefined8 *)(puVar3 + -8);
        if ((bRam0000000002be8bde & 1) == 0) {
          func_0x01978cf8(0x757a);
          bRam0000000002be8bde = 1;
        }
        if ((((uVar6 & 0xffff) != (uVar7 & 0xffff)) && (iVar5 = *(int *)(lVar10 + 0x10), iVar5 != 0)
            ) && (iVar4 = System_String__IndexOfUnchecked(lVar10,uVar6,0,iVar5), iVar4 != -1)) {
          if (iVar4 < 4) {
            iVar4 = 0;
          }
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          lVar11 = thunk_FUN_019c327c(iVar5);
          iVar5 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
          if (iVar4 != 0) {
            if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
               (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
              func_0x0198ba0c();
            }
            System_String__CharCopy(lVar11 + iVar5,lVar10 + 0x14,iVar4);
          }
          lVar12 = (long)(iVar4 << 1);
          iVar8 = *(int *)(lVar10 + 0x10) << 1;
          if (lVar12 != iVar8) {
            lVar15 = iVar8 - lVar12;
            puVar13 = (ushort *)(lVar11 + iVar5 + (long)(iVar4 << 1));
            puVar14 = (ushort *)(lVar12 + lVar10 + 0x14);
            do {
              lVar15 = lVar15 + -2;
              uVar2 = (ushort)uVar7;
              if ((uint)*puVar14 != (uVar6 & 0xffff)) {
                uVar2 = *puVar14;
              }
              *puVar13 = uVar2;
              puVar13 = puVar13 + 1;
              puVar14 = puVar14 + 1;
            } while (lVar15 != 0);
          }
        }
        return lVar11;
      }
    }
    piVar17 = (int *)(puVar3 + -0x3a0);
    func_0x00972e60(piVar17,0,800);
    iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar8 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar5 = *(int *)(lVar10 + 0x10);
    if (0 < iVar5) {
      uVar19 = 0;
      iVar9 = 0;
      *(long *)(puVar3 + -0x68) = lVar10 + iVar4;
      *(long *)(puVar3 + -0x70) = lVar15 + iVar8;
      piVar18 = piVar17;
      do {
        iVar9 = System_String__IndexOfOrdinalUnchecked(lVar10,lVar12,iVar9,iVar5 - iVar9);
        if (iVar9 < 0) {
          if ((int)uVar19 == 0) {
            return lVar10;
          }
          break;
        }
        if (199 < (long)uVar19) {
          lVar11 = System_String__ReplaceFallback(lVar10,lVar12,lVar15,200);
          return lVar11;
        }
        *piVar18 = iVar9;
        iVar5 = *(int *)(lVar10 + 0x10);
        uVar19 = uVar19 + 1;
        iVar9 = *(int *)(lVar12 + 0x10) + iVar9;
        piVar18 = piVar18 + 1;
      } while (iVar9 < iVar5);
      iVar5 = *(int *)(lVar10 + 0x10);
      if (lVar15 == 0) {
        func_0x019a516c(0);
      }
      iVar4 = *(int *)(lVar12 + 0x10);
      iVar8 = *(int *)(lVar15 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      lVar11 = thunk_FUN_019c327c(iVar5 + (iVar8 - iVar4) * (int)uVar19);
      iVar5 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
      lVar1 = lVar11 + iVar5;
      if ((int)uVar19 < 1) {
        iVar5 = 0;
        lVar12 = 0;
      }
      else {
        iVar4 = 0;
        iVar8 = 0;
        iVar5 = 0;
        uVar19 = uVar19 & 0xffffffff;
        *(long *)(puVar3 + -0x78) = lVar11;
        do {
          iVar9 = *(int *)((long)piVar17 + (long)iVar4) - iVar5;
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          System_String__CharCopy
                    (lVar1 + (iVar8 << 1),*(long *)(puVar3 + -0x68) + (long)(iVar5 << 1),iVar9);
          iVar9 = iVar9 + iVar8;
          iVar5 = *(int *)(lVar12 + 0x10) + *(int *)((long)piVar17 + (long)iVar4);
          System_String__CharCopy
                    (lVar1 + iVar9 * 2,*(undefined8 *)(puVar3 + -0x70),
                     *(undefined4 *)(lVar15 + 0x10));
          uVar19 = uVar19 - 1;
          iVar8 = *(int *)(lVar15 + 0x10) + iVar9;
          iVar4 = iVar4 + 4;
        } while (uVar19 != 0);
        lVar11 = *(long *)(puVar3 + -0x78);
        lVar12 = (long)(iVar8 * 2);
      }
      iVar4 = *(int *)(lVar10 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      System_String__CharCopy
                (lVar1 + lVar12,*(long *)(puVar3 + -0x68) + (long)(iVar5 << 1),iVar4 - iVar5);
    }
  }
  return lVar11;
}
