import std.stdio;
import std.array;
import std.conv;

import tosuke.smilebasic.compiler;
import tosuke.smilebasic.vm;
import tosuke.smilebasic.error;

void main(){
	try{
		auto slot = slot(
			`
				var a$="a$"
				print a$
				print var(var("a$"))

				var("a$")="BBA"
				print a$

				var("a$")[0]="A"
				print a$
			`
		);
		slot.source.writeln;
		slot.compile;

		auto vm = new VM();
		vm.set(0, slot);
		vm.run(0);
	}catch(SmileBasicError e){
		writeln(e.msg);
		//throw e;
	}
}
