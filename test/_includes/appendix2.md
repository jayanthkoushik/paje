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

Col1       Col2     Col3
------   ------    ------
1             2     3
11           22     33
111         222     333

: Appendix table {#tbl:app2ex1}

## Appendix figures

* @fig:app2ex1
* @fig:app2ex2, @fig:app2ex2b

![Figure with implicit dark version](figures/anscombe){#fig:app2ex1}

<div id="fig:app2ex2">

![Figure with implicit dark version](figures/lines.png){#fig:app2ex2a}

![Figure with suppressed dark version](figures/lines.png){#fig:app2ex2b darksrc=""}

Sub-figures with non-default extension
</div>

## Appendix math

$$
\begin{align*}
    x &= 1\\
    x + y &= 10\\
\end{align*}
$$ {#eq:app2ex1}

$$
\frac{\int_0^\infty \exp^{-x^2}\,\mathrm{d}x}{1 + \frac{1}{\int_0^1 \sin^2(x)\,\mathrm{d}x}}
$$ {#eq:app2ex2}

* @eq:app2ex1
* @eq:app2ex2
* Without tag:

$$
x + y + z = 100
$$
