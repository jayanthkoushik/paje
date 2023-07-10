# Typography

* **Bold**
* _Italic_
* **_Bold italic_**.


# Numbers

* Normal: 0123456789
* Math: $0123456789$


# Acronyms

\newenvironment*{acros}{}{}
\begin{acros}
\acrodef{CMU}{Carnegie Mellon University}
\acrodef{USA}{United States of America}
\acrodef{SSN}{social security number}
\acrodef{NVIDIA}{}
\acrodef{H20}[$\mathrm{H}_2\mathrm{O}$]{water}
\acrodef{AC}[A/C]{}
\end{acros}

* Default (short+long): \ac{CMU}
* Repeated (short): \ac{CMU}
* Forced long: \acl{CMU}
* Forced short: \acs{USA}
* Repeated after forced short (short+long): \ac{USA}
* Plural: \acp{SSN}
* No long form: \ac{NVIDIA}
* Special short form: \ac{H20}
* Special short form without long form: \ac{AC}


# Math

\newcommand{\PP}[2]{\mathbb{P}_{#1}\left[{#2}\right]}
\newcommand{\XX}{\mathcal{X}}
\newcommand{\EE}[2]{\mathbb{E}_{#1}\left[{#2}\right]}

$$
\int_0^\infty \exp^{-x^2}\,\mathrm{d}x
$$ {#eq:ex1}

$$
a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F
$$ {#eq:ex2}

* Inline: $\int_0^\infty \exp^{-x^2}\,\mathrm{d}x$
* Block: @eq:ex1, @eq:ex2
* Commands defined in body (P[x in X]): $\PP{}{x \in \XX}$
* Aligned:

\begin{aligned}
    x &= 1\\
    x + y &= 10\\
    x + y + z &= 100
\end{aligned}

Proin eleifend lorem semper, commodo tellus nec, porta purus. Nullam commodo
lectus nibh, consequat maximus lorem faucibus in. Nam purus eros, rutrum in
sapien et, condimentum lacinia nibh. Block math in same paragraph as text:
$$
\int_0^\infty \exp^{-x^2}\,\mathrm{d}x
$$

# Links

* Section: @sec:ex1, @sec:ex1.2
* Appendix section: @sec:app2ex1, @sec:app1ex1.1.1
* Appendix figure: @fig:app2ex2b
* Appendix table: @tbl:app2ex1
* Appendix math: @eq:app2ex2
* Pointer to footnote[^m11][^m12]

[^m11]: Example footnote text.
[^m12]: Integer at enim eu tellus malesuada scelerisque. Ut sed rhoncus ipsum, at tempor
      nisl. Vivamus vitae pulvinar leo, at pharetra massa. Ut lobortis odio non nulla
      tincidunt pulvinar.

# Citations

* Short citation[@latex:companion]
* Short citation with pre note[see @latex:companion]
* Short citation with locator[@latex:companion, p. 1]
* Short citation with post note[@latex:companion, for more]
* Short citation with locators and pre/post notes[see @latex:companion, chap. 1-4, for more]
* Long citation: @lesk:1977, @latex:companion
* Long citation with locator: @lesk:1977 [chap. 1]
* Long citation with note: @lesk:1977 [for more]
* Multi citation[@lesk:1977; @knuth:1984; @latex:companion]
* Multi citation with pre note[see @lesk:1977; @knuth:1984; @latex:companion]
* Multi citation with locators[@lesk:1977, sec. 1; @knuth:1984; @latex:companion, p. 1-3]
* Multi citation with post note[@lesk:1977; @knuth:1984; @latex:companion, for more]
* Multi citation with locators and pre/post notes[see @lesk:1977, p. 1; @knuth:1984; @latex:companion, chap. 1-2, for more]
