module tosuke.smilebasic.value.value;

import tosuke.smilebasic.value;

import tosuke.smilebasic.error;
import std.conv : to;
import std.format;
import std.algorithm, std.range, std.array;


///値の種別
enum ValueType{
	Undefined,
	Integer,
	Floater,
	String,
	Array,
}


///値の種別を文字列化する
string toString(ValueType t){
	switch(t){
		case ValueType.Undefined:	return "Undefined";
		case ValueType.Integer: 	return "Integer";
		case ValueType.Floater: 	return "Floater";
		case ValueType.String: 		return "String";
		case ValueType.Array: 		return "Array";
		default: assert(0);
	}
}


///tosukeSmileBasic内の値
struct Value{
	import std.variant : Algebraic;

	alias data this;

	///初期化
	this(T)(T a) if(!is(T == ValueType)){
		data = a;
	}

	///ditto
	this(ValueType t){
		final switch(t){
			case ValueType.Undefined:
				break;
			case ValueType.Integer:
				data = 0;
				break;
			case ValueType.Floater:
				data = 0.0;
				break;
			case ValueType.String:
				data = ""w;
				break;
			case ValueType.Array:
				break;
		}

		type = t;
	}

	///値の実体
	alias Type = Algebraic!(int, double, StringValue, ArrayValue);
	private Type data_;
	@property{
		///ditto
		public Type data() const {return data_;}
		///ditto
		public void data(T)(T a){
			static if(is(T == Value)){
				type = a.type;
				data_ = a.data;
			}else static if(is(T : int) || is(T : bool)){
				type = ValueType.Integer;
				data_ = cast(int)a;
			}else static if(is(T : double)){
				type = ValueType.Floater;
				data_ = a;
			}else static if(is(T : wstring)){
				type = ValueType.String;
				data_ = new StringValue(a);
			}else static if(is(T == StringValue)){
				type = ValueType.String;
				data_ = a;
			}else static if(is(T == ArrayValue)){
				type = ValueType.Array;
				data_ = a;
			}else{
				static assert(0);
			}
		}
	}


	///取得
	T get(T)() const{
		static if(is(T : wstring)){
			return data.get!StringValue.data.to!T;
		}else static if(is(T == IArray)){
			if(this.type == ValueType.String){
				return this.get!StringValue.to!IArray;
			}else if(this.type == ValueType.Array){
				return this.get!ArrayValue.to!IArray;
			}else{
				throw cannotUseAsArrayError(this);
			}
		}else{
			return data.get!T;
		}
	}


	///次元
	int dimension() @property const{
		final switch(this.type){
			case ValueType.Undefined:	return 0;
			case ValueType.Integer: 	return 0;
			case ValueType.Floater: 	return 0;
			case ValueType.String:		return this.get!StringValue.dimension;
			case ValueType.Array:			return this.get!ArrayValue.dimension;
		}
	}


	///長さ
	size_t length() @property const {
		return this.get!IArray.length;
	}

	///配列アクセス
	Value index(int[] ind) const {
		if(!this.isArrayValue){
			throw cannotUseAsArrayError(this);
		}
		if(ind.length != this.dimension){
			throw illegalIndexError(this.dimension);
		}

		return this.get!IArray.index(ind);
	}

	///ditto
	Value opIndex(int[] ind...) const {
		return index(ind);
	}

	///配列アクセス
	void indexAssign(Value a, int[] ind){
		if(!this.isArrayValue){
			throw cannotUseAsArrayError(this);
		}
		if(ind.length != this.dimension){
			throw illegalIndexError(this.dimension);
		}

		this.get!IArray.indexAssign(a, ind);
	}

	///ditto
	void opIndexAssign(Value a, int[] ind...){
		indexAssign(a, ind);
	}


	/// =演算子
	void opAssign(T)(T a) if(!is(T == Value)){
		data = a;
	}

	///ditto
	void opAssign(Value a){
		if(this.isArithmeticValue && a.isArithmeticValue){
			if(this.type == ValueType.Integer){
				this.data = a.toInteger;
			}else{
				this.data = a.toFloater;
			}
		}else if(this.type == a.type || this.type == ValueType.Undefined){
			this.data = a;
		}else{
			throw failedToConvertTypeError(this, a);
		}
	}

	/// 値の種別
	private ValueType type_;
	@property{
		///ditto
		public ValueType type() const {return type_;}
		private void type(ValueType a){type_ = a;}
	}

	///初期化
	public void clear(){
		this.type = ValueType.Undefined;
	}

	string toString() const {
		switch(this.type){
			case ValueType.Undefined: return "undefined";
			case ValueType.Integer: return this.get!int.to!string;
			case ValueType.Floater: return this.get!double.to!string;
			case ValueType.String: return `"`~this.get!wstring.to!string~`"`;
			default: assert(0);
		}
	}

	//演算子オーバーロード
	mixin OperatorMixin;

	///怒られるので
	auto toHash() const{
		return data.toHash;
	}
}


///数値型であるか？
bool isArithmeticValue(Value v){
	return v.type == ValueType.Integer || v.type == ValueType.Floater;
}


///配列型であるか？
bool isArrayValue(Value v){
	return v.type == ValueType.String || v.type == ValueType.Array;
}


///実数型に変換する
double toFloater(Value v){
	if(!isArithmeticValue(v))
		throw failedToConvertTypeError(v, Value(ValueType.Floater));
		
	if(v.type == ValueType.Integer){
		return v.get!int.to!double;
	}else{
		return v.get!double;
	}
}


///整数型に変換する
int toInteger(Value v){
	if(!isArithmeticValue(v))
		throw failedToConvertTypeError(v, Value(ValueType.Integer));
	
	if(v.type == ValueType.Floater){
		auto k = v.get!double;
		if(k > int.max){
			return int.max;
		}else if(k < int.min){
			return int.min;
		}else{
			return k.to!int;
		}
	}else{
		return v.get!int;
	}
}


///真であれば0以外、偽であれば0を返す
int toBoolean(Value v){
	switch(v.type){
		case ValueType.Integer: return cast(int)(v.get!int != 0);
		case ValueType.Floater: return cast(int)(v.get!double != 0);
		case ValueType.String: return 3;
		default: assert(0);
	}
}