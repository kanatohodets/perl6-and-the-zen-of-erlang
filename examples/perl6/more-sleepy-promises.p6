use v6;
my $start = now;
my @promises;
say "firing off some promises";
for ^17 -> $i {
    @promises.push(start { sleep 3; say "$i is done" })
}
await @promises;
say "all done! ran {@promises.elems} promises in {now - $start} seconds"
