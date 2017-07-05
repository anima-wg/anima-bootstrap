This directory contains shepherd review suggestions and proposed text
changes that were written against a pre-version of draft-ietf-anima-bootstrapping-keyinfra-06.

These where subsequently discussed in the weekly meetings and to a large part included
into a separate branch of the github:

https://github.com/anima-wg/anima-bootstrap/tree/toerless_review_20170530
https://github.com/anima-wg/anima-bootstrap/tree/toerless_review_section3_20160606

Unfortunately, this branch did not get merged into the keyinfa-07 version of the draft
which was primarily focussed on aligning bootstrap with the voucher draft in last call.

Etherpad notes see: etherpad.txt

------------------------------------------------------------------------------------
TODO:
3.1.1 Discovery: Check if "ACP+Proxy" is the correct GRASP defintion.

--------------------------------
Q1: Is there any statement that the MASA can be optional, eg: is it clear what would
    need to be implemented on pledge and registrar for pledges that do not require a MASA ?

Q2: Is there any statement how a device without an IDevID could be used, pledge/registrar ?

Q3: Is there a list of assignments needed ?
    Page 13: id-mod-MASAURLExtn2016 - who assigns this ?

--------------------------------
Note 1: text is in textual order, sometimes i went back and found additional issues,
so the point numbering (Nxxx) is not in numerical order.

Note 2: I gave up on typos quickly, thats a separate round.

====================================================================================================

--------------------------------

N1: The intro with "BRSKI provides a foundation to securely answer" is great if we would
want the document to target only a room full of security expert. For the rest of us (ANIMA = OPS)
i think it would be great to prepend a few sentences that answer questions like "what planet are we
on, what context do i need to load int my brain to understand the following". 

I have suggested text to do that preprended before the existing text. 

--------------------------------

N2: "storing an X.509 root certificate". 

Does this need to be a "root" certificate ?
Consider the most likely simple enterprise or SP deployment of BRSKI.
Organization has some root-CA. for the purpose of a particular ANI, a sub-CA is created, which
becomes the assigning CA that the registrar uses. The root-CA itself is likely never online
except when both Data Centers with the asigning CAs burn down.

In these environments, it is not suffficient to only store on the pledge the root-CA, because
that root-CA will also assign other subCA that create certificates, and those certificates
would not be valid for our ANI.

So, the pledge could either just store the assigning-CA, which becomes a virtual root CA,
and if it burns down the ANI is frozen (no new pledges possible, re-enroll whole ANI with
new CA), or the pledges need to store the CA-chain with root-CA and assigning CA. WHich is the
best solution because it allows revocation/renewal of assigning CA in desaster cases.

I did not modify any text, but i am worried about this problem for actual deployments so i would
like to make sure we have documented an actual working solution.

--------------------------------

N3: The intro says "and local access control lists. The Pledge actions"...
What "and local access control lists" does this talk about ? If nobody knows, maybe delete ?

--------------------------------

N4: I think the "Other Bootstrapping Approaches" is also a level of brackground information that
hurts the "ease of digestion" flow for the reader, so i have moved it into an appendix and left
a breadcrump in the intro section. Otherwise unchanged.

--------------------------------

N5: "In many target applications, the systems involved are ".... this section
in secion 1.3 is i think quite crucial and one of the biggest benefits of BRSKI
and a great reasoning why we have new complex elements like proxy and MASA, but i
think it is more suggestive than descriptive and raises more questions than
it answers. And even tthat is already divesting the readers attention by being
in the beginning of the document. This topic IMHO deserves a more thorough explanation.
I have suggested an appendix section "Flexible SKU management" that tries to do this.

I think it is appropriate for an appendix, because it seems that to enable this functionality,
we would need some more functionality eg: across ACP, in MASA and so on.

--------------------------------

N6: The "Scope of the solution" section is really a discussion about the applicability to
constrained environments. This IMHO also is not necessary to be at the top, so i also moved
it into an appendix and left a breadcrump in the introduction. Also changed the name
to "Applicability to constrained environments" as this is more descriptive of the actual content.

N6.1: "The bootstrapping process can take minutes to complete". I bulletized and extended
the reasons for this. If i missed any core reasons contributing to the problem, please add.

N6.2: "This protocol is not intended for low latency handoffs". I find the idea of
thinking to use this protocol for that purpose as grotesque as requesting a new passport
every time i want to go through airport security (instead of using one i got in before).
Aka: to me the statement is more confusing than helpfull. I would recommend to remove the sentence
or provide a more founded explanation why anybody would think about this option.

