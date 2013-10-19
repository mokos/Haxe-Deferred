enum DeferredState<T, E> {
	Pending;
	Resolved(result:T);
	Rejected(error:E);
}


private typedef P<T, E> = PromiseWithErrorType<T, E>;

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
}

class DeferredWithErrorType<T, E> extends PromiseWithErrorType<T, E> {
	public function resolve(result : T) : Void {
		fix(Resolved(result));
	}

	public function reject(error : E) : Void {
		fix(Rejected(error));
	}

	function fix(s : DeferredState<T, E>) : Void {
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

typedef Promise<T> = PromiseWithErrorType<T, Dynamic>;
typedef Deferred<T> = DeferredWithErrorType<T, Dynamic>;

