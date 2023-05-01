# Appendix 2 {#sec:app2ex1}

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam nisi purus,
bibendum non neque sed, lacinia tristique tortor. Vestibulum eu lectus sed velit
luctus varius. Sed sollicitudin ligula ante. Integer porta a erat commodo
dignissim. Duis et lectus diam. Nulla id erat vestibulum nisi placerat
efficitur. Nulla a semper libero. Praesent pharetra ullamcorper massa vel
tincidunt. Sed dignissim magna et tellus efficitur, vitae sollicitudin lorem
tincidunt. Nam non velit et enim rutrum euismod.

## Appendix tables

* @tbl:app2ex1
* @tbl:app2ex2

------   ------    ------
1             2     3
11           22     33
111         222     333
------   ------    ------

: Headless table {#tbl:app2ex1}


Col1         Col2     Col3     Col4     Col5     Col6     Col7     Col8     Col9     Col10     Col11     Col12     Col13     Col14     Col15     Col16     Col17   Col17
---------  ------   ------   ------   ------   ------   ------   ------   ------   -------   -------   -------   -------   -------   -------   -------   -------   -------
a               1        2        3      123     abcd     1234      444        a       bbb      cccc       ddd      eeee       fff      gggg      abcd      1234   9876
b              11       22       33      456     efgh      567       44       aa        bb      cccc        dd      eeee        ff      gggg      efgh       567   543
c[^a21]       111      222      333      789     ijkl       89        4      aaa         b      cccc         d      eeee         f      gggg      ijkl        89   21

: Extra wide table[^a22] {#tbl:app2ex2}

[^a21]: Footnote in table.
[^a22]: Footnote in table caption.


## Appendix figures

* @fig:app2ex1
* @fig:app2ex2, @fig:app2ex2b
* @fig:app2ex3

![Figure with implicit dark version. Suspendisse erat est, imperdiet sed dolor at, sagittis lobortis tortor. Nulla facilisi. Aliquam pharetra scelerisque auctor. Duis vel auctor ipsum.](figures/anscombe){#fig:app2ex1}

<div id="fig:app2ex2">

![Figure with implicit dark version](figures/lines.png){#fig:app2ex2a}

![Figure with suppressed dark version](figures/lines.png){#fig:app2ex2b darksrc=""}

Sub-figures with non-default extension.
</div>

![Extra wide figure](figures/densities){#fig:app3ex3 width=10in}

## Appendix math

$$
\begin{aligned}
    x &= 1\\
    x + y &= 10\\
\end{aligned}
$$ {#eq:app2ex1}

$$
\frac{\int_0^\infty \exp^{-x^2}\,\mathrm{d}x}{1 + \frac{1}{\int_0^1 \sin^2(x)\,\mathrm{d}x}}
$$ {#eq:app2ex2}

* @eq:app2ex1
* @eq:app2ex2
* Block without tag:

$$
x + y + z = 100
$$

* Large aligned without tag:

\begin{aligned}
        a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
    &A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,\\
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
    &A, B, C, D, E, F
\end{aligned}
