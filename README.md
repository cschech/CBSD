Wed Jun 14 23:40:21 UTC 2023

# Abstract 

Every time a new version ("release" in OpenBSD parlance) of Unix is created, it needs to be stamped as authentic, otherwise it's just a glorified computer worm susceptible to attack as indicated by Paul Karger (the topic of Dennis Richie's popular ACM lecture) masquerading as an operating system that people are trying to do genetic engineering (or perhaps hopelessly, analysis) on. 

This avoids a circular specification of the operating system where it is defined as its implementation. As a demonstrative example the author provides (in this repository) a new version of the BSD operating system kernel (CBSD) that is not an OpenBSD kernel but which will be reordered by the OpenBSD 7.3 release reorder_kernel utility as it currently exists (which does not check that it has been stamped) and installed as a new kernel during the next boot, and patch to the script that creates the new version of BSD during the build. As the objects provided in the link kit are opaque they should (at a minimum) be discarded and the system built from source. 

The core problem with OpenBSD's implementation of kernel reordering is that the operating system is viewed at the link-level as a collection of components and as a monolithic binary during runtime which are two seperate levels of abstraction, leading to this security flaw, where attempting to relink at runtime without checking that the objects match the stamp from the release allows relinking of an arbitrary computer program with the same link structure.

If the OpenBSD kernel_reorder utility instead checked the stamp created when the release was created, for all kernel objects /usr/share/relink/kernel/$BUILD, this security vulnerability would be closed.

In summary, the link kit distributed with OpenBSD when paired with the existing reorder_kernel function (which lacks such a check) as of OpenBSD 7.3 allows the installation of a rootkit for anyone with local access to the machine, and even complete replacement or destruction of the operating system. A link kit that is stamped does not suffer from this class of vulnerability.

# Areas for Further Study

The source of OpenBSD is tied to a specific bundled clang implementation that is self-hosted. Lack of an external build environment with first-party support makes it impossible to verify if the link kit provided with OpenBSD is not a trojan horse. GCC support was also dropped and eliminated from the source tree. Having both GCC and clang support for the kernel build process (that is self-hosted) would be an excellent first step toward support for a portable build environment hosted externally to the system.

Portable bootstrapping from another vendor's POSIX environment or a mobile programming system (the concept behind Waite's STAGE2) is instead desirable.


Cf. 

https://dwheeler.com/trusting-trust/

https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=31bb1c092dba2b1a692b87cd2ff859bb7ce735f7

--

Tue Jun 13 23:36:31 UTC 2023

# CBSD
Fork of OpenBSD (via simple examples) that patches problems with kernel relinking opening up undesirable regressions and local exploits, and that aims to provide a parallel build environment that's not self-hosted in OpenBSD and which also can be bootstrapped from the OpenBSD 7.3/amd64 release media easily with or without BSD make.

***

I had a really nice test harness for this but there were only 4 files left on my 800 GB partition after the kernel crashed while the startup relinking phase was rm'ing files so I'm not reproducing that again.

***

Dear OpenBSD developers, please fix the following bug/vulnerability:

The OpenBSD "kernel relinking" process contains a flaw which can lead to both regressions and intentional problems because the signatures of the object files being relinked are not kept in sync with the kernel (or anywhere that reorder currently checks because it's naive and didn't consider this.)

Model right now is chain of trust from release --- never interfered with - relink - never - relink - no third party builds - relink - hostile actors putting payloads everywhere OpenBSD runs that isn't a secure site -> relink - special day happens, everything goes Y2K or worse ->

should just be - last link kit matches last booted kernel (or initial release kernel provided with initial link kit) and no other posibilities.

or - throw away link kit idea as a terrible attack surface to ship everywhere, put the source in the install sets and always build from source, then only a flaw in the initial kernel in the release or a compiler/upstream toolchain flaw would break things.


to fix this problem I propose a simple patch along these lines 

[...]

+#ost="CBSD"

+#osr="0.01"

+sha512 -h /var/db/obj.${id}.sha512 *.o lorder

cat >vers.c <<eof

[...]

in /sys/conf/newvars.sh.

as well as the removal of the "kernel reordering" in /etc/rc with the current approach not checking the link kit component checksums directly being deprecated, or a check against

+sha512 -c /var/db/obj.${id}.sha512 *.o lorder /bsd

before reordering, or making it optional for the user

^ this I will refer to as (1) - the only valid precondition for doing it at runtime rather than only ever after the initial compilation/linking by computing randomized offsets to the initial build offsets without preserving unlinked object code in the wild - can warn if signed or unsigned, users can even sign them whenever they want, etc

the relinked kernel is random and you can just delete the input objects now, anyway, and keep the lorder file and then manually compute how to shuffle it without the linker doing it for you each time

delete the old lorder file


^ maintains the set of important checksums as one atomic unit that can be signed, if they are truly equivalent and you trust whatever process made that guarantee for you...

