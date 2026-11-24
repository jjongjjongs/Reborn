// Wellgames.Utils.GLLPHABKNEO$$MBKKJAKIPGD @ RVA 0x1cbbee4

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long Wellgames_Utils_GLLPHABKNEO__MBKKJAKIPGD(void)

{
  ushort uVar1;
  undefined1 *puVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  long lVar10;
  long lVar11;
  long *plVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  long lVar15;
  long lVar16;
  long lVar17;
  ushort *puVar18;
  ushort *puVar19;
  undefined8 unaff_x19;
  long unaff_x20;
  long unaff_x21;
  int *piVar20;
  undefined8 unaff_x22;
  int *piVar21;
  undefined8 unaff_x23;
  undefined8 unaff_x24;
  ulong uVar22;
  undefined8 unaff_x25;
  undefined8 unaff_x26;
  undefined8 unaff_x27;
  undefined8 unaff_x28;
  undefined1 *puVar23;
  undefined1 *unaff_x29;
  code *unaff_x30;
  undefined1 auVar24 [16];
  undefined1 auStack_b0 [128];
  
  lVar11 = Wellgames_Utils_GLLPHABKNEO__LEOGKIMMBKP();
  if ((bRam0000000002c49796 & 1) == 0) {
    func_0x01978cf8(0x314d);
    bRam0000000002c49796 = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  if (*(char *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x40) == '\x02') {
    if ((bRam0000000002c497a0 & 1) == 0) {
      func_0x01978cf8(0x314e);
      bRam0000000002c497a0 = 1;
    }
    if (lVar11 == 0) {
      func_0x019a516c(0);
    }
    uVar9 = System_String__get_Length(lVar11,0);
    func_0x019b9d20(_DAT_02bf5608,uVar9);
    if (((*(byte *)(_DAT_02bf56a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf56a0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    plVar12 = (long *)System_Text_Encoding__get_UTF8(0);
    if (plVar12 == (long *)0x0) {
      func_0x019a516c(0);
    }
    uVar13 = (**(code **)(*plVar12 + 0x1c8))(plVar12,lVar11,*(undefined8 *)(*plVar12 + 0x1d0));
    if (((*(byte *)(_DAT_02bf55c0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf55c0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar11 = System_Convert__ToBase64String(uVar13,0);
    return lVar11;
  }
  puVar2 = auStack_b0 + 0x80;
  if ((bRam0000000002c49799 & 1) == 0) {
    func_0x01978cf8(0x3155);
    bRam0000000002c49799 = 1;
  }
  lVar11 = Wellgames_Utils_GLLPHABKNEO__CONLOCNPPGP(lVar11);
  uVar13 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar13,_DAT_02c29f98,0);  /* dec: '=' */
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar13 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar13,0,0);
  uVar14 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar14,_DAT_02c29fa8,0);  /* dec: '%3D' */
  uVar14 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar14,0,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  lVar11 = System_String__Replace(lVar11,uVar13,uVar14,0);
  uVar13 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar13,_DAT_02c29fb0,0);  /* dec: '+' */
  uVar13 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar13,0,0);
  uVar14 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar14,_DAT_02c29fb8,0);  /* dec: '%2B' */
  uVar14 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar14,0,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  lVar11 = System_String__Replace(lVar11,uVar13,uVar14,0);
  uVar13 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar13,_DAT_02c29fc0,0);  /* dec: '/' */
  lVar15 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar13,0,0);
  auVar24._8_8_ = lVar15;
  auVar24._0_8_ = lVar11;
  uVar13 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar13,_DAT_02c29fc8,0);  /* dec: '%2F' */
  lVar16 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar13,0,0);
  if (lVar11 == 0) {
    func_0x019a516c(0);
  }
  puVar23 = auStack_b0 + 0xa0;
  uVar13 = 0x2be8000;
  if ((bRam0000000002be8bdf & 1) == 0) {
    func_0x01978cf8(0x757b,lVar15,lVar16,0);
    bRam0000000002be8bdf = 1;
  }
  if (lVar15 == 0) {
    unaff_x19 = func_0x019b4464(_DAT_02bf5658);
    System_ArgumentNullException___ctor(unaff_x19,_StringLiteral_11393,0);  /* "oldValue" */
  }
  else {
    if (*(int *)(lVar15 + 0x10) != 0) {
      if (*(int *)(lVar11 + 0x10) == 0) {
        return lVar11;
      }
      lVar15 = lVar16;
      if (lVar16 == 0) {
        if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar15 = **(long **)(_DAT_02bf5540 + 0xb8);
      }
      puVar2 = (undefined1 *)register0x00000008;
      lVar11 = unaff_x20;
      lVar16 = unaff_x21;
      uVar13 = unaff_x22;
      puVar23 = unaff_x29;
      goto code_r0x00dc0c38;
    }
    unaff_x19 = func_0x019b4464(_DAT_02bf5670);
    System_ArgumentException___ctor(unaff_x19,_StringLiteral_11394,0);  /* "oldValue is the empty string." */
  }
  lVar15 = _DAT_02c125e0;
  func_0x019a50dc(unaff_x19,0);
  unaff_x30 = System_String__ReplaceUnchecked;
  auVar24 = func_0x019da0a8();
