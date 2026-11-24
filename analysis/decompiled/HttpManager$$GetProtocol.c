// HttpManager$$GetProtocol @ RVA 0x1c81934

void HttpManager__GetProtocol(long param_1,undefined8 param_2)

{
  long lVar1;
  undefined8 uVar2;
  
  if ((bRam0000000002c495ea & 1) == 0) {
    func_0x01978cf8(0x3889);
    bRam0000000002c495ea = 1;
  }
  lVar1 = *(long *)(param_1 + 0x58);
  if (lVar1 == 0) {
    HttpManager__LoadProtocols(param_1);
    lVar1 = *(long *)(param_1 + 0x58);
    if (lVar1 == 0) {
      func_0x019a516c();
      lVar1 = 0;
    }
  }
  uVar2 = Newtonsoft_Json_Linq_JObject__get_Item(lVar1,param_2,0);
  Newtonsoft_Json_Linq_JToken__op_Explicit(uVar2,0);
  return;
}
