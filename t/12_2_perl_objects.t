use strict ;
use Test ;

use Inline Config => 
           DIRECTORY => './_Inline_test';

use Inline (
	Java => 'DATA',
) ;

use Inline::Java qw(caught) ;
use Data::Dumper ;


BEGIN {
	my $cnt = 14 ;
	plan(tests => $cnt) ;
}

my $t = new t16() ;

{
	eval {
		my $o = new Obj(name => 'toto') ;
		$t->set($o) ;
		ok($t->get(), $o) ;
		ok($t->get()->{name}, 'toto') ;
		ok($t->round_trip($o), $o) ;
		ok($o->get("name"), 'toto') ;
		ok($t->method_call($o, 'get', ['name']), 'toto') ;
		eval {$t->method_call($o, 'bad', ['bad'])} ; ok($@, qr/Can't locate object method "bad" via package "Obj"/) ;
		eval {$t->round_trip({})} ; ok($@, qr/^Can't convert (.*?) to object org.perl.inline.java.InlineJavaPerlObject/) ;
		ok($t->add_eval(5, 6), 11) ;
		eval {$t->error()} ; ok($@, qr/alone/) ;

		my $cnt = Inline::Java::Callback::ObjectCount() ;
		$t->clean($o) ;
		ok($cnt, Inline::Java::Callback::ObjectCount()) ;

		my $jo = $t->create("Obj", ['name', 'titi']) ;
		ok($jo->get("name"), 'titi') ;
		$t->have_fun() ;
		ok($jo->get('shirt'), qr/lousy t-shirt/) ;

		$t->clean(undef) ;
	} ;
	if ($@){
		if (caught("java.lang.Throwable")){
			$@->printStackTrace() ;
			die("Caught Java Exception") ;
		}
		else{
			die $@ ;
		}
	}
}

ok($t->__get_private()->{proto}->ObjectCount(), 1) ;
ok(Inline::Java::Callback::ObjectCount(), 3) ;


package Obj ;

sub new {
	my $class = shift ;

	return bless({@_}, $class) ;
}

sub get {
	my $this = shift ;
	my $attr = shift ;

	return $this->{$attr} ;
}

sub set {
	my $this = shift ;
	my $attr = shift ;
	my $val = shift ;

	$this->{$attr} = $val ;
}

package main ;


__END__

__Java__


import java.io.* ;
import org.perl.inline.java.* ;

class t16 {
	InlineJavaPerlObject po = null ;

	public t16(){
	}

	public void set(InlineJavaPerlObject o){
		po = o ;
	}

	public InlineJavaPerlObject get(){
		return po ;
	}

	public int add_eval(int a, int b) throws InlineJavaException, InlineJavaPerlException {
		Integer i = (Integer)po.eval(a + " + " + b, Integer.class) ;
		return i.intValue() ;
	}

	public String method_call(InlineJavaPerlObject o, String name, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		String s = (String)o.InvokeMethod(name, args) ;
		o.Done() ;
		return s ;
	}

	public void error() throws InlineJavaException, InlineJavaPerlException {
		po.eval("die 'alone'") ;
	}

	public InlineJavaPerlObject round_trip(InlineJavaPerlObject o) throws InlineJavaException, InlineJavaPerlException {
		return o ;
	}

	public void clean(InlineJavaPerlObject o) throws InlineJavaException, InlineJavaPerlException {
		if (o != null){
			o.Done() ;
		}
		else if (po != null){
			po.Done() ;
		}
	}

	public InlineJavaPerlObject create(String pkg, Object args[]) throws InlineJavaException, InlineJavaPerlException {
		po = new InlineJavaPerlObject(pkg, args) ;
		return po ;
	}

	public void have_fun() throws InlineJavaException, InlineJavaPerlException {
		po.InvokeMethod("set", new Object [] {"shirt", "I've been to Java and all I got was this lousy t-shirt!"}) ;
	}

	public void gc(){
		System.runFinalization() ;
		System.gc() ;
	}
}