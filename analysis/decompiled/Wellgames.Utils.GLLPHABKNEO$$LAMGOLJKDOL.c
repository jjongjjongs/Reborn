// Wellgames.Utils.GLLPHABKNEO$$LAMGOLJKDOL @ RVA 0x1cbcb9c

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long Wellgames_Utils_GLLPHABKNEO__LAMGOLJKDOL(undefined8 param_1)

{
  ushort uVar1;
  undefined1 *puVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  long lVar9;
  long lVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  long lVar13;
  long lVar14;
  long lVar15;
  ushort *puVar16;
  ushort *puVar17;
  undefined8 unaff_x19;
  long unaff_x20;
  long unaff_x21;
  int *piVar18;
  undefined8 unaff_x22;
  int *piVar19;
  undefined8 unaff_x23;
  undefined8 unaff_x24;
  ulong uVar20;
  undefined8 unaff_x25;
  undefined8 unaff_x26;
  undefined8 unaff_x27;
  undefined8 unaff_x28;
  undefined1 *puVar21;
  undefined1 *unaff_x29;
  code *unaff_x30;
  undefined1 auVar22 [16];
  undefined1 auStack_b0 [128];
  
  puVar2 = auStack_b0 + 0x80;
  if ((bRam0000000002c4979f & 1) == 0) {
    func_0x01978cf8(0x3157);
    bRam0000000002c4979f = 1;
  }
  lVar10 = Wellgames_Utils_GLLPHABKNEO__OAFIPNKODLN(param_1);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a008,0);  /* dec: '#WEB_179' */
  if (((*(byte *)(_DAT_02bfc200 + 0x126) >> 1 & 1) != 0) && (*(int *)(_DAT_02bfc200 + 0xd8) == 0)) {
    func_0x0198ba0c();
  }
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  uVar12 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar12,_DAT_02c2a010,0);  /* dec: 'geRunningApp' */
  uVar12 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar12,0,0);
  if (lVar10 == 0) {
    func_0x019a516c(0);
  }
  lVar10 = System_String__Replace(lVar10,uVar11,uVar12,0);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a018,0);  /* dec: 'NO' */
  uVar11 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  uVar12 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar12,_DAT_02c2a020,0);  /* dec: 'MSG_TITLE_PURCHASE_ERROR' */
  uVar12 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar12,0,0);
  if (lVar10 == 0) {
    func_0x019a516c(0);
  }
  lVar10 = System_String__Replace(lVar10,uVar11,uVar12,0);
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a028,0);  /* dec: 'versionName' */
  lVar13 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  auVar22._8_8_ = lVar13;
  auVar22._0_8_ = lVar10;
  uVar11 = func_0x019b9d20(_DAT_02bf5608,0x80);
  System_Runtime_CompilerServices_RuntimeHelpers__InitializeArray(uVar11,_DAT_02c2a030,0);  /* dec: 'MESSAGE' */
  lVar14 = <PrivateImplementationDetails>_F4B7C4DC_7006_4C08_9283_F3F0DDD65116__NLNPLGOEHOB__NECOKEIHMKL
                     (uVar11,0,0);
  if (lVar10 == 0) {
    func_0x019a516c(0);
  }
  puVar21 = auStack_b0 + 0xa0;
  uVar11 = 0x2be8000;
  if ((bRam0000000002be8bdf & 1) == 0) {
    func_0x01978cf8(0x757b,lVar13,lVar14,0);
    bRam0000000002be8bdf = 1;
  }
  if (lVar13 == 0) {
    unaff_x19 = func_0x019b4464(_DAT_02bf5658);
    System_ArgumentNullException___ctor(unaff_x19,_StringLiteral_11393,0);  /* "oldValue" */
  }
  else {
    if (*(int *)(lVar13 + 0x10) != 0) {
      if (*(int *)(lVar10 + 0x10) == 0) {
        return lVar10;
      }
      lVar13 = lVar14;
      if (lVar14 == 0) {
        if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
           (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
          func_0x0198ba0c();
        }
        lVar13 = **(long **)(_DAT_02bf5540 + 0xb8);
      }
      puVar2 = (undefined1 *)register0x00000008;
      lVar10 = unaff_x20;
      lVar14 = unaff_x21;
      uVar11 = unaff_x22;
      puVar21 = unaff_x29;
      goto code_r0x00dc0c38;
    }
    unaff_x19 = func_0x019b4464(_DAT_02bf5670);
    System_ArgumentException___ctor(unaff_x19,_StringLiteral_11394,0);  /* "oldValue is the empty string." */
  }
  lVar13 = _DAT_02c125e0;
  func_0x019a50dc(unaff_x19,0);
  unaff_x30 = System_String__ReplaceUnchecked;
  auVar22 = func_0x019da0a8();