code_r0x00dc0c38:
  lVar17 = auVar24._8_8_;
  lVar10 = auVar24._0_8_;
  *(undefined8 *)(puVar2 + -0x60) = unaff_x28;
  *(undefined8 *)(puVar2 + -0x58) = unaff_x27;
  *(undefined8 *)(puVar2 + -0x50) = unaff_x26;
  *(undefined8 *)(puVar2 + -0x48) = unaff_x25;
  *(undefined8 *)(puVar2 + -0x40) = unaff_x24;
  *(undefined8 *)(puVar2 + -0x38) = unaff_x23;
  *(undefined8 *)(puVar2 + -0x30) = uVar13;
  *(long *)(puVar2 + -0x28) = lVar16;
  *(long *)(puVar2 + -0x20) = lVar11;
  *(undefined8 *)(puVar2 + -0x18) = unaff_x19;
  *(undefined1 **)(puVar2 + -0x10) = puVar23;
  *(code **)(puVar2 + -8) = unaff_x30;
  if ((bRam0000000002be8be0 & 1) == 0) {
    func_0x01978cf8(0x7579);
    bRam0000000002be8be0 = 1;
  }
  if (lVar17 == 0) {
    func_0x019a516c(0);
  }
  lVar11 = lVar10;
  if (*(int *)(lVar17 + 0x10) <= *(int *)(lVar10 + 0x10)) {
    if (*(int *)(lVar17 + 0x10) == 1) {
      if (lVar15 == 0) {
        func_0x019a516c(0);
      }
      if (*(int *)(lVar15 + 0x10) == 1) {
        uVar5 = System_String__get_Chars(lVar17,0);
        uVar6 = System_String__get_Chars(lVar15,0);
        *(undefined8 *)(puVar2 + -0x50) = *(undefined8 *)(puVar2 + -0x50);
        *(undefined8 *)(puVar2 + -0x48) = *(undefined8 *)(puVar2 + -0x48);
        *(undefined8 *)(puVar2 + -0x40) = *(undefined8 *)(puVar2 + -0x40);
        *(undefined8 *)(puVar2 + -0x38) = *(undefined8 *)(puVar2 + -0x38);
        *(undefined8 *)(puVar2 + -0x30) = *(undefined8 *)(puVar2 + -0x30);
        *(undefined8 *)(puVar2 + -0x28) = *(undefined8 *)(puVar2 + -0x28);
        *(undefined8 *)(puVar2 + -0x20) = *(undefined8 *)(puVar2 + -0x20);
        *(undefined8 *)(puVar2 + -0x18) = *(undefined8 *)(puVar2 + -0x18);
        *(undefined8 *)(puVar2 + -0x10) = *(undefined8 *)(puVar2 + -0x10);
        *(undefined8 *)(puVar2 + -8) = *(undefined8 *)(puVar2 + -8);
        if ((bRam0000000002be8bde & 1) == 0) {
          func_0x01978cf8(0x757a);
          bRam0000000002be8bde = 1;
        }
        if ((((uVar5 & 0xffff) != (uVar6 & 0xffff)) && (iVar4 = *(int *)(lVar10 + 0x10), iVar4 != 0)
            ) && (iVar3 = System_String__IndexOfUnchecked(lVar10,uVar5,0,iVar4), iVar3 != -1)) {
          if (iVar3 < 4) {
            iVar3 = 0;
          }
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          lVar11 = thunk_FUN_019c327c(iVar4);
          iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
          if (iVar3 != 0) {
            if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
               (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
              func_0x0198ba0c();
            }
            System_String__CharCopy(lVar11 + iVar4,lVar10 + 0x14,iVar3);
          }
          lVar16 = (long)(iVar3 << 1);
          iVar7 = *(int *)(lVar10 + 0x10) << 1;
          if (lVar16 != iVar7) {
            lVar15 = iVar7 - lVar16;
            puVar18 = (ushort *)(lVar11 + iVar4 + (long)(iVar3 << 1));
            puVar19 = (ushort *)(lVar16 + lVar10 + 0x14);
            do {
              lVar15 = lVar15 + -2;
              uVar1 = (ushort)uVar6;
              if ((uint)*puVar19 != (uVar5 & 0xffff)) {
                uVar1 = *puVar19;
              }
              *puVar18 = uVar1;
              puVar18 = puVar18 + 1;
              puVar19 = puVar19 + 1;
            } while (lVar15 != 0);
          }
        }
        return lVar11;
      }
    }
    piVar20 = (int *)(puVar2 + -0x3a0);
    func_0x00972e60(piVar20,0,800);
    iVar3 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar7 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar4 = *(int *)(lVar10 + 0x10);
    if (0 < iVar4) {
      uVar22 = 0;
      iVar8 = 0;
      *(long *)(puVar2 + -0x68) = lVar10 + iVar3;
      *(long *)(puVar2 + -0x70) = lVar15 + iVar7;
      piVar21 = piVar20;
      do {
        iVar8 = System_String__IndexOfOrdinalUnchecked(lVar10,lVar17,iVar8,iVar4 - iVar8);
        if (iVar8 < 0) {
          if ((int)uVar22 == 0) {
            return lVar10;
          }
          break;
        }
        if (199 < (long)uVar22) {
          lVar11 = System_String__ReplaceFallback(lVar10,lVar17,lVar15,200);
          return lVar11;
        }
        *piVar21 = iVar8;
        iVar4 = *(int *)(lVar10 + 0x10);
        uVar22 = uVar22 + 1;
        iVar8 = *(int *)(lVar17 + 0x10) + iVar8;
        piVar21 = piVar21 + 1;
      } while (iVar8 < iVar4);
      iVar4 = *(int *)(lVar10 + 0x10);
      if (lVar15 == 0) {
        func_0x019a516c(0);
      }
      iVar3 = *(int *)(lVar17 + 0x10);
      iVar7 = *(int *)(lVar15 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      lVar11 = thunk_FUN_019c327c(iVar4 + (iVar7 - iVar3) * (int)uVar22);
      iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
      lVar16 = lVar11 + iVar4;
      if ((int)uVar22 < 1) {
        iVar4 = 0;
        lVar15 = 0;
      }
      else {
        iVar3 = 0;
        iVar7 = 0;
        iVar4 = 0;
        uVar22 = uVar22 & 0xffffffff;
        *(long *)(puVar2 + -0x78) = lVar11;
        do {
          iVar8 = *(int *)((long)piVar20 + (long)iVar3) - iVar4;
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          System_String__CharCopy
                    (lVar16 + (iVar7 << 1),*(long *)(puVar2 + -0x68) + (long)(iVar4 << 1),iVar8);
          iVar8 = iVar8 + iVar7;
          iVar4 = *(int *)(lVar17 + 0x10) + *(int *)((long)piVar20 + (long)iVar3);
          System_String__CharCopy
                    (lVar16 + iVar8 * 2,*(undefined8 *)(puVar2 + -0x70),
                     *(undefined4 *)(lVar15 + 0x10));
          uVar22 = uVar22 - 1;
          iVar7 = *(int *)(lVar15 + 0x10) + iVar8;
          iVar3 = iVar3 + 4;
        } while (uVar22 != 0);
        lVar11 = *(long *)(puVar2 + -0x78);
        lVar15 = (long)(iVar7 * 2);
      }
      iVar3 = *(int *)(lVar10 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      System_String__CharCopy
                (lVar16 + lVar15,*(long *)(puVar2 + -0x68) + (long)(iVar4 << 1),iVar3 - iVar4);
    }
  }
  return lVar11;
}
