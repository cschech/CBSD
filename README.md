# It's 9 p.m., where is your vault reference copy of the Unix kernel now?
- Draft Copy -
Thu Jun 15 17:01:51 UTC 2023

# Abstract 

Every time a new version ("release" in OpenBSD parlance) of Unix is created, it needs to be stamped as authentic, otherwise it's just a glorified computer worm susceptible to attack as indicated by Paul Karger (NB: the spurious topic "trust-of-trust" of Dennis Richie's popular ACM lecture was a deliberate misconstrual of the USAF security analysis and compromise of Multics[1]) masquerading as an operating system that people are trying to do genetic engineering (or perhaps hopelessly, analysis) on. To avoid digressions into "trust of trust" this needs to be treated as a systems engineering, computer security, supply chain problem, and a technical computing problem simultaneously, and given an interdisciplinary treatment, as the Unix kernel (as traditionally implemented) defines the entire security domain of a running system[3].

This avoids a circular specification of the operating system where it is defined as its implementation, which in the case of the OpenBSD kernel link kit, is ELF machine code. The problem of inversion from the ELF machine code back to the C source code is in general undecidable as the Post correspondence problem is very well-understood (https://www.cis.upenn.edu/~jean/gbooks/PCPh04.pdf), so data integrity of the objects needs to be accounted for by *some* mechanism. Furthermore, the existing C compiler also lacks type information inside its intermediate representation, and payloads (of course) may be arbitrarily encoded inside or outside the kernel. The OpenBSD kernel is currently an SLSA0 component as officially distributed, with the current distribution mechanism. As the project leader has no desire to improve on this, an alternate path to bootstrap away from a self-hosted build and an illustration of how kernel-reordering as currently implemented allows greater tampering with the kernel than it did historically[2], provide the theme of this paper. 

SLSA provenance (https://slsa.dev/spec/v0.1/levels) would be a path toward (partial) assurance for official releases in lieu of a clean-room implementation of a build environment ("SLSA4"), but at present OpenBSD is still self-hosting and self-bootstrapping from a machine code kernel of unknown provenance. Before kernel reordering was introduced it had a tamper-resistant build process ("SLSA2") and thus was at a higher level of SLSA compliance than it is now: an automatic process relinks kernel objects of unknown provenance at install time and at boot time, and does not match them against any checksums or digital signatures at the host level or externally. My proposal to add specific security controls to the reorder_kernel function for exactly this reason was rejected, as of writing. Furthermore, in the past, GCC support was also present so bootstrapping a build offline from another environment that does not suffer from arbitary relinking present in the current self-hosted environment ("hermetic builds" in SLSA parlance) was less difficult. The vulnerability can be avoided by making the kernel-reordering function transactional, or by decoupling the components used for reordering from the automatic startup script and into a daemon which is activated or deactivated at the discretion of the user (selectable at install-time before any reordering has occured). C code was originally intended to be highly portable and the POSIX specification was developed to facilitate this, however the OpenBSD code as currently implemented is tightly coupled to an archaic and mostly-undocumented build system, and not portable to even the packaged GCC compiler using the currently-available source releases. Historical review (of potentially unavailable or doctored) historical releases of OpenBSD may be practical.   

This essay limits the topic to auditability and security-hardening (tamper resistance) of the build process and not higher-level theoretical limitations and practical problems in compiler design and formal verification.

Keywords: Unix, OpenBSD, iterated build processes, security evaluation, system integrity, SLSA

[1] https://www.acsac.org/2002/papers/classic-multics-orig.pdf

Obit., contains pertinent mention of isolation compared with integrity:

[2] https://www.computer.org/csdl/magazine/sp/2010/06/msp2010060005/13rRUy08MDu

# Insecurity of the OpenBSD 7.3/amd64 distribution

As a demonstrative example the author provides (in this repository) a new version of the BSD operating system kernel, both in binary form and as a link kit (CBSD) that is not an OpenBSD kernel but which, if installed as a link kit, will be reordered by the OpenBSD 7.3 release reorder_kernel utility as it currently exists (which does not check that it has been stamped) and installed as a new kernel during the next boot, and a patch to the script that creates the new version of BSD during the build which adds such a stamp, closing the vulnerability in an online system (with or without iterated builds), assuming a corresponding check is performed before executing reorder_kernel. However the root-of-trust problem with the machine code in the initial link kit (and initial kernel from the release media) still stands. 

As the objects provided in the link kit are opaque they should (at a minimum) be discarded and the system built from source, but it is not sufficient by itself in a self-hosted environment in the general case when considering sophisticated attackers. 

The core problem with OpenBSD's implementation of kernel reordering is that the operating system is viewed at the link-level as a collection of components and as a monolithic binary during runtime which are two seperate levels of abstraction, leading to this security flaw, where attempting to relink at runtime without checking that the objects match the stamp from the release allows relinking of an arbitrary computer program with the same link structure.

With no or limited knowledge of computer programming it is trivial to introduce corrupted objects which while not trojan horses will instead crash the system in a myriad of unexpected ways, or by modifying compiler flags from an official release using the build instructions. Sophisticated adversaries can introduce arbitrary revisions to OpenBSD.

The link kit being embedded inside of the "base" installation set makes it impossible to verify the compiler binaries independently from the link kit during installation. Lack of signatures for the installation sets on the installation media make it impossible to verify the installation sets from the installation media alone. Immediately reordering the kernel on boot makes the system polymorphic generally. Architectural cross-cutting of concerns is problematic here for objects that should be clearly separated.

If the OpenBSD kernel_reorder utility instead checked the stamp created when the release was created, for all kernel objects /usr/share/relink/kernel/$BUILD, this security vulnerability would be closed. Right now it is security theatre at best (Why is more than one random reordering needed or a periodic process at each boot which silently makes objects in the link kit reappear? It doesn't make it any more random assuming the kernel is correctly isolated to begin with), additionally, entropy is extremely low when performing an install, the process can't be disabled, and it introduces all the vulnerabilities and integrity problems outlined, when it can also be done as a purely mathematical process using the initial entry points and sizes of the segments. Using such data allows for an attacker to scan the binary stored on the system, identify the segments using strings from the objects that are preserved, and compute the entry points anyway, because the internal structure of the objects is not reordered, akin to a game of "Battleship" or "Sudoku". The random gap is also present on the filesystem. Because the link kit is a potential trojan horse itself it should never be linked and installed. Even a warning in the installer or an opt-out would not be troublesome to add.

Keeping all link-reordering as a purely-mathematical segment-shuffling operation on a reference kernel binary and the discarding of the link kit concept entirely is desirable as a a complete alternative if polymorphic kernels are what is wanted. OpenBSD's stance on firmware blobs is ironic because the link kit is in-effect a firmware blob representing OpenBSD, and reorder_kernel is effectively a weak implementation of a single-level store, so the security analysis that Paul Karger applied to Multics now applies to OpenBSD. 

OpenBSD's historical focus on isolation from attacks from outside the system neglects attacks from below or inside, which require a focus on both system and data integrity. IBM holds extensive patents in this area (automatic tagging of programs and data when they are added to the system, etc.). Security through obscurity and Unix's obfuscated build process is not helpful when it comes to a system that is widely-deployed on a range of critical infrastructure. A safe design is crucial, as well as careful study of prior work.

The current implementation also makes the strong assumption that remote holes will never occur in the OpenBSD operating system as a whole going forward, allowing installation of rootkits as link kits. The "base" install set is a ready-made off-the-shelf trojan horse in and of itself in the worst case (if not verified, and the install media lacks embedded signatures), paired with the fact that in the default install the system runs the reordering routine automatically immediately at the end of the install process and then again periodically at boot with no possibility of user intervention or a prompt to enable or disable the feature, as with other automatic startup options for X11 startup or SSH. It is a lower-level analogue of syspatch operating outside of user control (paired with a lack of checksum verification on the objects). This may harden it against certain "buffer overflow" attacks but it's a form of premature optimization that (unintentionally?) creates a new hole (as currently implemented) which allows tampering with the build process itself, which is much more dangerous as it allows code to be injected into the kernel through an especially weakly-implemented special case of an iterated build process hosted on the machine and automatically run at startup that otherwise wouldn't exist. It is almost a worst-case scenario, although that would be a completely undocumented build process running iteratively on a machine with no provenance. At least in OpenBSD's case it is self-hosted and documented so steps can be made to move away from it.

Manual editing of the install image configuration scripts or tedious work inside the BSD.RD environment is required for a user to disable the feature, yet still install the rest of the complete system, and entails remastering of the installation images, if an existing OpenBSD environment is not available.

[3] John Rushby, "The Design and Verification of Secure Systems," Eighth ACM Symposium on Operating System Principles, pp. 12-21, Asilomar, CA, December 1981. (ACM Operating Systems Review, Vol. 15, No. 5): "[...] I shall argue that the problems with conventional systems have their roots in the use of a security kernel which attempts to impose a single security policy over the whole system. "


# Approximately correct protocol to make reorder_kernel transactional (pseudocode)
```
< foo > denotes a command
[ ... ] denotes a comment
{bar} denotes a parameter
 
BEGIN is the initial state of the subsystem under consideration

Pseudocode follows (this can likely be implemented in prolog or similar or verfied/implemented in automated theorem provers like Coq using Hoare logic)
-------------------------------------------------------------------------------------------------------------------------------------

BEGIN </etc/rc>


Precondition 1:
- Assumes that the SHA512 and SHA256 algorithms and their implementations in the system sha256 and sha512 programs are trusted to execute correctly on a host machine 
- Assumes newvers.sh creates sha512 and sha256 files for all components of the link kit, including makegap.sh and lorder and all .o files, and a separate file for the linked kernel from the build, at build time
- Assumes that the initially distributed and installed link kit and checksums in /var/db have not been tampered with
- Assumes that the post-install process populates the hashes for the link kit in the install's base set.
- Assumes no rootkits or compromises in the running kernel or in userland.
Precondition 2:
WHERE {id} is the ID generated by /usr/src/conf/newvers.sh 
[refer to version in this repository for example]


FOR ALL FILES in /usr/share/relink/kernel/{id}/ 

IF <verification> OF obj.{id}.sha512 AND kernel.{id}.sha512 AND obj.{id}.sha256 AND kernel.{id}.sha256, and kernel.SHA256 >
["verification" would be implemented by the standard sha512 and sha256 utilities with the -C flag when pointed at /var/db/obj.{id}.sha512 and /var/db/obj.{id}.sha256] 
[refer to newvers.sh for the construction of the sha512 and sha256 files, kernel.SHA256 is constructed by make in the standard documented build process with the released code]

THEN   
   <reorder_kernel>
ELSE
  <log error>
  <exit 1>
```

Either a valid kernel will be relinked (if all preconditions hold) or an error will be logged and an exit status of 1 will occur in /etc/rc, both newvers.sh

There are a lot of interacting components so a thorough implementation will take this into account, as well as correct bootstrapping and provenance for the install media's install sets and the installation media as a unit in itself. Also builds can be switched between, which isn't a concern of kernel_reorder but object and kernel integrity is. Relinking will fail if such a switch occurs.

This would also require the addition of the relevant files to the link kit contents in the base install set (for the initial link kit) to simplify the implementation and limit reliance on online scripting.

I would like to expand from this single example problem to a similar pseudocode specification of the complete OpenBSD system, it could likely serve for the development of a future formally-verified version of OpenBSD (at least it would be an example of literate programming even if not).

Translating this into say, Z notation, without a team of logicians and computer scientists is definitely non-trivial. 
(https://en.wikipedia.org/wiki/Z_notation)
     
# Workarounds

Disabling the existing process by removing it from the /etc/rc file, and rebuilding the kernel from source (avoids trivial rootkits in the provided link kit objects, but not sophisticated rootkits throughout the entire system as it is self-hosting). Disabling the existing process inside the install image. Deleting the link kit from the COMP install set and providing a signed copy of all install set images, contained inside the installation media. Requires correct remastering of the installation media. The signatures not being included inside the install media to begin with is suspect. That is a trivial patch to provide assurance against tampering, as the complete image would be signed as official, as well as its components, verifiable at install-time. In a stand-alone system or when bootstrapping an OpenBSD environment this is not possible unless done manually at present.

distcc and an automated build process developed independently from the provided self-hosted build would allow compilation to occur remotely.

# Remote linking

Removing the ability for OpenBSD to link objects by itself, and having them linked by a call to a remote machine (akin to distcc, distlink?) would eliminate the need for the system to capture its own elf components and link order/randomization information. Experts in the use of llvm's LLD can likely provide a quick solution here. Setting up a build environment on say, Debian 11 and ksh, and seeing if the linking and compilation phases return sucessfully would be useful.

# Removing the dependency on BSD make from the clang build process 

Further steps toward a diverse build environment:

I have extracted the compilation phase and linking phase to make them not depend on BSD make as a proof of concept of how to start to move away from provided components, but a working GCC build is needed for full diverse compilation to eliminate the root-of-trust problem concerning the machine code in the OpenBSD releases.

As of writing, distcc/linux clang would look to be a good candidate for trying to bootstrap the compilation away from the initially-installed OpenBSD system. Trying to do it purely from scratch is difficult (cf. Waite's STAGE2), GNU Mes. Clean-room reimplementation is intractable. 

# Complete automation of the OpenBSD build process

Merely requires concerted effort. A worthwhile direction for further development effort.

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

Stand-alone site(s) with trusted administrator(s) are required. Any old vendor can look good during an audit with perfect build orchestration and by the same token then flip a switch and turn off all the protections if having reached that level of automation.

# Summary 

The link kit distributed with OpenBSD when paired with the existing reorder_kernel function (which lacks such a check) as of OpenBSD 7.3 allows the installation of a rootkit for anyone with local access to the machine, or the creator of the link kit provided on the installation media, or by tampering with the installation media. A link kit that is stamped does not suffer from this class of vulnerability in the restricted case of tampering with local access to the machine or the installation media, but a trusted external build environment is required to rule out that the creator of the initial link kit did not install a trojan horse. As GCC support was conspicuously dropped, this difficult for those without access to historical copies of the release media and source distributions. OpenBSD's official installation media notably lacks the signature and checksum for the base installation sets, allowing trivial tampering. The release of official physical media was also discontinued.

# Useful RAND Corporation reports

https://www.rand.org/pubs/papers/P3544.html

# Userland back doors

A patch process for the link kit can be embedded in any of the applications available for OpenBSD which when run as root, surreptitiously patches the kernel with a payload that is relinked by kernel_reorder. 

There should be no mechanism by which this can happen.

# Areas for Further Study

The source of OpenBSD is tied to a specific bundled clang implementation that is self-hosted. Lack of an external build environment with first-party support makes it impossible to verify if the link kit provided with OpenBSD is not a trojan horse, however the default build of the kernel includes build and compilation meta-data inside of itself so a "bit-by-bit" comparison or just a checksum verification is impossible without modifying the canonical build process. GCC support was also (conspicuously) dropped and eliminated from the source tree. Having both GCC and clang support for the kernel build process (that is self-hosted) would be an excellent first step toward support for a portable build environment hosted externally to the system.


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

Kolmogorov Complexity is undecidable so using probability and information theory and statistics to find worms is a dead-end:

http://alexander.shen.free.fr/library/Zvonkin_Levin_70.pdf

Although this is interesting:

"None of the computing machine simulations of organic evolution have
attempted representations of organisms using minimal codes, and it seems like
a reasonably good thing to try." - Ray Solomonoff

What was the Soviet equivalent of Unix? They obviously had far superior tooling in the 1980s to develop Buran as a fully-automated space shuttle:
https://en.wikipedia.org/wiki/DRAKON

I know from REFAL that they had a better version of LISP and a better compiler for it (Supercompilers, LLC).

# Footnotes

[1] PAR2 and the Bittorrent protocol (have been around for two decades, cover a similar problem domain when file integrity (or durability in the case of erasure) of collections of objects is concerned). This isn't rocket science. Durability and integrity are both important aspects of system design.

[2] OpenBSD "syspatch" is at the same level of security and correctness analysis as "kernel_reorder". They represent critical transactions on the system. Transaction processing systems with ultra-high-reliability have been studied extensively (Tandem, DB2, Journaling ISAM databases where transactions are physically written out in the order that they occur). These are not historical artifacts, Tandem hosts are still running in the Canadian commercial banking infrastructure, for instance.

Transaction processing systems where ultra-high-reliability and data loss are not allowed are an excellent reference (the "shared-nothing" approach):

"Tandem's NonStop systems use a number of independent identical processors and redundant storage devices and controllers to provide automatic high-speed "failover" in the case of a hardware or software failure. To contain the scope of failures and of corrupted data, these multi-computer systems have no shared central components, not even main memory. Conventional multi-computer systems all use shared memories and work directly on shared data objects. Instead, NonStop processors cooperate by exchanging messages across a reliable fabric, and software takes periodic snapshots for possible rollback of program memory state."


[3] Filesystems using optical WORM robotic disc libraries existed at the time of Plan 9's development (e.g. "Ken's filesystem"). Optical drives have notably disappeared from consumer devices despite having the same WORM property, and of course now we also have blockchains, ZFS, and IPFS.

[4] A simple counting argument suffices to show that signature-based methods alone are not enough to detect the presence of malware due to the possibility of arbitrary encoding and polymorphism. Cf. "tripwire".

[5] We solved the byzantine generals problem (Bitcoin), but we can't get this right.

[5] Light-hearted fictional scenarios that are enjoyable and illustrative of some of the problems:

1. Putting a copy of the current unpatched version of OpenBSD inside the computer center from "Colossus: The Forbin Project" (1970) - maybe that was the reason for the massive speedup, it had access to its own unlinked ELF object code (j/k).
3. Burning it into firmware that controls a nuclear power plant cooling pump (akin to Michael Mann's Blackhat), or using it to control commercial or government (manned or unmanned) space launch systems, military command and control ("Wargames") or life support systems on manned space stations or space vehicles ("2001: A Space Odyssey", with a twist), or the guidance systems or arming systems for nuclear warheads, or in commercial aviation, or self-driving vehicles.
   
4. Bruce Sterling already wrote a sci-fi book where a laser weapon runs OpenBSD, "The Zenith Angle".

[6] Is the random reordering really random? There's almost no entropy when the install media is running on a system initially, and it doesn't proactively collect entropy from the user.

https://www.schneier.com/blog/archives/2007/11/the_strange_sto.html


# My initial bug report to the OpenBSD mailing list:

https://marc.info/?l=openbsd-bugs&m=159074964523007&w=2


# Request for comments

Please provide any commentary or feedback on this essay or the source repository or my bug reports, and suggestions or ideas for further development (pull requests can go to the "comments" file).

--

Thu Jun 15 16:59:52 UTC 2023

# Conclusion

The unstated truth (or perhaps dirty secret) about the portability of self-hosted Unix and why Unix is such a highly polished gem (initially, anyway) is that it is the first synthetic analogue of a biological organism (with a self-reproduction process), with C being the portable assembly language. As such it is prone to the accumulation of "junk DNA" as well as "viral DNA"  (which might not actually be junk but could trigger or be triggered by another process). In this analogy, OpenBSD's kernel-reodering mechanism (as currently implemented with no integrity checks of object files) is "cancer". Proceeding from the assumption of no contamination of the outside or inside environment is foolish.

All software problems can be fixed, however. 

# Addendum

The official response from Theo de Raadt is that the sha256 sums solve nothing, and that I am worried about "second or third-order problems", so I guess it doesn't matter.

https://marc.info/?l=openbsd-bugs&m=168688579123005&w=2

The official spec of SLSA 1.0 specifically states that a hardend build platform is the desired highest state of compliance (ironically):

https://slsa.dev/spec/v1.0/levels#build-l2-hosted-build-platform

"Track/Level Requirements 	            Focus
 Build L3 	 Hardened build platform 	Tampering during the build"

I had not read this document until today when GitHub recommended I install a dummy SLSA3 build automation script. Maybe I am on the right track as I reached the same conclusion after noticing the problem three years ago? A formal approach to security hardening is required for software systems which are self-hosting, generally.
