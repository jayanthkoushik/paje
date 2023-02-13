# paje
_paje_ is a website creation and deployment system. It is composed of two major
parts: 1) A [Jekyll](https://jekyllrb.com) scaffolding with a clean minimalist
theme, and support for math and bibliographies. 2) A [GitHub
Actions](https://github.com/features/actions) workflow to deploy the site using
[GitHub Pages](https://pages.github.com).

## Quickstart

1. Create a new GitHub repository for your site. If creating a personal page,
   which will be deployed to `<username>.github.io`, the repository should be
   created with that name.

2. Create a new branch named `source`, and switch to it (`git checkout -b
   source`). This is where the source for your site will live. The `master` branch
   will be used to deploy the site.

   > :warning: **The `master` branch will be overwritten when using the
   configuration provided in the quickstart**.

3. Create a file named `index.md` at the root of your repository. This file will
   contain the root of your site. For now, just add a title:

   ```yaml
   ---
   title: Hello, World
   ---
   ```

4. Create a folder named `.github/workflows`, and within it, create a `.yml`
   file, e.g., `deploy.yml`, with the following contents:

   ```yaml
   on:
     workflow_dispatch:
     push:
       branches:
       - source

   jobs:
     main:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v2
       - uses: jayanthkoushik/paje@v2
         with:
           setupscript: sh build.sh
           targetbranch: master
         env:
           GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

5. Create a file named `build.sh`. This will be run by _paje_ prior to building
   your site. For now, add a line copying `index.md` to the `/www` folder (_paje_
   builds the website from this folder):

   ```sh
   cp index.md /www
   ```

6. Commit all three files, and push to GitHub.

7. In the _Actions_ tab on your repository's GitHub page, you should see a new
   workflow run. This is _paje_ building and deploying the site, and should take
   just a few minutes to run.

8. Once the workflow is complete (indicated by a check mark), the master branch
   should have two file, `index.html`, and `404.html`. The site has been built, and
   is ready to be deployed!

9. On the repository's GitHub page, go to the _Pages_ section under _Settings_.
   Here, set the source branch to `master`, and save.

10. Your website should now be online!

## Demo

The `test/` folder contains a demo showing various features of _paje_. The website
generated for this folder can be viewed at <https://jkoushik.me/paje>.

## Adding content

_paje_ uses [pandoc](https://pandoc.org) to convert markdown files to html.
Refer to the [docs](https://pandoc.org/MANUAL.html#pandocs-markdown) for
pandoc's markdown syntax. The present guide will indicate elements which need to
be written in a particular manner. Additionally, you can use the templating
features of Jekyll to make your pages modular. Refer to the [Jekyll
docs](https://jekyllrb.com/docs/) for details.

>:warning: Note that any files added to the site should be copied to `/www` in
_setup.sh_.

### References

_paje_ using [pandoc-crossref](https://lierdakil.github.io/pandoc-crossref/) to
process references to figures, tables, equations. Refer to the docs for details
on syntax.

### Additional files

You can create additional markdown files to add pages to your site. For each new
file, add a line to _setup.sh_ copying that file to `/www`, e.g. `cp newfile.md
/www`. This will create a `/newfile` page on your site. Files _must_ start with
`---` for them to be recognized as pages.

### Metadata

Metadata should be specified within `---` and `---` at the top of the file,
using yaml syntax. The default _paje_ template handles the tags shown in the
following example:

```yaml
---
title: page title, displayed at the top of the page

subtitle: page sub-title, displayed below the title

description: page description meta data (not displayed)

author:  # author list, will be displayed below sub-title
- name: Author1 Name
  affiliation:
  - 1  # link to an id in the institute list
  equalcontrib: true  # whether the author is an equal main contributor

- name: Author2 Name
  affiliation:
  - 2  # will be shown as a super-script after the name
  equalcontrib: true  # will be indicated with a '*'

- name: Author3 Name
  affiliation:
  - 1
  - 2  # multiple affiliations will be separated by ','

institute:  # institute list, displayed below authors
- id: 1  # will be shown as a super-script before the name
  name: Institute 1

- id: 2
  name: Institute 2

skipequal: true  # skip adding a note about equal authorship

nomath: true # will disable math support

includes:  # files whose content will be added before the main body
- inc1.md  # should be inside '_includes/'
- inc2.html

appendices:  # files whose content will be added after the main body
- app1.md  # should be inside '_includes/'
- app2.md

extcss:
- local1.scss # custom scss files for the page
- local2.scss

extjs:
- local1.js # custom javascript files for the page
- local2.js
---
```

### Math

_paje_ supports typesetting math using [KaTeX](https://katex.org). Inline and
block expressions can be added as shown below:

```latex
This is an inline expression: $f(x) = x^2 + 2x + 1$.
This is a block expression:

$$
f(x) = \int_{0^\infty} \exp(-x^2) \mathrm{d}x.
$$

Note the empty lines surrounding the block expression. These are necessary! You
can also make equations:

$$
\begin{aligned}
f(x) &= sin(x).\\
f'(x) &= cos(x).
\end{aligned}
$$ {#eq:ex}

Equations can be referenced (@eq:ex) using tags.
```

Definitions are supported, and can be added in any page directly, or in a
separate file that's included (via `includes` in the metadata):

```latex
\newcommand{\PP}[2]{\mathbb{P}_{#1}\left[{#2}\right]}
\newcommand{\XX}{\mathcal{X}}
\newcommand{\RR}{\mathbb{R}}

$$
\PP{\RR}{x \in \XX}
$$
```

### Bibliography

You can include a `bib` file of references, and add citations in your page. The
page _must be named `references.bib`_, and you need to add the following line to
_setup.sh_: `cp references.bib /www/_includes`. Refer to the pandoc guide for
syntax used to make citations.

### Figures

Images can be added as figures with captions and links:

```markdown
This is a figure:

![This is the figure caption.](img_path){#fig:figid}

Note the surrounding empty lines! You can refer to the figure (@fig:figid) like
any other reference.
```

The default extension for images is `.svg`, so it can be omitted when
specifying the path.

The default _paje_ theme has a dark mode. When this is enabled (either based on
user device preference, or the toggle button), figures will have their colors
inverted. Alternatively, figures can have a separate image to be used in the
dark theme. For a figure with source '/path/to/fig.ext', if there is a file
'/path/to/fig_dark.ext', it will be used automatically. A dark mode image can
also be specified explicity by setting 'darksrc' for the figure:

```markdown
![This figure will use `alt_img.png` in dark mode](img.png){#fig:figid darksrc='alt_img.png'}
```

Setting `darksrc` to `''` will suppress the default behavior of inverting colors
in the dark mode. This can be used for figures that should appear the same
regardless of mode.

Sub-figures can be created by wrapping figures in a `div`:

```markdown
<div id="fig:subs">

![Sub-figure 1. You can specify the width](img1){#fig:sub1 width=2in}

![Sub-figure 2. You can specify both the width and height](img2){#fig:sub2 width=3in height=2in}

This is the caption for the whole figure.
</div>

You can refer to either the whole figure (@fig:subs), or to individual
sub-figures (@fig:sub1,@fig:sub2).
```

### Tables
Note that support for tables is finicky. They can be added as such:

```markdown
This is a table:

Header    col1   col2    col3
--------- ------ ------- ------
Row       1      2       3

: Table caption. {#tbl:tblid}

Note the empty lines surrounding the table (@tbl:tblid).
```

### Acronyms

Acronyms can be defined using `\acrodef`:

```latex
\acrodef{CMU}{Carnegie Mellon University}
\acrodef{USA}{United States of America}
```

These can be used using `\ac` and `\acs`:

```latex
This will be shown with the definition in brackets since it is the first time
the abbreviation is used: \ac{CMU}.
This will now be shown only as the abbreviation: \ac{CMU}.
This will be only shown as the abbreviation even though it has not been used
before: \acs{USA}.
```
