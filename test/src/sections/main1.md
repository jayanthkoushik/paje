# Typography

* **Bold**
* _Italic_
* **_Bold italic_**.


# Numbers

* Normal: 0123456789
* Math: $0123456789$


# Acronyms

\acrodef{CMU}{Carnegie Mellon University}
\acrodef{USA}{United States of America}
\acrodef{SSN}{social security number}

* Default (short+long): \ac{CMU}
* Repeated (short): \ac{CMU}
* Forced short: \acs{USA}
* Repeated after forced short (short+long): \ac{USA}
* Plural: \acp{SSN}


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


# Links

* Section: @sec:ex1, @sec:ex1.2
* Appendix section: @sec:app2ex1, @sec:app1ex1.1.1
* Appendix figure: @fig:app2ex1, @fig:app2ex2a
* Appendix table: @tbl:app2ex1
* Appendix math: @eq:app2ex1
* Short citation[@latex:companion]
* Long citation: @latex:companion, @lesk:1977
* Multi citation[@lesk:1977; @knuth:1984; @latex:companion]
* Pointer to footnote[^m11]

[^m11]: Example footnote text.
