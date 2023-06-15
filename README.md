# It's 9 p.m., where is your vault reference copy of the Unix kernel now?

Thu Jun 15 17:01:51 UTC 2023

# Abstract 

Every time a new version ("release" in OpenBSD parlance) of Unix is created, it needs to be stamped as authentic, otherwise it's just a glorified computer worm susceptible to attack as indicated by Paul Karger (the topic of Dennis Richie's popular ACM lecture) masquerading as an operating system that people are trying to do genetic engineering (or perhaps hopelessly, analysis) on.

This avoids a circular specification of the operating system where it is defined as its implementation, which in the case of the OpenBSD kernel link kit, is ELF machine code. The problem of inversion from the ELF machine code back to the C source code is in general undecidable as the Post correspondence problem is very well-understood (https://www.cis.upenn.edu/~jean/gbooks/PCPh04.pdf). Furthermore, existing C compiler also lacks type information inside its intermediate representation, and payloads (of course) may be arbitrarily encoded inside or outside the kernel.

As a demonstrative example the author provides (in this repository) a new version of the BSD operating system kernel, both in binary form and as a link kit (CBSD) that is not an OpenBSD kernel but which, if installed as a link kit, will be reordered by the OpenBSD 7.3 release reorder_kernel utility as it currently exists (which does not check that it has been stamped) and installed as a new kernel during the next boot, and a patch to the script that creates the new version of BSD during the build which adds such a stamp, closing the vulnerability in an online system, assuming a corresponding check is performed before executing reorder_kernel. However the root-of-trust problem with the machine code in the initial link kit (and initial kernel from the release media) still stands. 

As the objects provided in the link kit are opaque they should (at a minimum) be discarded and the system built from source, but it is not sufficient by itself in a self-hosted environment in the general case when considering sophisticated attackers. 

The core problem with OpenBSD's implementation of kernel reordering is that the operating system is viewed at the link-level as a collection of components and as a monolithic binary during runtime which are two seperate levels of abstraction, leading to this security flaw, where attempting to relink at runtime without checking that the objects match the stamp from the release allows relinking of an arbitrary computer program with the same link structure.

With no or limited knowledge of computer programming it is trivial to introduce corrupted objects which while not trojan horses will instead crash the system in a myriad of unexpected ways, or by modifying compiler flags from an official release using the build instructions. Sophisticated adversaries can introduce arbitrary revisions to OpenBSD.

The link kit being embedded inside of the COMP installation set makes it impossible to verify the compiler binaries independently from the link kit during installation. Lack of signatures for the installation sets on the installation media make it impossible to verify the installation sets from the installation media alone. Immediately reordering the kernel on boot makes the system polymorphic generally. Architectural cross-cutting of concerns is problematic here for objects that should be clearly separated.

If the OpenBSD kernel_reorder utility instead checked the stamp created when the release was created, for all kernel objects /usr/share/relink/kernel/$BUILD, this security vulnerability would be closed.

Keeping all link-reordering as a purely-mathematical segment-shuffling operation on a reference kernel binary and the discarding of the link kit concept entirely is desirable as a a complete alternative if polymorphic kernels are what is wanted. OpenBSD's stance on firmware blobs is ironic because the link kit is in-effect a firmware blob representing OpenBSD, and reorder_kernel is effectively a weak implementation of a single-level store, so the security analysis that Paul Karger applied to Multics now applies to OpenBSD. 

OpenBSD's historical focus on isolation from attacks from outside the system neglects attacks from below or inside, which require a focus on both system and data integrity. IBM holds extensive patents in this area (automatic tagging of programs and data when they are added to the system, etc.). Security through obscurity and Unix's obfuscated build process is not helpful when it comes to a system that is widely-deployed on a range of critical infrastructure. A safe design is crucial, as well as careful study of prior work.

The current implementation also makes the strong assumption that remote holes will never occur in the OpenBSD operating system as a whole going forward, allowing installation of rootkits qua link kits. The "COMP" install set is a ready-made off-the-shelf trojan horse in and of itself.

Cf. John Rushby, "The Design and Verification of Secure Systems," Eighth ACM Symposium on Operating System Principles, pp. 12-21, Asilomar, CA, December 1981. (ACM Operating Systems Review, Vol. 15, No. 5).

# clang build process
I have extracted the compilation phase and linking phase to make them not depend on BSD make as a proof of concept of how to start to move away from provided components, but a working GCC build is needed for full diverse compilation to eliminate the root-of-trust problem concerning the machine code in the OpenBSD releases.

As of writing, distcc/linux clang would look to be a good candidate for trying to bootstrap the compilation away from the initially-installed OpenBSD system. Trying to do it purely from scratch is difficult (cf. Waite's STAGE2), GNU Mes. 

# Insufficient Workarounds

OPSEC, COMSEC, encryption:

Keeping the kernel offline and using one-time pads? Better keep them completely offline and never reuse or publish them.

A kernel which is totally opaque to userspace and a reference monitor running in a separation kernel, etc.. WORM-storage-backed filesystems.

Running a link kit and a provided binary, and a recompiled version in parallel and noting any differences in behaviour, versus a complete clean-room reimplementation from the POSIX spec on diverse hardware via triple modular redundancy? Out of reach for most individuals. Kernels can trigger processes in userspace and vice-versa by exercising obscure code paths. A complete cleanroom Unix implementation in both hardware and software in complete secrecy is akin to the Nth country problem in terms of scope and cost. Atomic secrets leaked rather quickly and that was with utmost secrecy and a state of war. Better not run existing potentially-compromised versions of Unix on your rocket guidance computer, for instance. 

Incentives for tampering or leaks are pervasive. Any detectable strings inside the decoded kernel are vectors for attacks. It has to be decoded *somewhere*. 

"I will spend most of this first period belaboring some seemingly obvious points on the need for
communications security; why we're in this business, and what our objectives really are. It seems
obvious that we need to protect our communications because they consistently reveal our strengths,
weaknesses. disposition, plans, and intentions and if the opposition intercepts them be can exploit
that information by attacking our weak points. avoiding our strengths, countering our plans, and
frustrating our intentions.. something he can only do if he has advance knowledge of our situation.
But there's more to it than that."

Cf. https://www.governmentattic.org/18docs/Hist_US_COMSEC_Boak_NSA_1973u.pdf

"Rewrite it in X" - just introduces another trap door. All changes must proceed from a known good state. System integration coupled with and security analysis of interfaces and component modules is a non-trivial activity.

Mistakes have been made (e.g. the known backdoor in TrueCrypt).

Hybrid systems are not enough, for the same reason untrusted systems are, lacking a clean-room kernel implementation, and with lack of a trusted compiler, and a trusted build environment which is not self-hosted by the kernel.

# Summary 

The link kit distributed with OpenBSD when paired with the existing reorder_kernel function (which lacks such a check) as of OpenBSD 7.3 allows the installation of a rootkit for anyone with local access to the machine, or the creator of the link kit provided on the installation media, or by tampering with the installation media. A link kit that is stamped does not suffer from this class of vulnerability in the restricted case of tampering with local access to the machine or the installation media, but a trusted external build environment is required to rule out that the creator of the initial link kit did not install a trojan horse. As GCC support was conspicuously dropped, this difficult for those without access to historical copies of the release media and source distributions. OpenBSD's official installation media notably lacks the signature and checksum for the base installation sets, allowing trivial tampering. The release of official physical media was also discontinued.

# Useful RAND Corporation reports

https://www.rand.org/pubs/papers/P3544.html

# Userland back doors

A patch process for the link kit can be embedded in any of the applications available for OpenBSD which when run as root, surreptitiously patches the kernel with a payload that is relinked by kernel_reorder. 

There should be no mechanism by which this can happen.

# Areas for Further Study

The source of OpenBSD is tied to a specific bundled clang implementation that is self-hosted. Lack of an external build environment with first-party support makes it impossible to verify if the link kit provided with OpenBSD is not a trojan horse. GCC support was also (conspicuously) dropped and eliminated from the source tree. Having both GCC and clang support for the kernel build process (that is self-hosted) would be an excellent first step toward support for a portable build environment hosted externally to the system.


Portable bootstrapping from another vendor's POSIX environment or a mobile programming system (the concept behind Waite's STAGE2) is instead desirable.


Cf. 

https://dwheeler.com/trusting-trust/

https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=31bb1c092dba2b1a692b87cd2ff859bb7ce735f7


--

Tue Jun 13 23:36:31 UTC 2023

# CBSD
Fork of OpenBSD (via simple examples) that patches problems with kernel relinking opening up undesirable regressions and local exploits, and that aims to provide a parallel build environment that's not self-hosted in OpenBSD and which also can be bootstrapped from the OpenBSD 7.3/amd64 release media easily with or without BSD make.

***

# Further reading:

Multics lead the way with this, OpenBSD follows:

https://www.acsac.org/2002/papers/classic-multics-orig.pdf

Obit., contains pertinent mention of isolation compared with integrity:

[1] https://www.computer.org/csdl/magazine/sp/2010/06/msp2010060005/13rRUy08MDu


" It is apparent that a wide range of considerations are pertinent to the engineering of security of information. Historically, the literature of computer systems has more narrowly defined the term protection to be just those security techniques that control the access of executing programs to stored information.3 An example of a protection technique is labeling of computer-stored files with lists of authorized users. Similarly, the term authentication is used for those security techniques that verify the identity of a person (or other external agent) making a request of a computer system. An example of an authentication technique is demanding a password. This paper concentrates on protection and authentication mechanisms, with only occasional reference to the other equally necessary security mechanisms. One should recognize that concentration on protection and authentication mechanisms provides a narrow view of information security, and that a narrow view is dangerous. The objective of a secure system is to prevent all unauthorized use of information, a negative kind of requirement. It is hard to prove that this negative requirement has been achieved, for one must demonstrate that every possible threat has been anticipated. Thus an expansive view of the problem is most appropriate to help ensure that no gaps appear in the strategy. In contrast, a narrow concentration on protection mechanisms, especially those logically impossible to defeat, may lead to false confidence in the system as a whole.4"

https://www.cs.virginia.edu/~evans/cs551/saltzer/



"In modern usage, the term usually refers to the organization of a computing system in which there are no files, only persistent objects (sometimes called segments), which are mapped into processes' address spaces (which consist entirely of a collection of mapped objects). The entire storage of the computer is thought of as a single two-dimensional plane of addresses (segment, and address within segment).

The persistent object concept was first introduced by Multics in the mid-1960s, in a project shared by MIT, General Electric and Bell Labs.[2] It also was implemented as virtual memory, with the actual physical implementation including a number of levels of storage types. (Multics, for instance, had three levels originally: main memory, a high-speed drum, and disks.)"

[...]

A single-level store changes this model by extending VM from handling just a paging file to a new concept where the "main memory" is the entire secondary storage system. In this model there is no need for a file system separate from the memory, programs simply allocate memory as normal and that memory is invisibly written out to storage and retrieved as required. The program no longer needs code to move data to and from secondary storage. The program can, for instance, produce a series of business cards in memory, which will invisibly be written out. When the program is loaded again in the future, that data will immediately re-appear in its memory. *And as programs are also part of this same unified memory, restarting a machine or logging in a user makes all of those programs and their data reappear.*" 

https://en.wikipedia.org/wiki/Single-level_store

The Teensy Files:

(cue X-Files music and title card) 

http://www.muppetlabs.com/~breadbox/software/tiny/ 

Plan 9, Inferno:

No one is doing systems research and development anymore.

Tandem hosts:

https://en.wikipedia.org/wiki/Tandem_Computers

Redundancy and the shared-nothing approach.

Kolmogorov Complexity is undecidable:

http://alexander.shen.free.fr/library/Zvonkin_Levin_70.pdf

"None of the computing machine simulations of organic evolution have
attempted representations of organisms using minimal codes, and it seems like
a reasonably good thing to try." - Ray Solomonoff

# Footnotes

[1] PAR2 and the Bittorrent protocol (have been around for two decades, cover a similar problem domain when file integrity (or durability in the case of erasure) of collections of objects is concerned). This isn't rocket science. Durability and integrity are both important aspects of system design.

[2] OpenBSD "syspatch" is at the same level of security and correctness analysis as "kernel_reorder". They represent critical transactions on the system. Transaction processing systems with ultra-high-reliability have been studied extensively (Tandem, DB2, Journaling ISAM databases where transactions are physically written out in the order that they occur). These are not historical artifacts, Tandem hosts are still running in the Canadian commercial banking infrastructure, for instance.

[3] Filesystems using optical WORM robotic disc libraries existed at the time of Plan 9's development (e.g. "Ken's filesystem"). Optical drives have notably disappeared from consumer devices despite having the same WORM property, and of course now we also have blockchains, ZFS, and IPFS.

[4] A simple counting argument suffices to show that signature-based methods alone are not enough to detect the presence of malware due to the possibility of arbitrary encoding and polymorphism. Cf. "tripwire".

[5] We solved the byzantine generals problem (Bitcoin), but we can't get this right.

[5] Light-hearted fictional scenarios that are enjoyable and illustrative of some of the problems:

1. Putting a copy of the current unpatched version of OpenBSD inside the computer center from "Colossus: The Forbin Project" (1970).
2. Burning it into firmware that controls a nuclear power plant cooling pump (akin to Michael Mann's Blackhat), or using it to control commercial or government (manned or unmanned space launch systems, military command and control ("Wargames") or life support systems on space stations or space vehicles ("2001: A Space Odyssey", with a twist).
3. Bruce Sterling already wrote a sci-fi book where a giant laser weapon runs OpenBSD, IIRC.

[6] Is the random reordering really random?

https://www.schneier.com/blog/archives/2007/11/the_strange_sto.html


# My initial bug report to the OpenBSD mailing list:

https://marc.info/?l=openbsd-bugs&m=159074964523007&w=2

# Request for comments

Please provide any commentary or feedback on this essay or the source repository or my bug reports, and suggestions or ideas for further development (pull requests can go to the "comments" file).

--

Thu Jun 15 16:59:52 UTC 2023

# Conclusion

The unstated truth (or perhaps dirty secret) about the portability of self-hosted Unix and why Unix is such a highly polished gem (initially, anyway) is that it is the first synthetic analogue of a biological organism (with a self-reproduction process), with C being the portable assembly language, and it is prone to the accumulation of "junk DNA" as well as "viral DNA"  (which might not actually be junk but could trigger or be triggered by another process). In this analogy, OpenBSD's kernel-reodering mechanism (as currently implemented with no integrity checks of object files) is "cancer". Proceeding from the assumption of no contamination of the outside or inside environment is foolish.

All software problems can be fixed.

