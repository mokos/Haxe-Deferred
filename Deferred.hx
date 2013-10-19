package ;

enum DeferredState<T, E> {
	Pending;
	Resolved(result:T);
	Rejected(error:E);
}

typedef Promise<T> = PromiseWithErrorType<T, Dynamic>;
typedef Deferred<T> = DeferredWithErrorType<T, Dynamic>;


private typedef P<T, E> = PromiseWithErrorType<T, E>;
private typedef D<T, E> = DeferredWithErrorType<T, E>;

class PromiseWithErrorType<T, E> {
	var state:DeferredState<T, E>;

	var doneQueue:Array<T -> Void>;
	var failQueue:Array<E -> Void>;
	var alwaysQueue:Array<Void -> Void>;

	public function new() {
		state = Pending;
		resetQueue();
	}

	function resetQueue() {
		doneQueue = [];
		failQueue = [];
		alwaysQueue = [];
	}

	function fixed() : Bool {
		return state!=Pending;
	}

	public function done(f : T -> Void) : P<T, E> {
		switch (state) {
		case Pending: doneQueue.push(f);
		case Resolved(result): f(result);
		case Rejected(_):
		}

		return this;
	}

	public function fail(f : E -> Void) : P<T, E> {
		switch (state) {
		case Pending: failQueue.push(f);
		case Resolved(_): 
		case Rejected(error): f(error);
		}

		return this;
	}

	public function always(f : Void -> Void) : P<T, E> {
		switch (state) {
		case Pending: alwaysQueue.push(f);
		case Resolved(_) | Rejected(_): f();
		}

		return this;
	}

	public function then<U>(f : T -> P<U, E>) : P<U, E> {
		var returnDeferred = new D<U, E>();

		this.done(function(result)  {
			var thenPromise = f(result);
			thenPromise
				.done(function(res2) returnDeferred.resolve(res2))
				.fail(function(err2) returnDeferred.reject(err2));
		});
		this.fail(function(error) returnDeferred.reject(error));

		return returnDeferred.promise(); 
	}

	public static function immediate<U>(x : U) : Promise<U> {
		var d = new Deferred<U>();
		d.resolve(x);
		return d.promise();
	}
}

class DeferredWithErrorType<T, E> extends PromiseWithErrorType<T, E> {
	public function promise() : PromiseWithErrorType<T, E> {
		return this;
	}

	public function resolve(result : T) : Void {
		fix(Resolved(result));
	}

	public function reject(error : E) : Void {
		fix(Rejected(error));
	}

	function fix(s : DeferredState<T, E>) : Void {
		if (fixed())
			return;

		state = s;

		switch (s) {
		case Resolved(result):
			for (f in doneQueue)
				f(result);
		case Rejected(error):
			for (f in failQueue)
				f(error);
		case _:
		}

		for (f in alwaysQueue)
			f();

		resetQueue();
	}
 
	public static function when<A, B, C, D, E>(
		 p1 : Promise<A>,
		 p2 : Promise<B>,
		?p3 : Promise<C>,
		?p4 : Promise<D>,
		?p5 : Promise<E>
	)
	{
		var d = new Deferred<ReturnTuple<A,B,C,D,E>>();
		var doneNum = 0;
		var ps:Array<Promise<Dynamic>> = [p1, p2];
		if (p3!=null) ps.push(p3);
		if (p4!=null) ps.push(p4);
		if (p5!=null) ps.push(p5);
		var promiseNum = ps.length;

		var r:Array<Dynamic> = [for (i in 0...promiseNum) null];

		for (i in 0...ps.length) {
			var p = ps[i];

			p.done(function(result) {
				r[i] = result;
				if (++doneNum==promiseNum) {
					switch (promiseNum) {
					case 2: d.resolve(Ret2(r[0], r[1]));
					case 3: d.resolve(Ret3(r[0], r[1], r[2]));
					case 4: d.resolve(Ret4(r[0], r[1], r[2], r[3]));
					case 5: d.resolve(Ret5(r[0], r[1], r[2], r[3], r[4]));
					case _:
					}
				}
			}).fail(function(e) {
				d.reject(e);
			});
		}

		return d.promise();
	}
}

enum ReturnTuple<A,B,C,D,E> {
	Ret2(a:A, b:B);
	Ret3(a:A, b:B, c:C);
	Ret4(a:A, b:B, c:C, d:D);
	Ret5(a:A, b:B, c:C, d:D, e:E);
}
