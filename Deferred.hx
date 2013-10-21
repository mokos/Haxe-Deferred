package ;

using Lambda;

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
		return (new Deferred<U>()).resolve(x);
	}
}

class DeferredWithErrorType<T, E> extends PromiseWithErrorType<T, E> {
	public function promise() : P<T, E> {
		return this;
	}

	public function resolve(result : T) : P<T, E> {
		fix(Resolved(result));
		return this;
	}

	public function reject(error : E) : P<T, E> {
		fix(Rejected(error));
		return this;
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
 
	public static function when<A, B, C, D, E, Er>(
		 p1 : P<A, Er>,
		 p2 : P<B, Er>,
		?p3 : P<C, Er>,
		?p4 : P<D, Er>,
		?p5 : P<E, Er>
	)
	{
		var d = new Deferred<ReturnTuple<A,B,C,D,E>>();
		var promises:Array<P<Dynamic, Er>> = [p1, p2, p3, p4, p5];
		promises = promises.filter(function(x) return x!=null);

		// results
		var r:Array<Dynamic> = [for (p in promises) null];


		var doneNum = 0;
		for (i in 0...promises.length) {
			var p = promises[i];

			p.done(function(result) {
				r[i] = result;
				if (++doneNum==promises.length) {
					switch (promises.length) {
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
