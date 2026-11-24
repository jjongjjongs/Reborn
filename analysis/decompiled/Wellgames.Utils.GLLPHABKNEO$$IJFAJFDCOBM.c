// Wellgames.Utils.GLLPHABKNEO$$IJFAJFDCOBM @ RVA 0x1cbba0c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long Wellgames_Utils_GLLPHABKNEO__IJFAJFDCOBM(long param_1)

{
  ushort uVar1;
  undefined1 *puVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar9;
  uint uVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  long lVar10;
  undefined8 uVar11;
  long lVar12;
  long lVar13;
  long *plVar14;
  undefined8 uVar15;
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
  
  if ((bRam0000000002c49791 & 1) == 0) {
    func_0x01978cf8(0x3154);
    bRam0000000002c49791 = 1;
  }
  if (((*(byte *)(_DAT_02bfcec0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfcec0 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  if (*(char *)(*(long *)(_DAT_02bfcec0 + 0xb8) + 0x40) == '\x03') {
    if ((bRam0000000002c4979c & 1) == 0) {
      func_0x01978cf8(0x315d);
      bRam0000000002c4979c = 1;
    }
    if (param_1 == 0) {
      func_0x019a516c(0);
    }
    uVar9 = System_String__get_Length(param_1,0);
    func_0x019b9d20(_DAT_02bf5608,uVar9);
    if (((*(byte *)(_DAT_02bf56a0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf56a0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    plVar14 = (long *)System_Text_Encoding__get_UTF8(0);
    if (plVar14 == (long *)0x0) {
      func_0x019a516c(0);
    }
    uVar15 = (**(code **)(*plVar14 + 0x1c8))(plVar14,param_1,*(undefined8 *)(*plVar14 + 0x1d0));
    if (((*(byte *)(_DAT_02bf55c0 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bf55c0 + 0xd8) == 0))
    {
      func_0x0198ba0c();
    }
    lVar16 = System_Convert__ToBase64String(uVar15,0);
    return lVar16;
  }
  puVar2 = auStack_b0 + 0x80;
  if ((bRam0000000002c49790 & 1) == 0) {
    func_0x01978cf8(0x3150);
    bRam0000000002c49790 = 1;
  }
  lVar16 = Wellgames_Utils_GLLPHABKNEO__NNLLEHJOGGB(param_1);
  uVar15 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar15,_DAT_02c29f28,0);  /* dec: 'com.unity3d.player.UnityPlayer' */
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar15 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar15,0,0);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c29f30,0);  /* dec: 'versionCode' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  if (lVar16 == 0) {
    func_0x019a516c(0);
  }
  lVar16 = System_String__Replace(lVar16,uVar15,uVar11,0);
  uVar15 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar15,_DAT_02c29f38,0);  /* dec: 'com.unity3d.player.UnityPlayer' */
  uVar15 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar15,0,0);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c29f50,0);  /* dec: 'currentActivity' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  if (lVar16 == 0) {
    func_0x019a516c(0);
  }
  lVar16 = System_String__Replace(lVar16,uVar15,uVar11,0);
  uVar15 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar15,_DAT_02c29f58,0);  /* dec: 'PACKAGE_UPDATE_1' */
  lVar12 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar15,0,0);
  auVar24._8_8_ = lVar12;
  auVar24._0_8_ = lVar16;
  uVar15 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar15,_DAT_02c29f60,0);  /* dec: 'PACKAGE_UPDATE' */
  lVar13 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar15,0,0);
  if (lVar16 == 0) {
    func_0x019a516c(0);
  }
  puVar23 = auStack_b0 + 0xa0;
  uVar15 = 0x2be8000;
  if ((bRam0000000002be8bdf & 1) == 0) {
    func_0x01978cf8(0x757b,lVar12,lVar13,0);
    bRam0000000002be8bdf = 1;
  }
  if (lVar12 == 0) {
    unaff_x19 = func_0x019b4464(_DAT_02bf5658);
    System_ArgumentNullException___ctor(unaff_x19,_StringLiteral_11393,0);  /* "oldValue" */
  }
  else {
    if (*(int *)(lVar12 + 0x10) != 0) {
      if (*(int *)(lVar16 + 0x10) == 0) {
        return lVar16;
      }
      lVar12 = lVar13;
      if (lVar13 == 0) {
        if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar12 = **(long **)(_DAT_02bf5540 + 0xb8);
      }
      puVar2 = (undefined1 *)register0x00000008;
      lVar16 = unaff_x20;
      lVar13 = unaff_x21;
      uVar15 = unaff_x22;
      puVar23 = unaff_x29;
      goto code_r0x00dc0c38;
    }
    unaff_x19 = func_0x019b4464(_DAT_02bf5670);
    System_ArgumentException___ctor(unaff_x19,_StringLiteral_11394,0);  /* "oldValue is the empty string." */
  }
  lVar12 = _DAT_02c125e0;
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
  *(undefined8 *)(puVar2 + -0x30) = uVar15;
  *(long *)(puVar2 + -0x28) = lVar13;
  *(long *)(puVar2 + -0x20) = lVar16;
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
  lVar16 = lVar10;
  if (*(int *)(lVar17 + 0x10) <= *(int *)(lVar10 + 0x10)) {
    if (*(int *)(lVar17 + 0x10) == 1) {
      if (lVar12 == 0) {
        func_0x019a516c(0);
      }
      if (*(int *)(lVar12 + 0x10) == 1) {
        uVar5 = System_String__get_Chars(lVar17,0);
        uVar6 = System_String__get_Chars(lVar12,0);
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
          lVar16 = thunk_FUN_019c327c(iVar4);
          iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
          if (iVar3 != 0) {
            if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
               (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
              func_0x0198ba0c();
            }
            System_String__CharCopy(lVar16 + iVar4,lVar10 + 0x14,iVar3);
          }
          lVar13 = (long)(iVar3 << 1);
          iVar7 = *(int *)(lVar10 + 0x10) << 1;
          if (lVar13 != iVar7) {
            lVar12 = iVar7 - lVar13;
            puVar18 = (ushort *)(lVar16 + iVar4 + (long)(iVar3 << 1));
            puVar19 = (ushort *)(lVar13 + lVar10 + 0x14);
            do {
              lVar12 = lVar12 + -2;
              uVar1 = (ushort)uVar6;
              if ((uint)*puVar19 != (uVar5 & 0xffff)) {
                uVar1 = *puVar19;
              }
              *puVar18 = uVar1;
              puVar18 = puVar18 + 1;
              puVar19 = puVar19 + 1;
            } while (lVar12 != 0);
          }
        }
        return lVar16;
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
      *(long *)(puVar2 + -0x70) = lVar12 + iVar7;
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
          lVar16 = System_String__ReplaceFallback(lVar10,lVar17,lVar12,200);
          return lVar16;
        }
        *piVar21 = iVar8;
        iVar4 = *(int *)(lVar10 + 0x10);
        uVar22 = uVar22 + 1;
        iVar8 = *(int *)(lVar17 + 0x10) + iVar8;
        piVar21 = piVar21 + 1;
      } while (iVar8 < iVar4);
      iVar4 = *(int *)(lVar10 + 0x10);
      if (lVar12 == 0) {
        func_0x019a516c(0);
      }
      iVar3 = *(int *)(lVar17 + 0x10);
      iVar7 = *(int *)(lVar12 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      lVar16 = thunk_FUN_019c327c(iVar4 + (iVar7 - iVar3) * (int)uVar22);
      iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
      lVar13 = lVar16 + iVar4;
      if ((int)uVar22 < 1) {
        iVar4 = 0;
        lVar12 = 0;
      }
      else {
        iVar3 = 0;
        iVar7 = 0;
        iVar4 = 0;
        uVar22 = uVar22 & 0xffffffff;
        *(long *)(puVar2 + -0x78) = lVar16;
        do {
          iVar8 = *(int *)((long)piVar20 + (long)iVar3) - iVar4;
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          System_String__CharCopy
                    (lVar13 + (iVar7 << 1),*(long *)(puVar2 + -0x68) + (long)(iVar4 << 1),iVar8);
          iVar8 = iVar8 + iVar7;
          iVar4 = *(int *)(lVar17 + 0x10) + *(int *)((long)piVar20 + (long)iVar3);
          System_String__CharCopy
                    (lVar13 + iVar8 * 2,*(undefined8 *)(puVar2 + -0x70),
                     *(undefined4 *)(lVar12 + 0x10));
          uVar22 = uVar22 - 1;
          iVar7 = *(int *)(lVar12 + 0x10) + iVar8;
          iVar3 = iVar3 + 4;
        } while (uVar22 != 0);
        lVar16 = *(long *)(puVar2 + -0x78);
        lVar12 = (long)(iVar7 * 2);
      }
      iVar3 = *(int *)(lVar10 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      System_String__CharCopy
                (lVar13 + lVar12,*(long *)(puVar2 + -0x68) + (long)(iVar4 << 1),iVar3 - iVar4);
    }
  }
  return lVar16;
}
