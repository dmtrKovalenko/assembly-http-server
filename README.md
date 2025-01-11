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

I recorded a very detailed youtube video with the description of every part of this assembly server. Watch here -> https://www.youtube.com/watch?v=xfBVv3WI8kU&t=2s&ab_channel=NeoGoose

## React server components implementation

This is fun, I know. Yes I also implemeneted a backend for React Server Components in assembly, you can find the code [here](https://github.com/dmtrKovalenko/assembly-http-server/tree/main/react_server_components). To run this app you need to run the actual react app dev server by installing node js and running 

```
npm install --legacy-peer-deps
npm start
```

**And** running the http server the same way as described above. 

Oh and there is also a youtube video for this one -> https://www.youtube.com/watch?v=i-4BJXTAFD0&t=29s

## Why did I do this? 

I don't know but you can follow me on twitter to not miss the next crazy thing I do: https://x.com/neogoose_btw
