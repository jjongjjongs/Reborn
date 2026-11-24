// HttpManager$$Request @ RVA 0x1c81b80

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

long * HttpManager__Request(long param_1,long param_2)

{
  long *plVar1;
  undefined8 *puVar2;
  undefined8 uVar3;
  ulong uVar4;
  int *piVar5;
  long lVar6;
  long lVar7;
  long *plStack_38;
  undefined8 uStack_28;
  
  lVar6 = *(long *)(param_1 + 0x58);
  if (lVar6 == 0) {
    func_0x019a516c(0);
  }
  if ((bRam0000000002be8828 & 1) == 0) {
    func_0x01978cf8(0x4080,param_2,0);
    bRam0000000002be8828 = 1;
  }
  plStack_38 = (long *)0x0;
  lVar7 = *(long *)(lVar6 + 0x48);
  if (lVar7 == 0) {
    func_0x019a516c(0);
  }
  lVar7 = Newtonsoft_Json_Linq_JObject_JPropertKeyedCollection__get_Dictionary(lVar7);
  plVar1 = (long *)0x0;
  if ((param_2 != 0) && (lVar7 != 0)) {
    lVar6 = *(long *)(lVar6 + 0x48);
    if (lVar6 == 0) {
      func_0x019a516c(0);
    }
    plVar1 = (long *)Newtonsoft_Json_Linq_JObject_JPropertKeyedCollection__get_Dictionary(lVar6);
    if (plVar1 == (long *)0x0) {
      func_0x019a516c();
    }
    lVar6 = *plVar1;
    if ((ulong)*(ushort *)(lVar6 + 0x11e) != 0) {
      uVar4 = 0;
      piVar5 = (int *)(*(long *)(lVar6 + 0xb0) + 8);
      do {
        if (*(long *)(piVar5 + -2) == _DAT_02bfe9b0) {
          puVar2 = (undefined8 *)(lVar6 + (ulong)(*piVar5 + 3) * 0x10 + 0x128);
          goto LAB_00d4edec;
        }
        uVar4 = uVar4 + 1;
        piVar5 = piVar5 + 4;
      } while (uVar4 < *(ushort *)(lVar6 + 0x11e));
    }
    puVar2 = (undefined8 *)func_0x01970ffc(plVar1,_DAT_02bfe9b0,3);
LAB_00d4edec:
    (*(code *)*puVar2)(plVar1,param_2,&plStack_38,puVar2[1]);
    plVar1 = plStack_38;
    if (plStack_38 != (long *)0x0) {
      lVar6 = *plStack_38;
      if ((*(byte *)(lVar6 + 0x120) < *(byte *)(_DAT_02bfdd20 + 0x120)) ||
         (*(long *)(*(long *)(lVar6 + 200) + (ulong)*(byte *)(_DAT_02bfdd20 + 0x120) * 8 + -8) !=
          _DAT_02bfdd20)) {
        func_0x019d7df0(&uStack_28,*(undefined8 *)(lVar6 + 0x40));
        uVar3 = func_0x019a5e1c(uStack_28);
        func_0x019a50dc(uVar3,0,0);
        func_0x0208fe80(&uStack_28);
        plVar1 = (long *)0x0;
      }
    }
  }
  return plVar1;
}
