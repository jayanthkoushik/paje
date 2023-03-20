# Includes {#sec:includes}

**There should be text in this paragraph before and after this**.

* Commands from metadata include (argmin R): $\argmin$ $\R$
* Include command in body (there should be text after this):

{% include utils/ext.md %}


# Tables

* @tbl:ex1
* @tbl:ex2

Col1       Col2     Col3     Col4
------   ------    ------    ------
1             2      3       4
11           22      33      44
111         222     333      444

: Short table {#tbl:ex1}

 Col1      Col2      Col3      Col4     Col5      Col6      Col7      Col8
-----     -----     -----     -----    -----     -----     -----     -----
    a         1         2         3      123      abcd      1234       444
    b        11        22        33      456      efgh       567        44
<!--  -->
    c       111       222       333      789      ijkl        89         4

: Wide table {#tbl:ex2}


# Figures

* @fig:ex1
* @fig:ex2
* @fig:ex3, @fig:ex3a, @fig:ex3b

![Figure with explicit dark version](figures/anscombe){#fig:ex1 darksrc="figures/anscombe_dark.svg"}

![Figure with no dark version](figures/diamonds){#fig:ex2 darksrc=""}

<div id="fig:ex3">

![Figure with 'width=3in'](figures/gaussian2d){#fig:ex3a width=3in}

![Figure with 'width=5in'](figures/densities){#fig:ex3b width=5in}

Sub-figures with auto dark versions
</div>
