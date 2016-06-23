# perl6 and the zen of erlang

Erlang! It's reliable! Reliable programs are good!

How do we write reliable programs?

1. don't write bugs (be very skilled, or have extensive QA)
2. limit the scope of a bug's impact

ok, so we're probably going to have bugs. it's a big bad world out there with
lots of different kinds of input, some of them will make our program crash. how
can we limit the scope of a bug's impact?

### define concurrency
* juggling. doing more than one thing 'at once' (logically, if not literally).
  order of execution is undefined.

### concurrency in perl 5: event loops
* juggler with one hand: lots of things in the air, only touching one ball at
  once.
* show an event loop impl
* this is an optimization for IO!
* they make programs: fast, complex, scalable, fragile.

### if concurrency is often an optimization (fragile, complicated), how is erlang so robust?
* concurrency as decoupling!

### decoupling!

like microservices, or classes (or an operating system): failure of one component (or
process) does not spread through the whole system.

you might know erlang for it's actor-based concurrency: soft real-time, etc.
That stuff is great, but it's all in service to one major feature: reliability
through decoupling.

__temporal (de)coupling__!!!

Why's that? The order of program execution is a form of coupling. When we have
a linear program (or an event loop), any possible exception must be handled in
order for the rest of the code to work, even if the exception happened in
a deep subsystem. The 'first this code, then that code' is coupling! Can we
decouple? Yes! Erlang does this! (also operating systems). The notion is that
we divide our programs into little chunks by the bits that have a need to run
in order. Lots of bits don't!

### That sounds like concurrency?
It is! But not like you normally use it. Typically concurrency is thought of as
an optimization for IO bound operations. It can be, but it can _also_ be used
as a tool to gain reliability, by decoupling parts of the program that have no
sequential relationship.

### cooperative and preemptive scheduling
Operating system -> preemptive scheduling. resilient to program errors. no
notion of callbacks or futures or yields or condvars. malloc/free vs garbage
collector: cooperative is fast, simple to implement, and error prone.
preemptive is slower, complicated to implement, but resilient to programmer
error/eliminates a category of bug.

### a gazillion threads?
spawning tons of little units of concurrency is terrifying if you've worked
with threaded programs. imagine instead of 50 threads we have 500000.
aaaaaaaagh! Erlang makes this OK by 1) being immutable, so processes can't
stomp on shared data structures and 2) arranging things into a supervisor tree.
just like an OS: init --> ssh/crond/supervisord --> application code. the init
process should be rock solid; our application code might be less solid, and
that's ok.

"controlled burn" metaphor. allow things to wipe out in a way we can manage,
rather than allowing problems to spread through the system unchecked

the benefit of this approach is that it frees us from writing complex
error-handling code at the pointy end of our system. it blows up? just restart
it. depending on the design of our application we might not even wipe out
a user, just degrade some feature/functionality.

why is turning it off and back on again a good thing? (table from Fred's talk:
transient vs repeatable bugs, core vs peripheral features, which kinds of bugs
are handled by restarting)

### "Let it crash"

So! If we have pieces of our program broken into concurrent components that can
fail independently of each other, we've removed the need for our entire program
to be able to handle every error. We can let one component crash, and the
others will keep on trucking. We don't need to know what kind of error
happened, nor do we need to make dangerous assumptions about what state that
error left us in. It doesn't matter _why_ the component crashes! It
could be a bug, or it could have been forcibly shut down by an admin.

### What about getting better?

Of course, letting pieces of our program crash is only useful if it can also
_recover_ from those crashes somehow. Otherwise the program will just degrade
slowly. Because we've handled failure by allowing it to proceed and terminate
our little decoupled chunk of code, the best thing would be to just start it
back up: this is what a supervisor does.

### Overview of Erlang reliability

1. temporally decoupled (concurrency as decoupling)
2. preemptively scheduled (robust to programmer error)
3. immutable language (so processes are distinct from green threads: no shared
   state/shared mem: isolation for crashes and SAFE TO RESTART)
4. supervisor tree taking advantage of the 'safe to restart' property

### and perl6?
Promises! little units of concurrency that isolate errors! no explicit
yielding (callbacks/yield, etc.)

... well... it's a thread pool. promises are 1:1 with system threads while
executing. the 'yield' is 'return'.

as such, the amount of temporal decoupling we can achieve is limited by the
size of our thread pool, rather than by the shape of our program.

moreover, the mutability of data structures means there's no protection from
shared memory race conditions. just like Golang, here.

#### could we have it?
in theory, yes. I don't think there's anything semantically that would stop
promises from being premeptively scheduled instead of mapping 1:1 to a thread
pool, but it does mean that the Perl6 VMs would have to develop a preempetive
scheduler, which is a serious bit of engineering and complexity.

you could also write some classes or even a slang that enforced immutable
arguments only for concurrency units, so that they could be safely restarted

in general though, perl6 is a more general-purpose language than the (very
specialized) Erlang VM, so you might be over-specializing by trying to adopt
these features or architectures, even if they're awesome for high-reliability
network services.
