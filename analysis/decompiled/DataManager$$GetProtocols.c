// DataManager$$GetProtocols @ RVA 0x1c9471c

void DataManager__GetProtocols(long param_1)

{
  undefined8 uVar1;
  long lVar2;
  
  if (*(long *)(param_1 + 0x58) == 0) {
    lVar2 = *(long *)(param_1 + 0x60);
    if (lVar2 == 0) {
      func_0x019a516c(0);
    }
    uVar1 = UnityEngine_TextAsset__get_text(lVar2,0);
    uVar1 = Newtonsoft_Json_Linq_JObject__Parse(uVar1,0);
    *(undefined8 *)(param_1 + 0x58) = uVar1;
  }
  return;
}
