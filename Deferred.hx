
enum DeferredState<T, E> {
	Pending;
	Resolved(result:T);
	Rejected(error:E);
}

typedef Promise<T> = PromiseWithErrorType<T, Dynamic>;
typedef Deferred<T> = DeferredWithErrorType<T, Dynamic>;


private typedef P<T, E> = PromiseWithErrorType<T, E>;

private typedef Tuple<T, U> = { first : T, second : U };

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

	function fixed():Bool {
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
		var returnDeferred = new DeferredWithErrorType<U, E>();

		this.done(function(result)  {
			var innerPromise = f(result);
			innerPromise.done(function(result2:U) returnDeferred.resolve(result2));
			innerPromise.fail(function(error2) returnDeferred.reject(error2));
		});
		this.fail(function(error) returnDeferred.reject(error));

		return returnDeferred; 
	}

	public function and<U, E>(p : P<U, E>) : P<Tuple<T, U>, E> {
		var d = new Deferred.DeferredWithErrorType<Tuple<T, U>, E>();
		return d;
	} 

}

class DeferredWithErrorType<T, E> extends PromiseWithErrorType<T, E> {
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
}