never run a reordering job unless (1) holds, otherwise you can accidentally or intentionally trash the kernel or revert it to one you already know the order of (from a release or you made yourself)

in /etc/rc before proceeding with the re-ordering. Of course the checksums for both the kernel and the objects can just be surreptitiously updated to work around this mitigation, but that requires a different exploit path than injecting the wrong binaries without being detected.

Merely changing the compiler flags to clang for some of the emitted objects will cause the relinking to crash during "rm" and delete the root filesystem contents on boot without changing the program text of the inputs to cclang.

A sanity check of a newly-installed kernel (e.g., surviving an intermediate reboot cycle ), before immediate relinking the next boot can reduce problems with untested kernels being built (or maliciously-constructed and then introduced into a system to later be loaded in as a "relinked kernel" which is not a permulation of the last one build or received from a distributed official kernel - and then immediately panicking when relinking in the lesser case and damaging or destroying the system or surreptitiously tampering with the kernel configuration and allowing a local root exploit on the next /etc/rc invocation should be avoided by correct design decisions and implementation.

Hoisting a minimal build script for the kernel and the objects is not difficult by careful dissection of the output of make or by trapping compiler and linker invocations during a build. Because make is incremental it is easy to then rebuild a new system with arbitary properties.

Having no diverse compiler choice for the base system or a simple base shell script that builds the complete system sequentially as a baseline keeps non-expert and non-interested parties from investigating how to modify the kernel to improve it. The complete stagnation of the build system and the complete removal of GCC which makes finding compiler regressions between different toolchains impossible at present without resorting to software archaeology is an odd part the situation.


Build systems of large projects are often intentionally obfuscated in industry (job security?). It is not difficult to build a kernel, just a 20 MB text listing of the same call to cc for each point in the source tree. Having a huge worldwide archive yet with only two rolling releases of less than 1 GB each to go back to as a user is a questionable practice too. Every release ever made on all architectures could easily be compiled and published as a torrent. Having old packages and ports is always valuable for comparison and for (re)bootstrapping GCC compilation for instance.

***

Further reading:

Multics lead the way with this, OpenBSD follows:

https://www.acsac.org/2002/papers/classic-multics-orig.pdf

" It is apparent that a wide range of considerations are pertinent to the engineering of security of information. Historically, the literature of computer systems has more narrowly defined the term protection to be just those security techniques that control the access of executing programs to stored information.3 An example of a protection technique is labeling of computer-stored files with lists of authorized users. Similarly, the term authentication is used for those security techniques that verify the identity of a person (or other external agent) making a request of a computer system. An example of an authentication technique is demanding a password. This paper concentrates on protection and authentication mechanisms, with only occasional reference to the other equally necessary security mechanisms. One should recognize that concentration on protection and authentication mechanisms provides a narrow view of information security, and that a narrow view is dangerous. The objective of a secure system is to prevent all unauthorized use of information, a negative kind of requirement. It is hard to prove that this negative requirement has been achieved, for one must demonstrate that every possible threat has been anticipated. Thus an expansive view of the problem is most appropriate to help ensure that no gaps appear in the strategy. In contrast, a narrow concentration on protection mechanisms, especially those logically impossible to defeat, may lead to false confidence in the system as a whole.4"

https://www.cs.virginia.edu/~evans/cs551/saltzer/

My initial bug report to Theo:

https://marc.info/?l=openbsd-bugs&m=159074964523007&w=2

***

Implications of the rc script not validating the whole blob of objects before linking it -

0. So many objects to infect.. inject malicious/arbitary/corrupt code/logic bombs into the system easily
1. Take an old link kit from a previous release and put it in /usr/share/relink - it gets reordered and relinked into the new kernel
2. Why not relink only on shutdown? Right at startup is the most critical section to be relinking in, the handoff from kernel to the user gets broken as indicated.
3. You have to trust the initial link kit isn't backdoored versus everyone (in the past) evaluating one static kernel in all environments

Basic shutdown procedure:
   
Shut down everything else
check sha512sum for everything in /usr/share/relink + /bsd from install set in initial install from a release or check against last set of checksums every time it's reordered - and make a reordered copy
move in place for next boot
run sanity checks or bring up in a vm and run a self-test for bonus points
log the checksums to syslog and mail to root or whatever
sync disk

on encrypted partitions you are completely confident that it's not tampered with

you can also make a strong guarantee that all your kernels are derived from the official ones, or some branch that you made yourself

you can do the same with the .rd kernel

3. minimally put the sha256 checksum and the signature that are on the http site inside the release media image. and a manifest of all files in each installset and their correct signatures 
4. consider just signing everything in the entire distribution and the source tree

for the least attack surface reorder only after compiling when shutting down or at end of fresh install

at startup always has a maximum allowance for tampering/interfering with other services, also slows down boot at the most important stage

Lots of ways to solve the problem adequately and little downside.


Sincerely,

C.W. Schech

