module tosuke.smilebasic.vm.vm;

import tosuke.smilebasic.vm;
import tosuke.smilebasic.value;
import tosuke.smilebasic.utils;
import tosuke.smilebasic.error;

import std.conv : to;
import std.experimental.logger;

class VM{
  private{
    Slot[] slots;
    @property Slot currentSlot(){ return slots[currentSlotNumber]; }

    @property VMCode[] currentCode(){ return currentSlot.vmcode;}

    uint pc;
    uint currentSlotNumber;

    Stack!Value valueStack;

    void delegate()[0x10000] codeTable;
  }

  

  this(){
    slots = new Slot[5];
    foreach(ref a; slots) a = new Slot();

    codeTable[] = (){ assert(0, "Invalid Bytecode"); };
    initCommandTable();
    initPushTable();
  }

  void set(int slotNum, Slot slot)
  in{
    assert(0 <= slotNum && slotNum <= 4);
  }body{
    slots[slotNum] = slot;
  }

  void run(int slotNum)
  in{
    assert(0 <= slotNum && slotNum <= 4);
  }body{
    currentSlotNumber = slotNum;
    pc = 0;

    while(pc < currentCode.length){
      auto pcBak = pc;
      VMCode code = take();
      try{
        codeTable[code]();
      }catch(SmileBasicError e){
        auto codemap = currentSlot.codemap;
        e.line = codemap.search(pcBak);
        throw e;
      }
      
    }
  }

  VMCode take(){
    return currentCode[pc++];
  }

  VMCode[] take(uint a){
    pc += a;
    return a == 1 ? [currentCode[pc-a]] : currentCode[pc-a..pc];
  }

  void initCommandTable(){
    //UnaryOps
    codeTable[0x0000] = &unaryOp!"negOp";
    codeTable[0x1000] = &unaryOp!"notOp";
    codeTable[0x2000] = &unaryOp!"logicalNotOp";

    codeTable[0x0010] = &binaryOp!"mulOp";
    codeTable[0x1010] = &binaryOp!"divOp";
    codeTable[0x2010] = &binaryOp!"intDivOp";
    codeTable[0x3010] = &binaryOp!"modOp";
    codeTable[0x4010] = &binaryOp!"addOp";
    codeTable[0x5010] = &binaryOp!"subOp";
    codeTable[0x6010] = &binaryOp!"leftShiftOp";
    codeTable[0x7010] = &binaryOp!"rightShiftOp";
    codeTable[0x8010] = &binaryOp!"andOp";
    codeTable[0x9010] = &binaryOp!"orOp";
    codeTable[0xA010] = &binaryOp!"xorOp";

    codeTable[0x0020] = &binaryOp!"eqOp";
    codeTable[0x1020] = &binaryOp!"notEqOp";
    codeTable[0x2020] = &binaryOp!"lessOp";
    codeTable[0x3020] = &binaryOp!"greaterOp";
    codeTable[0x4020] = &binaryOp!"lessEqOp";
    codeTable[0x5020] = &binaryOp!"greaterEqOp";

    codeTable[0x0080] = &printCommand;
  }
  void initPushTable(){
    codeTable[0x0001] = &pushImm16;
    codeTable[0x0011] = &pushImm32;
    codeTable[0x0021] = &pushImm64f;
    codeTable[0x0031] = &pushString;
  }

  void unaryOp(string op)(){
    auto a = valueStack.pop;
    valueStack.push(mixin(op~"(a)"));
  }

  void binaryOp(string op)(){
    auto a = valueStack.pop;
    auto b = valueStack.pop;

    valueStack.push(mixin(op~"(a, b)"));
  }

  void printCommand(){
    int argNum = take();
    import std.array;
    import std.conv : to;

    Appender!wstring temp;
    foreach(a; 0..argNum){
      auto v = valueStack.pop();
      temp ~= (o){
        switch(o){
          case ValueType.Integer: return v.get!int.to!wstring;
          case ValueType.Floater: return v.get!double.to!wstring;
          case ValueType.String: return v.get!wstring;
          default: assert(0);
        }
      }(v.type);
    }
    import std.stdio;
    temp.data.write;
  }

  void pushImm16(){
    auto k = cast(short)take();
    valueStack.push(Value(k));
  }
  void pushImm32(){
    auto t = take(2);
    uint k = t[0] << 16 | t[1];
    valueStack.push(Value(cast(int)k));
  }
  void pushImm64f(){
    auto t = take(4);
    ulong k = t[0].to!ulong << 48 | t[1].to!ulong << 32 | t[2] << 16 | t[3];
    valueStack.push(Value(*(cast(double*)&k)));
  }
  void pushString(){
    import std.array;
    Appender!(wchar[]) str;
    while(true){
      auto a = cast(wchar)take();
      if(a == 0) break;
      str ~= a;
    }
    valueStack.push(Value(cast(wstring)(str.data)));
  }
}