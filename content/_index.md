+++
template = 'home.html'

[extra]
lang = 'en'
+++

I write code, among other things.

## Entrepreneurship

I've always had a strong customer-focused mindset. I've never thought that I'd
be there to just write the code I'm asked to. In 2006 that meant starting up my
own company with colleagues, which then led to starting other companies over the years which all culminated to having them bought in 2020. I am currently a salaried employee.

Owning a company gives a lot of perspective into what is actually important,
especially when considering the long term strategy. Business usually should not
be steered opportunistically, but instead there should be an end result that one
wants to achieve and then a path of intermediate steps towards that goal. Most
goals are achievable with concentrated effort, but unfortunately many VC and
stock traded companies lack the conviction to follow a long term plan.

## Payments

It's been now 20 years since I got involved in payment systems, specifically
card payments. It is an interesting combination of truly customer facing
experience, deep technical challenges, high security requirements, an extensive
compliance maze and cost optimization. And also extreme legacy and moats, so
many moats. It's curious how the most modern cloud-native systems talk to
[COBOL](https://en.wikipedia.org/wiki/COBOL) in
[NonStop](https://en.wikipedia.org/wiki/NonStop_(server_computers)) mainframes. 

My payment experience is the deepest on physical payment terminals in Visa and
Mastercard processing, but I've had to deal plenty with eCommerce, VAS, APMs, tokenization, omni-channel, etc. over the years – and so many other topics. 

## Cloud

I've lived through the full transition towards public clouds, starting from personal VPS to fully cloud-native development. Using a public cloud is an excellent means of reducing the amount of things you need to care about. It allows software development hours to be spent on the actual service to be produced. However, it's not a panacea, and it takes a lot of effort to avoid the pitfalls and to be truly effective. I have many strong opinions about the use of public clouds.

[AWS](https://aws.amazon.com/) is my cloud provider of choice. I've had limited
experience with both Azure and GCP, but my focus has been on AWS ever since they
launched VPC in 2009 and I've managed production workloads there for over ten
years. [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) is the most
important aspect of operating the cloud, where
[CloudFormation](https://aws.amazon.com/cloudformation/) and
[CDK](https://aws.amazon.com/cdk/) have been my primary tools. The used services
are way too numerous to list here, as I strongly believe each cloud should be
utilized to the fullest, rather than limiting to the lowest common denominator
among all the public clouds.

## Security

Security has always been close to heart for me. Security aspects should always
be considered in all stages of programming – design, implementation, testing,
deployment. I have many strong opinions on security as well. Defense in depth is
a good thing, but only if each layer is sufficient security by itself. It
doesn't matter how many fences there are surrounding the property if all of the
fences have a gap. Security is only as strong as the weakest link.

Professionally I've had plenty of experience with PCI DSS, PCI SSF, PCI PIN,
OWASP, CIS Benchmarks, FIPS-140-2, etc. Those, while a good starting point, are
not the be-all and end-all of security, and in some cases they are even at odds
with good security.

## Cryptography

I've been interested in the development and implementation of cryptographic
protocols for most of my programming career, and have written several
implementations of them. Simplicity is especially important to me – I'd much
rather have a 10% slower implementation than triple the lines of code involved.
I'm especially impressed by projects such as
[TweetNaCl](https://tweetnacl.cr.yp.to/) and
[s2n](https://github.com/aws/s2n-tls).

On the algorithm design front I have much less experience, but
[SHA-3](https://en.wikipedia.org/wiki/SHA-3) is my favourite or rather then
underlying [Keccak](https://keccak.team/keccak.html) permutation and the
[Sponge](https://en.wikipedia.org/wiki/Sponge_function) construct. It is
amazingly versatile in the ways it can be used, and simple and performant to
implement.

## Rust

I have found [Rust](https://www.rust-lang.org/) to be quite an enjoyable
language. It's capable of being very low level, yet complex things are also
relatively convenient. And if you need to do anything which shouldn't have a
garbage collector there is really no better option. There are however also
things that are awful, and it's just a tad bit too complex to be the default
programming language to go to.

## Cryptocurrencies

Let me lead by saying that I'm not into NFTs or cryptocurrency trading, but I am
very interested in the cryptocurrency technology and the potentical social
ramifications of that. Cryptocurrencies have the potential of bringing about a
revolution of sorts, but it is not certain that such a revolution will happen. In any case, cryptocurrencies are here to stay forever, and they will be utilized – centralized if not decentralized.

[Bitcoin](https://en.wikipedia.org/wiki/Bitcoin) is still the leading
cryptocurrency which I believe has the most potential to be world changing. I do
not consider the reliance of [PoW](https://en.wikipedia.org/wiki/Proof_of_work)
to be a showstopper. [Ethereum](https://en.wikipedia.org/wiki/Ethereum) has
recently managed to switch to
[PoS](https://en.wikipedia.org/wiki/Proof_of_stake) and it is interesting to see
how it will fare in the long term. But for many usages [Ripple](https://en.wikipedia.org/wiki/Ripple_(payment_protocol)), a shared ledger, is the most appropriate one. Of the others, there are just too many to mention – each has their potential, but also their downsides.

## Advent of Code

I enjoy programming, so I like to do it in my free time as well. And [Advent of
Code](https://adventofcode.com/) is a wonderful way to enjoy December. I
heartily recommend it to everyone who wants to learn a new language, or improve
their programming skills, or just showcase their ability in a very concise
manner. If I am recruiting anyone, having public AoC solution repositories are
an automatic hall pass through the technical part – I already know you can write
code and I know you can think algorithmically.