N6.3: "specifically there are protocol aspects described here which might result
in congestion collapse"...  The following text makes it sound as if the verbosity of the
per-pledge enrolment is main the reason. I think this is misleading. From my understanding,
the likely even more important reason is the fact that parallel enrollment of multiple pledges
can not well be serialized. At least thats exactly the issue the 6TSCH adaptation of BRSKI is trying
to fix by reverting the initiator/responder roles. I have tried to improve the text accordingly. Please check.

N6.4: "It could also be used by non-constrained devices across a non-energy constrained, but challenged network"
An short explanation what constitute being challenged in respect to 802.15.4 would help. Otherwise it is unclear why that example is being mentioned.

--------------------------------

N7: The paragraph mentioning 802.1X is very suggestive and IMHO opens more questions
than answering them. It also breaks the core flow of the text. I suggest to move this
discussion into an appendix and make it more descriptive. I have proposed text for this
via a separate appendix (Network Access Control interop).

--------------------------------

N8: "Architectural Overview"

N8.1: "Each component is logical and may be combined with other components as necessary."
I have no idea what this means. It sounds like i can build a solution without Registrar
and without Pledge. Aka: either clarify or remove sentence.

N8.2: Figure 1: Suggested improvements to picture leveraged in below improved explanation.
Added protocol to lines to clarify which protocols run where.

N8.3: Suggested improved text for textual explanation of Figure 1. 
- It needed to better explain each block shown and how they relate. Eg; Added text for MASA.
- Original text said that PKI RA can optionally be integrated with Domain Registrar.
  In reality i think that it is the other way around: It MUST be integrated with Domain
  Registrar unless additional extensions are implemented, eg: in Circuit Proxy. Explained that
  in the text.
- Mentioned that PKI CA can be outsourced and does not require any BRSKI extensions.
  important IMHO to show the simplicity of deployment.

--------------------------------

N9: 2.3 Protocol flow 

N9.1: Expanded picture
  - showing GRASP for Registrar discovery by Circuit Proxy, ACP, L2 to circuit proxy

N9.2 - redid discovery part.

--------------------------------

N10: Protocol details

N10.1: Moved "run BRSKI when unconfigured" into subsection "High Level" and amended that
with an explanation of the high level workflow.


N10.2: Added explanation why BRSKI is EST7030 extension (instead of separate connection)
also ecause of circuit proxy.

N10.2: "If the Registrar responds with a redirection to other web origins the Pledge MUST follow
            only a single redirection"
Can we detail a single workflow where this is beneficial in the standard workflow, eg:
wrt to the Circuit Proxy ? I fail to see how this would work in general except if the
Pledge has aquired a global IPv4/IPv6 address.

N10.3: "discovered Registar" -> "discovered Circuit Proxies"


--------------------------------

N11: "IPv4/mDNS operations"

It is unclear from existing text when and why pledges and/or proxies would want to use
IPv4 instead of IPv6 and/or mDNS instead of GRASP. Without further changes, these sections
would easily result in a lot of incompatible implementation choices.

I have proposed an expanded, refined text under the title of "Supporting pledges without ANI".
That IMHO is really the context for which all these options are relevant:
 - which devices could this apply to (many)
 - benefits of BRSKI for these devices with simple example
 - explain how to do BRSKI discovery using whatever protocols pledge already uses without BRSKI
   (IPv4 vs. IPv6, mDNS vs GRASP)
 - 

I suggest to move this whole text into a new standalone document. Even if it becomes a rather
sort document, it would IMHO help a lot to promote the idea of applying BRSKI outside of full ANI
implementations. 

If we fork off a document for this right now, we can leave a breadcrump (reference) to it
in BRSKI itself and therefore make sure that readers of BRSKI will still know about that
large scope of applicability of BRSKI.

Note: This move would of course eradicate all mentioning of IPv4 and mDNS from the main BRSKI
document.

NX.1: I have added a sentence "Circuit Proxy SHOULD send unsolicited multicast responses for
      the bootstrap service every 30 seconds" to the section about how to operate mDNS.

My understanding of RFC6762 is that there is NO periodic unsolicited multicast of
responses, so what this sentence says is a change to RFC6762. If that change is acceptable
to IESG review, then pledges can passively listen to mDNS. If this sentence is not acceptable,
then the whole paragraph will become questionable and pledges using mDNS may be forced to
send queries to reliably get responses.

--------------------------------

TODO: Need to update author addresses.

-----------------------------------------------------------------------------------
TODO:
  Would also work with bearer Tokens - how to add that text into the introduction.