code_r0x00dc0c38:
  lVar15 = auVar22._8_8_;
  lVar9 = auVar22._0_8_;
  *(undefined8 *)(puVar2 + -0x60) = unaff_x28;
  *(undefined8 *)(puVar2 + -0x58) = unaff_x27;
  *(undefined8 *)(puVar2 + -0x50) = unaff_x26;
  *(undefined8 *)(puVar2 + -0x48) = unaff_x25;
  *(undefined8 *)(puVar2 + -0x40) = unaff_x24;
  *(undefined8 *)(puVar2 + -0x38) = unaff_x23;
  *(undefined8 *)(puVar2 + -0x30) = uVar11;
  *(long *)(puVar2 + -0x28) = lVar14;
  *(long *)(puVar2 + -0x20) = lVar10;
  *(undefined8 *)(puVar2 + -0x18) = unaff_x19;
  *(undefined1 **)(puVar2 + -0x10) = puVar21;
  *(code **)(puVar2 + -8) = unaff_x30;
  if ((bRam0000000002be8be0 & 1) == 0) {
    func_0x01978cf8(0x7579);
    bRam0000000002be8be0 = 1;
  }
  if (lVar15 == 0) {
    func_0x019a516c(0);
  }
  lVar10 = lVar9;
  if (*(int *)(lVar15 + 0x10) <= *(int *)(lVar9 + 0x10)) {
    if (*(int *)(lVar15 + 0x10) == 1) {
      if (lVar13 == 0) {
        func_0x019a516c(0);
      }
      if (*(int *)(lVar13 + 0x10) == 1) {
        uVar5 = System_String__get_Chars(lVar15,0);
        uVar6 = System_String__get_Chars(lVar13,0);
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
        if ((((uVar5 & 0xffff) != (uVar6 & 0xffff)) && (iVar4 = *(int *)(lVar9 + 0x10), iVar4 != 0))
           && (iVar3 = System_String__IndexOfUnchecked(lVar9,uVar5,0,iVar4), iVar3 != -1)) {
          if (iVar3 < 4) {
            iVar3 = 0;
          }
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          lVar10 = thunk_FUN_019c327c(iVar4);
          iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
          if (iVar3 != 0) {
            if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
               (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
              func_0x0198ba0c();
            }
            System_String__CharCopy(lVar10 + iVar4,lVar9 + 0x14,iVar3);
          }
          lVar14 = (long)(iVar3 << 1);
          iVar7 = *(int *)(lVar9 + 0x10) << 1;
          if (lVar14 != iVar7) {
            lVar13 = iVar7 - lVar14;
            puVar16 = (ushort *)(lVar10 + iVar4 + (long)(iVar3 << 1));
            puVar17 = (ushort *)(lVar14 + lVar9 + 0x14);
            do {
              lVar13 = lVar13 + -2;
              uVar1 = (ushort)uVar6;
              if ((uint)*puVar17 != (uVar5 & 0xffff)) {
                uVar1 = *puVar17;
              }
              *puVar16 = uVar1;
              puVar16 = puVar16 + 1;
              puVar17 = puVar17 + 1;
            } while (lVar13 != 0);
          }
        }
        return lVar10;
      }
    }
    piVar18 = (int *)(puVar2 + -0x3a0);
    func_0x00972e60(piVar18,0,800);
    iVar3 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar7 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
    iVar4 = *(int *)(lVar9 + 0x10);
    if (0 < iVar4) {
      uVar20 = 0;
      iVar8 = 0;
      *(long *)(puVar2 + -0x68) = lVar9 + iVar3;
      *(long *)(puVar2 + -0x70) = lVar13 + iVar7;
      piVar19 = piVar18;
      do {
        iVar8 = System_String__IndexOfOrdinalUnchecked(lVar9,lVar15,iVar8,iVar4 - iVar8);
        if (iVar8 < 0) {
          if ((int)uVar20 == 0) {
            return lVar9;
          }
          break;
        }
        if (199 < (long)uVar20) {
          lVar10 = System_String__ReplaceFallback(lVar9,lVar15,lVar13,200);
          return lVar10;
        }
        *piVar19 = iVar8;
        iVar4 = *(int *)(lVar9 + 0x10);
        uVar20 = uVar20 + 1;
        iVar8 = *(int *)(lVar15 + 0x10) + iVar8;
        piVar19 = piVar19 + 1;
      } while (iVar8 < iVar4);
      iVar4 = *(int *)(lVar9 + 0x10);
      if (lVar13 == 0) {
        func_0x019a516c(0);
      }
      iVar3 = *(int *)(lVar15 + 0x10);
      iVar7 = *(int *)(lVar13 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      lVar10 = thunk_FUN_019c327c(iVar4 + (iVar7 - iVar3) * (int)uVar20);
      iVar4 = System_Runtime_CompilerServices_RuntimeHelpers__get_OffsetToStringData(0);
      lVar14 = lVar10 + iVar4;
      if ((int)uVar20 < 1) {
        iVar4 = 0;
        lVar13 = 0;
      }
      else {
        iVar3 = 0;
        iVar7 = 0;
        iVar4 = 0;
        uVar20 = uVar20 & 0xffffffff;
        *(long *)(puVar2 + -0x78) = lVar10;
        do {
          iVar8 = *(int *)((long)piVar18 + (long)iVar3) - iVar4;
          if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
             (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
            func_0x0198ba0c();
          }
          System_String__CharCopy
                    (lVar14 + (iVar7 << 1),*(long *)(puVar2 + -0x68) + (long)(iVar4 << 1),iVar8);
          iVar8 = iVar8 + iVar7;
          iVar4 = *(int *)(lVar15 + 0x10) + *(int *)((long)piVar18 + (long)iVar3);
          System_String__CharCopy
                    (lVar14 + iVar8 * 2,*(undefined8 *)(puVar2 + -0x70),
                     *(undefined4 *)(lVar13 + 0x10));
          uVar20 = uVar20 - 1;
          iVar7 = *(int *)(lVar13 + 0x10) + iVar8;
          iVar3 = iVar3 + 4;
        } while (uVar20 != 0);
        lVar10 = *(long *)(puVar2 + -0x78);
        lVar13 = (long)(iVar7 * 2);
      }
      iVar3 = *(int *)(lVar9 + 0x10);
      if (((*(byte *)(_DAT_02bf5540 + 0x126) >> 1 & 1) != 0) &&
         (*(int *)(_DAT_02bf5540 + 0xd8) == 0)) {
        func_0x0198ba0c();
      }
      System_String__CharCopy
                (lVar14 + lVar13,*(long *)(puVar2 + -0x68) + (long)(iVar4 << 1),iVar3 - iVar4);
    }
  }
  return lVar10;
}
