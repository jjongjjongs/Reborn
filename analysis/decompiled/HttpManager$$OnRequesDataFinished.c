// HttpManager$$OnRequesDataFinished @ RVA 0x1c81f7c

void HttpManager__OnRequesDataFinished
               (undefined8 param_1,undefined8 param_2,long param_3,long *param_4,long param_5)

{
  long *plVar1;
  ushort uVar2;
  ulong uVar3;
  undefined8 uVar4;
  code *UNRECOVERED_JUMPTABLE_00;
  ulong uVar5;
  undefined8 uVar6;
  undefined8 *puVar7;
  undefined4 uVar8;
  long lVar9;
  long lVar10;
  int *piVar11;
  
  if (param_3 == 0) {
    func_0x019a516c(0);
  }
  uVar3 = BestHTTP_HTTPResponse__get_IsSuccess(param_3,0);
  if ((uVar3 & 1) == 0) {
    if (param_5 == 0) {
      return;
    }
    if (param_3 == 0) {
      func_0x019a516c(0);
    }
    uVar4 = BestHTTP_HTTPResponse__get_Data(param_3,0);
    uVar8 = 1;
  }
  else {
    if (param_5 == 0) {
      return;
    }
    if (param_3 == 0) {
      func_0x019a516c(0);
    }
    uVar4 = BestHTTP_HTTPResponse__get_Data(param_3,0);
    uVar8 = 0;
  }
  if (*(long *)(param_5 + 0x58) != 0) {
    cbHttpResDelegate__Invoke(*(long *)(param_5 + 0x58),param_4,uVar4,uVar8,param_2,param_3,0);
  }
  plVar1 = *(long **)(param_5 + 0x20);
  puVar7 = *(undefined8 **)(param_5 + 0x28);
  UNRECOVERED_JUMPTABLE_00 = *(code **)(param_5 + 0x10);
  if (*(short *)(puVar7 + 9) == -1) {
    func_0x0198b814(puVar7);
  }
  uVar3 = func_0x019baa78(puVar7);
  if ((uVar3 & 1) == 0) {
    if (*(char *)((long)puVar7 + 0x4a) != '\x05') goto LAB_01dc5214;
  }
  else {
    if (*(char *)((long)puVar7 + 0x4a) == '\x05') {
      if ((*(short *)(puVar7 + 9) != -1) &&
         (((plVar1 == (long *)0x0 || ((*(byte *)(*plVar1 + 0x109) & 1) == 0)) &&
          (*(long *)(param_5 + 0x18) != 0)))) {
        if (plVar1 == (long *)0x0) goto LAB_01dc52e8;
        if ((*(byte *)(*plVar1 + 0x109) & 1) != 0) {
          return;
        }
        uVar3 = func_0x019baa64(puVar7);
        func_0x019baae0(puVar7);
        uVar5 = func_0x0196f120();
        if ((uVar3 & 1) == 0) {
          uVar2 = *(ushort *)(puVar7 + 9);
          if ((uVar5 & 1) == 0) {
            lVar9 = *plVar1 + (ulong)uVar2 * 0x10;
            UNRECOVERED_JUMPTABLE_00 = *(code **)(lVar9 + 0x128);
            puVar7 = *(undefined8 **)(lVar9 + 0x130);
          }
          else {
            lVar9 = func_0x019baae0(puVar7);
            lVar10 = *plVar1;
            if ((ulong)*(ushort *)(lVar10 + 0x11e) != 0) {
              uVar3 = 0;
              piVar11 = (int *)(*(long *)(lVar10 + 0xb0) + 8);
              do {
                if (*(long *)(piVar11 + -2) == lVar9) {
                  puVar7 = (undefined8 *)(lVar10 + (ulong)(*piVar11 + (uint)uVar2) * 0x10 + 0x128);
                  goto LAB_01dc54e0;
                }
                uVar3 = uVar3 + 1;
                piVar11 = piVar11 + 4;
              } while (uVar3 < *(ushort *)(lVar10 + 0x11e));
            }
            puVar7 = (undefined8 *)func_0x01970ffc(plVar1,lVar9,(ulong)uVar2);
LAB_01dc54e0:
            UNRECOVERED_JUMPTABLE_00 = (code *)*puVar7;
            puVar7 = (undefined8 *)puVar7[1];
          }
        }
        else {
          if ((uVar5 & 1) == 0) {
            uVar6 = *(undefined8 *)(*plVar1 + (ulong)*(ushort *)(puVar7 + 9) * 0x10 + 0x130);
          }
          else {
            lVar9 = *plVar1;
            if ((ulong)*(ushort *)(lVar9 + 0x11e) != 0) {
              uVar3 = 0;
              piVar11 = (int *)(*(long *)(lVar9 + 0xb0) + 8);
              do {
                if (*(long *)(piVar11 + -2) == puVar7[3]) {
                  lVar9 = lVar9 + (ulong)(*piVar11 + (uint)*(ushort *)(puVar7 + 9)) * 0x10 + 0x128;
                  goto LAB_01dc549c;
                }
                uVar3 = uVar3 + 1;
                piVar11 = piVar11 + 4;
              } while (uVar3 < *(ushort *)(lVar9 + 0x11e));
            }
            lVar9 = func_0x01970ffc(plVar1);
LAB_01dc549c:
            uVar6 = *(undefined8 *)(lVar9 + 8);
          }
          puVar7 = (undefined8 *)func_0x0198b744(uVar6,puVar7);
          UNRECOVERED_JUMPTABLE_00 = (code *)*puVar7;
        }
      }
LAB_01dc5214:
                    /* WARNING: Could not recover jumptable at 0x01dc522c. Too many branches */
                    /* WARNING: Treating indirect jump as call */
      (*UNRECOVERED_JUMPTABLE_00)(plVar1,param_4,uVar4,uVar8,param_2,param_3,puVar7);
      return;
    }
    if (((*(short *)(puVar7 + 9) != -1) &&
        ((plVar1 == (long *)0x0 || ((*(byte *)(*plVar1 + 0x109) & 1) == 0)))) &&
       (*(long *)(param_5 + 0x18) != 0)) {
      if ((plVar1 != (long *)0x0) && ((*(byte *)(*plVar1 + 0x109) & 1) != 0)) {
        return;
      }
      uVar3 = func_0x019baa64(puVar7);
      func_0x019baae0(puVar7);
      uVar5 = func_0x0196f120();
      if ((uVar3 & 1) == 0) {
        uVar2 = *(ushort *)(puVar7 + 9);
        if ((uVar5 & 1) == 0) {
          lVar9 = *param_4 + (ulong)uVar2 * 0x10;
          UNRECOVERED_JUMPTABLE_00 = *(code **)(lVar9 + 0x128);
          puVar7 = *(undefined8 **)(lVar9 + 0x130);
        }
        else {
          lVar9 = func_0x019baae0(puVar7);
          lVar10 = *param_4;
          if ((ulong)*(ushort *)(lVar10 + 0x11e) != 0) {
            uVar3 = 0;
            piVar11 = (int *)(*(long *)(lVar10 + 0xb0) + 8);
            do {
              if (*(long *)(piVar11 + -2) == lVar9) {
                puVar7 = (undefined8 *)(lVar10 + (ulong)(*piVar11 + (uint)uVar2) * 0x10 + 0x128);
                goto LAB_01dc5470;
              }
              uVar3 = uVar3 + 1;
              piVar11 = piVar11 + 4;
            } while (uVar3 < *(ushort *)(lVar10 + 0x11e));
          }
          puVar7 = (undefined8 *)func_0x01970ffc(param_4,lVar9,(ulong)uVar2);
LAB_01dc5470:
          UNRECOVERED_JUMPTABLE_00 = (code *)*puVar7;
          puVar7 = (undefined8 *)puVar7[1];
        }
      }
      else {
        if ((uVar5 & 1) == 0) {
          uVar6 = *(undefined8 *)(*param_4 + (ulong)*(ushort *)(puVar7 + 9) * 0x10 + 0x130);
        }
        else {
          lVar9 = *param_4;
          if ((ulong)*(ushort *)(lVar9 + 0x11e) != 0) {
            uVar3 = 0;
            piVar11 = (int *)(*(long *)(lVar9 + 0xb0) + 8);
            do {
              if (*(long *)(piVar11 + -2) == puVar7[3]) {
                lVar9 = lVar9 + (ulong)(*piVar11 + (uint)*(ushort *)(puVar7 + 9)) * 0x10 + 0x128;
                goto LAB_01dc5430;
              }
              uVar3 = uVar3 + 1;
              piVar11 = piVar11 + 4;
            } while (uVar3 < *(ushort *)(lVar9 + 0x11e));
          }
          lVar9 = func_0x01970ffc(param_4);
LAB_01dc5430:
          uVar6 = *(undefined8 *)(lVar9 + 8);
        }
        puVar7 = (undefined8 *)func_0x0198b744(uVar6,puVar7);
        UNRECOVERED_JUMPTABLE_00 = (code *)*puVar7;
      }
    }
  }
LAB_01dc52e8:
                    /* WARNING: Could not recover jumptable at 0x01dc5300. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*UNRECOVERED_JUMPTABLE_00)(param_4,uVar4,uVar8,param_2,param_3,puVar7);
  return;
}
