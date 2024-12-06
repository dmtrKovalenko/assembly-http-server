# MacOS HTTP server using pure assembly 

Yes it is what it says in the title. Pure arm 64 assembly implementation of HTTP server in assembly with a 

- real (but primitive) routing (try /urmom and /urdad routes)
- some kind of configuration (you can change the port in one place and it applies everywhere)
- primitive logging to stdout

And still under 200 lines of code.

## Build and run it

It is a macos only assembly (remember, arm64) so it will work only on Apple Silicon macs.

```bash
as -o server.o server.s
ld -o server server.o -lSystem -L /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -arch arm64 -platform_version macos 15.0 15.0 -e _main -dynamic

./server
```

## Why did I do this? 

I don't know but you can follow me on twitter to not miss the next crazy thing I do: https://x.com/neogoose_btw
