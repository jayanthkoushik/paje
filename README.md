# paje
_paje_ is a website creation and deployment system. It is composed of two major parts: 1) A [Jekyll](https://jekyllrb.com) scaffolding with a clean minimalist theme, and support for math and bibliographies. 2) A [GitHub Actions](https://github.com/features/actions) workflow to deploy the site using [GitHub Page](https://pages.github.com).

## Quickstart

1. Create a new GitHub repository for your site. If creating a personal page, which will be deployed to `<username>.github.io`, the repository should be created with that name.

2. Create a new branch named `source`, and switch to it (`git checkout -b source`). This is where the source for your site will live. The `master` branch will be used to deploy the site.

> :warning: **The `master` branch will be overwritten when using the configuration provided in the quickstart**.

3. Create a file named `index.md` at the root of your repository. This file will contain the root of your site. For now, just add a title:

```markdown
---
title: Hello, World
---
```

4. Create a folder named `.github/workflows`, and within it, create a `.yml` file, e.g., `deploy.yml`, with the following contents:

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
    - uses: jayanthkoushik/paje@v1
      with:
        setupscript: sh build.sh
        targetbranch: master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

5. Create a file named `build.sh`. This will be run by _paje_ prior to building your site. For now, add a line copying `index.md` to the `/www` folder (`paje` builds the website from this folder):

```txt
cp index.md /www
```

6. Commit all three files, and push to GitHub.

7. In the _Actions_ tab on your repository's GitHub page, you should see a new workflow run. This is _paje_ building and deploying the site, and should take just a few minutes to run.

8. Once the workflow is complete (indicated by a check mark), the master branch should have two file, `index.html`, and `404.html`. The site has been built, and is ready to be deployed!

9. On the repository's GitHub page, go to the _Pages_ section under _Settings_. Here, set the source branch to `master`, and save.

10. Your website should now be online!

## Adding content
_paje_ uses [pandoc](https://pandoc.org) to convert markdown files to html. Refer to the [docs](https://pandoc.org/MANUAL.html#pandocs-markdown) for pandoc's markdown syntax. The present guide will indicate elements which need to be written in a particular manner. Additionally, you can use the templating features of Jekyll to make your pages modular. Refer to the [Jekyll docs](https://jekyllrb.com/docs/) for details. Note that any files added to the site should be copied to `/www` in _setup.sh_.

### Additional files
You can create additional markdown files to add pages to your site. For each new file, add a line to _setup.sh_ copying that file to `/www`, e.g. `cp newfile.md /www`. This will create a `/newfile` page on your site. Files _must_ start with `---` for them to be recognized as pages.

### Metadata
Metadata should be specified within `---` at the top of the file, using yaml syntax. The default `paje` template handles the tags shown in the following example:

```yaml
---
title: page title, displayed at the top of the page
subtitle: page sub-title, displayed below the title
description: page description meta data (not displayed)
nomath: true # will disable math support
extcss:
- local1.scss # custom css files for the page
- local2.scss
extjs:
- local1.js # custom javascript files for the page
- local2.js
---
```

### Math
_paje_ supports typesetting math using [KaTeX](https://katex.org). Inline and block expressions can be added as shown below:

```txt
This is an inline expression: $f(x) = x^2 + 2x + 1$.
This is a block expression:

$$
f(x) = \int_{0^\infty} \exp(-x^2) \mathrm{d}x.
$$

Note the empty lines surrounding the block expression.
These are necessary! You can also make equations:

$$
\begin{aligned}
f(x) &= sin(x).\\
f'(x) &= cos(x).
\end{aligned}
$$ {#eq:ex}

And refer to them (@eq:ex) using tags.
```

### Bibliography
You can include a `bib` file of references, and add citations in your page. The page _must be named `references.bib`_, and you need to add the following line to _setup.sh_: `cp references.bib /www/_includes`. Refer to the pandoc guide for syntax used to make citations.

### Figures
`.png` images can be added as figures with captions and links:

```txt
This is a figure:

![This is the figure caption.](img_name_without_extension){#fig:figid}

Note the surrounding empty lines! You can refer to
the figure (@fig:figid) like any other reference.
```

### Tables
Note that support for tables is finicky. They can be added as such:

```txt
This is a table:

Header    col1   col2    col3
--------- ------ ------- ------
Row       1      2       3

: Table caption. {#tbl:tblid}

Note the empty lines surrounding the table (@tbl:tblid).
```
