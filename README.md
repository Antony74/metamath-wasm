# metamath-wasm

This is an attempt to build a command line program - the [Metamath proof assistant](http://us.metamath.org/#mmprog) - for WebAssembly (WASM).

Metamath is *highly* portable, so there's no real need to have the command line tool working on WASM.  It does however serve as a very useful milestone towards the goal of making use of Metamath's functionality in dynamic JavaScript web-pages.

Here's how it's going:

## Docker

I'm running in a containerised development environment because I find it easier and more convenient than setting it up manually on the host computer, and you can jump ahead straight to where I'm getting stuck with no set up at all.  You might not want to bother with Docker if you're already set up for Emscripten development.  Please bear in mind `emscripten/emsdk` is a bit of a kitchen-sink container, and seemed to be about a gigabyte when I downloaded it.

```
docker build -t metamath .
docker run -it metamath
```

## Where I'm trying to get to

Let's take a quick look at Metamath running natively, so we can see where we're trying to get to.

```
# clang *.c -o metamath
# ./metamath
Metamath - Version 0.198 7-Aug-2021           Type HELP for help, EXIT to exit.
MM> read set.mm
Reading source file "set.mm"... 43210184 bytes
43210184 bytes were read into the source buffer.
The source has 202125 statements; 2692 are $a and 39734 are $p.
No errors were found.  However, proofs were not checked.  Type VERIFY PROOF *
if you want to check them.
MM> verify proof *
0 10%  20%  30%  40%  50%  60%  70%  80%  90% 100%
..................................................
All proofs in the database were verified in 12.02 s.
MM> exit
```

We can see Metamath is interacting with the filesystem, so as some point we're going to have to set up Emscripten's virtual filesystem.  But as we shall see, the more immediate problem is that Metamath is expecting to be able to block on stdin (i.e. wait for the user to type something), whereas WASM is a more asynchronous environment.

## Building and running with Emscripten

```
# emcc *.c -o metamath.html
# node metamath.js
Metamath - Version 0.198 7-Aug-2021           Type HELP for help, EXIT to exit.
MM> EXIT
```

Here we see Metamath exiting immediately because stdin has nothing for it and doesn't block.  We can verify this is the case by passing a stream into stdin and seeing the expected behaviour.

```
# echo "help" | node metamath.js
Metamath - Version 0.198 7-Aug-2021           Type HELP for help, EXIT to exit.
MM> Welcome to Metamath.  Here are some general guidelines.

To make the most effective use of Metamath, you should become familiar
with the Metamath book.  In particular, you will need to learn
the syntax of the Metamath language.

For help using the command line, type HELP CLI.
For help invoking Metamath, type HELP INVOKE.
For a summary of the Metamath language, type HELP LANGUAGE.
For a summary of comment markup, type HELP VERIFY MARKUP.
For help getting started, type HELP DEMO.
For help exploring the data base, type HELP EXPLORE.
For help creating a LaTeX file, type HELP TEX.
For help creating Web pages, type HELP HTML.
For help proving new theorems, type HELP PROOF_ASSISTANT.
For a list of help topics, type HELP ? (to force an error message).
For current program settings, type SHOW SETTINGS.
For a simple but general-purpose ASCII file manipulator, type TOOLS.
To exit Metamath, type EXIT (or its synonym QUIT).

If you need technical support, contact Norman Megill at nm@alum.mit.edu.
Copyright (C) 2020 Norman Megill  License terms:  GPL 2.0 or later

MM> EXIT
```

## Asyncify

We might be able to repeatedly tell Metamath we don't have any input for it, for instance by replying with \0 each time, but it would be a shame to have to thrash the system this way.

We could also change the C source code to accept commands via function calls instead of stdin, but that would give us C code to maintain and keep up to date with the Metamath codebase.

So ideally we want to be able to pause Metamath execution whenever it is waiting on stdin, just like it expects, and as happens when it is running natively.  Building with Asyncify is supposed to enable us to be able to do that, but unfortunately when I try, Metamath just hangs.

```
# emcc -O3 *.c -s ASYNCIFY -o metamath.html
# node metamath.js
```

## Wasmer

I've also tried Wasmer, which is specifically for runner WebAssmembly code on the command line.

```
# emcc *.c -o metamath.html
# wasmer metamath.wasm
error: failed to run `metamath.wasm`
╰─> 1: Emscripten requires at least one imported table
```

Usually such error messages can just be Googled, by I'm afraid I've had no luck on this occasion.

## Conclusion

So yes, I'm afraid I'm a bit stuck at the moment.

## Quick note about source maps

You'll notice I haven't tried to generate source maps for debugging C code in a web-browser's debugger such as Chrome DevTools.

There's a nice example of that here

https://yurydelendik.github.io/wasm-source-map-emscripten/pi.html

You can click through, open your web-browser's debugger (F12 on Windows), and debug the C source code.

I'm pleased to be able to see this, but I didn't find it very helpful.  "Step-over" doesn't seem to work very well.  Presumbably because there are many lines of WASM generated for each line of C.

I guess I'll stick to `printf` if I need to debug.